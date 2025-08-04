defmodule FwdCodeExercise.SocketClient do
  @moduledoc """
  Connects to the WebSocket server to receive updates pushed to the "wildfires" topic.
  """

  use WebSockex
  require Logger

  @default_output_file "wildfire_data.json"

  def start_link(url) do
    WebSockex.start_link(url, __MODULE__, %{})
  end

  @impl WebSockex
  def handle_frame({:text, msg} = frame, state) do
    case Jason.decode(msg) do
      {:ok, %{"type" => "wildfire_updates"} = json} ->
        handle_wildfire_updates(json, state)

      _ ->
        handle_other_frame(frame, state)
    end
  end

  defp handle_wildfire_updates(json, state) do
    wildfire_updates =
      json
      |> Map.delete("type")
      |> Jason.encode!(pretty: true)

    Logger.info("Received wildfire updates")
    output_file = Application.get_env(:fwd_code_exercise, :output_file, @default_output_file)
    File.write!(output_file, wildfire_updates)
    {:reply, {:text, "Wildfire updates saved to #{output_file}"}, state}
  end

  def handle_other_frame({:text, msg}, state) do
    Logger.info("Received message: #{msg}")
    {:ok, state}
  end

  @impl WebSockex
  def handle_connect(_conn, state) do
    Logger.info("Connected to WebSocket server")
    {:ok, state}
  end

  @impl WebSockex
  def handle_disconnect(_reason, state) do
    Logger.warning("Disconnected from WebSocket server")
    {:ok, state}
  end

  @impl WebSockex
  def terminate(_reason, _state) do
    Logger.info("WebSocket connection terminated")
    :ok
  end
end
