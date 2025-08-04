defmodule FwdCodeExercise.ArcGisPoller do
  @moduledoc """
  A GenServer that periodically fetches wildfire data from the ArcGIS API
  and broadcasts it to subscribers.
  """

  use GenServer
  require Logger
  alias Req.Response
  alias Phoenix.PubSub
  alias FwdCodeExercise.SocketHandler

  # TODO: Set poll interval to 15 minutes to match the ArcGIS API's update frequency
  @default_poll_interval :timer.seconds(60)
  @default_incidents_endpoint "https://services9.arcgis.com/RHVPKKiFTONKtxq3/ArcGIS/rest/services/USA_Wildfires_v1/FeatureServer/0/query"

  @doc """
  Starts the ArcGisPoller GenServer.

  ## Parameters
  - `_opts`: Options for starting the GenServer _(not used in this implementation)_.

  ## Returns
  - `{:ok, pid}`: The process identifier of the started GenServer.
  - `{:error, reason}`: If the GenServer could not be started.
  """
  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @doc """
  Initializes the GenServer state and starts the polling process.

  ## Parameters
  - `state`: The initial state of the GenServer.

  ## Returns
  - `{:ok, state}`: The initial state of the GenServer.
  """
  @impl GenServer
  @spec init(term()) :: {:ok, term()}
  def init(state) do
    send(self(), :wildfire_poll)
    {:ok, state}
  end

  @doc """
  Handles incoming messages from the GenServer.

  When a `:wildfire_poll` message is received, it fetches wildfire data from the ArcGIS API,
  broadcasts the data to subscribers of the "wildfires" topic, and schedules the next poll.

  Other messages are ignored.

  ## Parameters
  - `msg`: The message received by the GenServer.
    - `:wildfire_poll`: Trigger to fetch and broadcast wildfire data.
    - Any other message is ignored.
  - `state`: The current state of the GenServer.

  ## Returns
  - `{:noreply, state :: term()}`: The updated state of the GenServer.
  """
  @impl GenServer
  @spec handle_info(msg :: :wildfire_poll | term(), term()) :: {:noreply, term()}
  def handle_info(:wildfire_poll, state) do
    fetch_and_broadcast()
    poll_interval = Application.get_env(:fwd_code_exercise, :poll_interval, @default_poll_interval)
    Process.send_after(self(), :wildfire_poll, poll_interval)
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # Fetches wildfire data from the ArcGIS API and broadcasts it to subscribers of the "wildfires" topic.
  # Returns:
  # - `:ok`: If the data is successfully fetched and broadcast.
  # - `{:error, error}`: If there is an error fetching or broadcasting the data.
  @spec fetch_and_broadcast() :: :ok | {:error, term()}
  defp fetch_and_broadcast() do
    case fetch_wildfire_data() do
      {:ok, geojson} ->
        PubSub.broadcast(
          FwdCodeExercise.PubSub,
          SocketHandler.topic_name(),
          {:wildfire_updates, geojson}
        )

      {:error, error} ->
        Logger.error("API poll failed: #{inspect(error)}")
        {:error, error}
    end
  end

  # Fetches wildfire data from the ArcGIS API.
  # Returns:
  # - `{:ok, geojson}`: The GeoJSON data fetched from the API.
  # - `{:error, error}`: If there is an error fetching the data.
  @spec fetch_wildfire_data() :: {:ok, map()} | {:error, binary()}
  defp fetch_wildfire_data() do
    incidents_endpoint = Application.get_env(:fwd_code_exercise, :incidents_endpoint, @default_incidents_endpoint)
    params = [
      f: "geojson",
      where: "1=1",
      returnGeometry: true,
      outSR: 4326,
    ]

    case Req.get(incidents_endpoint, params: params) do
      {:ok, %Response{body: %{"error" => error}}} ->
        {:error, "Failed to fetch wildfires data: #{inspect(error)}"}

      {:ok, %Response{body: %{} = geojson}} ->
        Logger.info("Fetched wildfires data successfully")
        {:ok, geojson}

      {:ok, %Response{body: body}} ->
        {:error, "Failed to fetch wildfires data: #{inspect(body)}"}

      {:error, error} ->
        {:error, "Failed to fetch wildfires data: #{inspect(error)}"}
    end
  end
end
