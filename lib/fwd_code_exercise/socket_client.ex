defmodule FwdCodeExercise.SocketClient do
  @moduledoc """
  A client module for connecting to the WebSocket server and handling messages.
  """

  use WebSockex
  require Logger

  def start_link(url) do
    WebSockex.start_link(url, __MODULE__, %{})
  end

  @impl WebSockex
  def handle_frame({:text, msg}, state) do
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
  def handle_info({:wildfire_updates, geojson}, state) do
    json = Jason.encode!(geojson)
    Logger.info("New data received: #{json}")
    {:ok, state}
  end

  @impl WebSockex
  def terminate(_reason, _state) do
    Logger.info("WebSocket connection terminated")
    :ok
  end
end
