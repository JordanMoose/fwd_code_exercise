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

  describe "start_link/1" do
    test "happy path: successfully starts the socket client and logs the connection" do
      mock_pid = :c.pid(0, 0, 1)
      with_mock(WebSockex, start_link: fn _, _, _ -> {:ok, mock_pid} end) do
        assert {{:ok, ^mock_pid}, log} = with_log(fn -> SocketClient.start_link("ws://test-url") end)
        assert log =~ "Socket client connected to ws://test-url with PID #{inspect(mock_pid)}"
      end
    end

    test "error path: fails to start the socket client and logs the error" do
      with_mock(WebSockex, start_link: fn _, _, _ -> {:error, :connection_failed} end) do
        assert {{:error, :connection_failed}, log} = with_log(fn -> SocketClient.start_link("ws://test-url") end)
        assert log =~ "Failed to connect socket client: :connection_failed"
      end
    end
  end

  describe "handle_frame/2" do
    test "happy path: processes wildfire updates and saves to file" do
      json = %{"is_wildfire_update" => true, "data" => "wildfire data"}
      frame = {:text, Jason.encode!(json)}

      with_mock(SocketClient, handle_wildfire_updates: fn _, _ -> {:reply, {:text, "Update processed"}, %{}} end) do
        assert {:reply, {:text, "Update processed"}, _state} = SocketClient.handle_frame(frame, %{})
      end
    end

    test "other frame: logs non-wildfire update messages" do
      frame = {:text, "Some other message"}

      with_mock(SocketClient, handle_other_frame: fn _, _ -> {:ok, %{}} end) do
        assert {:ok, _state} = SocketClient.handle_frame(frame, %{})
      end
    end

    test "error handling: returns error on invalid frame" do
      invalid_frame = {:invalid, "data"}

      assert_raise FunctionClauseError, fn ->
        SocketClient.handle_frame(invalid_frame, %{})
      end
    end
  end
end
