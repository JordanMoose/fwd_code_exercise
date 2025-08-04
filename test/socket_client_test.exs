defmodule FwdCodeExercise.SocketClientTest do
  @moduledoc """
  Unit tests for the `FwdCodeExercise.SocketClient` module,
  which connects to a websocket server to receive wildfire updates.
  """

  use ExUnit.Case
  import ExUnit.CaptureLog
  import Mock
  import Mox

  alias FwdCodeExercise.SocketClient

  doctest SocketClient

  setup :verify_on_exit!

  setup do
    geojson =
      File.read!("test/fixture/test_geojson.json")
      |> Jason.decode!()
      |> Map.put("is_wildfire_update", true)
      |> Jason.encode!()

    state = %{}

    {:ok, geojson: geojson, state: state}
  end

  describe "start_link/1" do
    test "happy path: successfully starts the socket client and logs the connection" do
      mock_pid = :c.pid(0, 0, 1)

      with_mock(WebSockex, start_link: fn _, _, _ -> {:ok, mock_pid} end) do
        assert {{:ok, ^mock_pid}, log} =
                 with_log(fn -> SocketClient.start_link("ws://test-url") end)

        assert log =~ "Socket client connected to ws://test-url with PID #{inspect(mock_pid)}"
      end
    end

    test "error path: fails to start the socket client and logs the error" do
      with_mock(WebSockex, start_link: fn _, _, _ -> {:error, :connection_failed} end) do
        assert {{:error, :connection_failed}, log} =
                 with_log(fn -> SocketClient.start_link("ws://test-url") end)

        assert log =~ "Failed to connect socket client: :connection_failed"
      end
    end
  end

  describe "handle_frame/2" do
    test "happy path: processes wildfire updates and saves to file", %{
      geojson: geojson,
      state: state
    } do
      with_mock(File, write: fn _, _ -> :ok end) do
        assert {:reply, {:text, response}, ^state} =
                 SocketClient.handle_frame({:text, geojson}, state)

        assert response =~ "Wildfire updates saved to "
      end
    end

    test "happy path: creates output directory if it doesn't exist", %{
      geojson: geojson,
      state: state
    } do
      with_mock(File,
        write: [in_series([:_, :_], [{:error, :enoent}, :ok])],
        mkdir_p: fn _ -> :ok end
      ) do
        assert {{:reply, {:text, response}, ^state}, log} =
                 with_log(fn -> SocketClient.handle_frame({:text, geojson}, state) end)

        assert log =~ "Created directory for output file: "
        assert response =~ "Wildfire updates saved to "
        assert_called_exactly(File.write(:_, :_), 2)
        assert_called_exactly(File.mkdir_p(:_), 1)
      end
    end

    test "error path: replies with error if creating output directory fails", %{
      geojson: geojson,
      state: state
    } do
      with_mock(File,
        write: fn _, _ -> {:error, :enoent} end,
        mkdir_p: fn _ -> {:error, :failure_reason} end
      ) do
        assert {:reply, {:text, "Error saving wildfire updates"}, state} ==
                 SocketClient.handle_frame({:text, geojson}, state)
      end
    end

    test "error path: replies with error if encoding GeoJSON fails", %{
      geojson: geojson,
      state: state
    } do
      with_mock(Jason, [:passthrough], encode: fn _, _ -> {:error, Jason.EncodeError} end) do
        assert {:reply, {:text, "Error processing wildfire updates"}, state} ==
                 SocketClient.handle_frame({:text, geojson}, state)
      end
    end

    test "error path: replies with error if writing to file fails", %{
      geojson: geojson,
      state: state
    } do
      with_mock(File, write: fn _, _ -> {:error, :write_error} end) do
        assert {:reply, {:text, "Error saving wildfire updates"}, state} ==
                 SocketClient.handle_frame({:text, geojson}, state)
      end
    end

    test "happy path: handles other frames and logs the message", %{
      state: state
    } do
      assert {{:ok, ^state}, log} =
               with_log(fn -> SocketClient.handle_frame({:text, "Some other message"}, state) end)

      assert log =~ "Received message: Some other message"
    end
  end

  describe "handle_connect/2" do
    test "happy path: logs the connection status", %{state: state} do
      assert {{:ok, ^state}, log} =
               with_log(fn -> SocketClient.handle_connect({:ok, state}, state) end)

      assert log =~ "Connected to websocket server"
    end
  end

  describe "handle_disconnect/2" do
    test "happy path: logs the disconnection status and reason", %{state: state} do
      assert {{:ok, ^state}, log} =
               with_log(fn -> SocketClient.handle_disconnect(:normal, state) end)

      assert log =~ "Disconnected from websocket server: :normal"
    end
  end

  describe "terminate/2" do
    test "happy path: logs the termination reason", %{state: state} do
      assert {:ok, log} = with_log(fn -> SocketClient.terminate(:normal, state) end)
      assert log =~ "Websocket connection terminated: :normal"
    end
  end
end
