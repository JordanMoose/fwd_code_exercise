defmodule FwdCodeExercise.SocketHandler do
  @moduledoc """
  Handles WebSocket connections for the "wildfires" topic,
  receiving updates from the ArcGIS API and pushing them to connected clients.
  """

  @behaviour WebSock
  require Logger
  alias Phoenix.PubSub

  @topic_name "wildfires"
  @spec topic_name :: <<_::72>>
  def topic_name, do: @topic_name

  @doc """
  Subscribes to the "wildfires" topic when the WebSocket connection is established.

  ## Parameters
  - `_opts`: Options passed during WebSocket initialization (not used in this handler).

  ## Returns
  - `{:ok, %{}}`: Initial state of the WebSocket handler.
  """
  @impl WebSock
  @spec init(term()) :: {:ok, %{}}
  def init(_opts) do
    PubSub.subscribe(FwdCodeExercise.PubSub, @topic_name)
    {:ok, %{}}
  end

  @doc """
  Handles incoming messages on the "wildfires" topic
  and pushes the stringified GeoJSON data to the client.

  ## Parameters
  - `{:wildfire_updates, geojson}`: The GeoJSON data received from the ArcGisPoller.
  - `state`: The current state of the WebSocket handler.

  ## Returns
  - `{:push, {:text, json}, state}`: The updated state of the WebSocket handler with the stringified GeoJSON data.
  """
  @impl WebSock
  @spec handle_info({:wildfire_updates, map()}, WebSock.state()) :: {:push, {:text, binary()}, WebSock.state()}
  def handle_info({:wildfire_updates, json}, state) do
    wildfire_updates =
      json
      |> Map.put("type", "wildfire_updates")
      |> Jason.encode!(pretty: true)
    {:push, {:text, wildfire_updates}, state}
  end

  @doc """
  Handles and logs frames received from the client.

  ## Parameters
  - `frame`: The frame received from the client.
  - `state`: The current state of the WebSocket handler.

  ## Returns
  - `{:ok, state}`: The updated state of the WebSocket handler.
  """
  @impl WebSock
  @spec handle_in({binary(), [opcode: WebSock.data_opcode()]}, WebSock.state()) :: {:ok, WebSock.state()}
  def handle_in({msg, [opcode: _opcode]}, state) do
    Logger.debug("Received message from client: #{inspect(msg)}")
    {:ok, state}
  end

  @doc """
  Handles the termination of the WebSocket connection and logs the termination reason.

  ## Parameters
  - `reason`: The reason for terminating the WebSocket connection.
  - `state`: The current state of the WebSocket handler.

  ## Returns
  - `:ok`: Indicates successful termination of the WebSocket connection.
  """
  @impl WebSock
  @spec terminate(WebSock.close_reason(), WebSock.state()) :: :ok
  def terminate(reason, _) do
    Logger.info("WebSocket connection terminated with reason: #{inspect(reason)}")
    :ok
  end
end
