defmodule FwdCodeExercise.SocketHandlerTest do
  @moduledoc """
  Unit tests for the `FwdCodeExercise.SocketHandler` module,
  which handles websocket connections for the "wildfires" topic.
  """

  use ExUnit.Case
  import ExUnit.CaptureLog
  import Mock
  import Mox

  alias FwdCodeExercise.{
    SocketHandler,
    PubSubMock
  }

  doctest SocketHandler

  setup :verify_on_exit!

  describe "init/1" do
    test "happy path: successfully subscribes to the 'wildfires' topic" do
      expect(PubSubMock, :subscribe, fn _, _ -> :ok end)
      assert {{:ok, %{}}, log} = with_log(fn -> SocketHandler.init(%{}) end)
      assert log =~ "Subscribed to topic: wildfires"
    end

    test "error path: fails to subscribe to the 'wildfires' topic and logs and returns the error from PubSub" do
      expect(PubSubMock, :subscribe, fn _, _ -> {:error, :failure_reason} end)
      assert {{:error, :failure_reason}, log} = with_log(fn -> SocketHandler.init(%{}) end)
      assert log =~ "Failed to subscribe to topic: wildfires, reason: :failure_reason"
    end
  end

  describe "handle_info/2" do
    test "happy path: adds 'is_wildfire_update' => true to the GeoJSON data and pushes the stringified JSON data to the client" do
      geojson = %{
        "crs" => %{
          "properties" => %{
            "name" => "EPSG:4326"
          },
          "type" => "name"
        },
        "features" => [
          %{
            "geometry" => %{
              "coordinates" => [
                100.111,
                100.222
              ],
              "type" => "Point"
            },
            "properties" => %{
              "IncidentName" => "Test wildfire"
            },
            "type" => "Feature"
          }
        ],
        "type" => "FeatureCollection"
      }

      state = %{}

      assert {:push, {:text, json}, ^state} =
               SocketHandler.handle_info({:wildfire_updates, geojson}, state)

      assert json =~ ~r/"is_wildfire_update":\s*true/
      assert json =~ ~r/"IncidentName":\s*"Test wildfire"/
    end

    test "error path: logs an error and returns the unchanged state if encoding the GeoJSON data fails" do
      geojson = %{"invalid" => "data"}
      state = %{}

      with_mock(Jason, encode: fn _, _ -> {:error, :encoding_error} end) do
        assert {{:ok, ^state}, log} =
                 with_log(fn ->
                   SocketHandler.handle_info({:wildfire_updates, geojson}, state)
                 end)

        assert log =~ "Failed to encode wildfire updates: :encoding_error"
      end
    end

    test "happy path: ignores a :wildfire_updates message if the geojson is not a map" do
      state = %{}

      assert {{:ok, ^state}, ""} =
               with_log(fn ->
                 SocketHandler.handle_info({:wildfire_updates, "not_a_geojson"}, state)
               end)
    end

    test "happy path: ignores other messages and returns the unchanged state" do
      state = %{}

      assert {{:ok, ^state}, ""} =
               with_log(fn -> SocketHandler.handle_info("some_other_message", state) end)
    end
  end

  describe "handle_in/2" do
    test "happy path: logs the received message and returns the unchanged state" do
      state = %{}

      assert {{:ok, ^state}, log} =
               with_log(fn ->
                 SocketHandler.handle_in({"some_message", [opcode: :text]}, state)
               end)

      assert log =~ "Received message from client: \"some_message\""
    end
  end

  describe "terminate/2" do
    test "happy path: logs the termination reason and returns :ok" do
      reason = :normal
      state = %{}
      assert {:ok, log} = with_log(fn -> SocketHandler.terminate(reason, state) end)
      assert log =~ "WebSocket connection terminated with reason: :normal"
    end
  end
end
