defmodule FwdCodeExercise.ArcGisPollerTest do
  @moduledoc """
  Unit tests for the `FwdCodeExercise.ArcGisPoller` module,
  which fetches wildfire data from the ArcGIS API and broadcasts it to subscribers.
  """

  use ExUnit.Case
  import ExUnit.CaptureLog
  import Mock
  import Mox

  alias FwdCodeExercise.{
    ArcGisPoller,
    PubSubMock,
    HttpClientMock
  }

  doctest ArcGisPoller

  setup :verify_on_exit!

  describe "start_link/1" do
    test "happy path: successfully starts the ArcGisPoller GenServer" do
      assert {:ok, _pid} = ArcGisPoller.start_link([])
    end

    test "error path: returns an error if the GenServer could not be started" do
      with_mock(GenServer, start_link: fn _, _, _ -> {:error, :failure_reason} end) do
        assert {:error, :failure_reason} = ArcGisPoller.start_link([])
      end
    end
  end

  describe "init/1" do
    test "happy path: initializes the GenServer and returns the initial state" do
      state = %{test: "initial_state"}
      assert {:ok, ^state} = ArcGisPoller.init(state)
    end
  end

  describe "handle_info/2" do
    test "happy path: handles :wildfire_poll message, fetches data successfully, and broadcasts to subscribers" do
      geojson =
        File.read!("test/fixture/test_geojson.json")
        |> Jason.decode!()

      expect(HttpClientMock, :get, fn _, _ -> {:ok, %Req.Response{body: geojson}} end)
      expect(PubSubMock, :broadcast, fn _, _, {:wildfire_updates, ^geojson} -> :ok end)
      state = %{}

      assert {{:noreply, ^state}, log} =
               with_log(fn ->
                 ArcGisPoller.handle_info(:wildfire_poll, state)
               end)

      assert log =~ "Fetched wildfires data successfully"
    end

    test "error path: handles failure during API call and logs the error" do
      expect(HttpClientMock, :get, fn _, _ ->
        {:ok, %Req.Response{body: %{"error" => "mock failure"}}}
      end)

      state = %{}

      assert {{:noreply, ^state}, log} =
               with_log(fn ->
                 ArcGisPoller.handle_info(:wildfire_poll, state)
               end)

      assert log =~ "API poll failed: \"Failed to fetch wildfires data: \\\"mock failure\\\"\""
    end

    test "error path: logs unexpected non-JSON response" do
      expect(HttpClientMock, :get, fn _, _ -> {:ok, %Req.Response{body: "non-JSON response"}} end)
      state = %{}

      assert {{:noreply, ^state}, log} =
               with_log(fn ->
                 ArcGisPoller.handle_info(:wildfire_poll, state)
               end)

      assert log =~
               "API poll failed: \"Unexpected response format for wildfires data: \\\"non-JSON response\\\"\""
    end

    test "error path: logs unexpected error response" do
      expect(HttpClientMock, :get, fn _, _ -> {:error, "mock error"} end)
      state = %{}

      assert {{:noreply, ^state}, log} =
               with_log(fn ->
                 ArcGisPoller.handle_info(:wildfire_poll, state)
               end)

      assert log =~ "API poll failed: \"Failed to fetch wildfires data: \\\"mock error\\\"\""
    end
  end
end
