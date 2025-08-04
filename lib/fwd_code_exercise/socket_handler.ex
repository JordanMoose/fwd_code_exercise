defmodule FwdCodeExercise.SocketHandler do
  @moduledoc """
  Handles WebSocket connections for the "wildfires" topic,
  receiving updates from the ArcGIS API and pushing them to connected clients.
  """

  @behaviour WebSock
  require Logger
  alias FwdCodeExercise.PubSubClient

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
    case PubSubClient.subscribe(FwdCodeExercise.PubSub, @topic_name) do
      :ok ->
        Logger.info("Subscribed to topic: #{@topic_name}")
        {:ok, %{}}

      {:error, reason} ->
        Logger.error("Failed to subscribe to topic: #{@topic_name}, reason: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Handles incoming messages on the "wildfires" topic.

  If the message is of type `{:wildfire_updates, geojson}`,
  it pushes the stringified GeoJSON data to the client.

  For other messages, the state is returned unchanged.

  ## Parameters
  - `message`: The GeoJSON data received from the ArcGisPoller, or another message.
  - `state`: The current state of the WebSocket handler.

  ## Returns
  - `{:push, {:text, json}, state}`: The updated state of the WebSocket handler with the stringified GeoJSON data.
  - `{:ok, state}`: The unchanged state if the message is not related to wildfire updates or if encoding fails.
  """
  @impl WebSock
  @spec handle_info(term(), WebSock.state()) ::
          {:push, {:text, binary()}, WebSock.state()} | {:ok, WebSock.state()}
  def handle_info({:wildfire_updates, %{} = geojson}, state) do
    with wildfire_updates <- Map.put(geojson, "is_wildfire_update", true),
         {:ok, stringified_json} <- Jason.encode(wildfire_updates, pretty: true) do
      {:push, {:text, stringified_json}, state}
    else
      {:error, error} ->
        Logger.error("Failed to encode wildfire updates: #{inspect(error)}")
        {:ok, state}
    end
  end

  def handle_info(_message, state) do
    # Ignore other messages
    {:ok, state}
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
  @spec handle_in({binary(), [opcode: WebSock.data_opcode()]}, WebSock.state()) ::
          {:ok, WebSock.state()}
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
