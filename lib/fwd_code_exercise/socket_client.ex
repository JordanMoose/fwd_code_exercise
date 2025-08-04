defmodule FwdCodeExercise.SocketClient do
  @moduledoc """
  Connects to the websocket server to receive updates pushed to the "wildfires" topic.
  """

  use WebSockex
  require Logger

  @default_output_filepath "wildfire_updates/wildfire_data"

  @doc """
  Starts a websocket connection to the specified URL and logs the connection status.

  ## Parameters
  - `url`: The websocket URL to connect to.

  ## Returns
  - `{:ok, pid}`: The process identifier of the started websocket client.
  - `{:error, reason}`: If the websocket client could not be started.
  """
  @spec start_link(binary()) :: {:ok, pid()} | {:error, term()}
  def start_link(url) do
    case WebSockex.start_link(url, __MODULE__, %{}) do
      {:ok, pid} ->
        Logger.info("Socket client connected to #{url} with PID #{inspect(pid)}")
        {:ok, pid}

      {:error, reason} ->
        Logger.error("Failed to connect socket client: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Handles received frames on the websocket connection.

  When a frame is received, it checks if its message contains wildfire updates.
  If it does, it processes the updates and saves them to a file.
  Otherwise, it logs the message.

  ## Parameters
  - `frame`: The frame received on the websocket.
  - `state`: The current state of the websocket handler.

  ## Returns
  - `{:reply, {:text, message}, state}`: If the frame contains wildfire updates, it replies with a confirmation message.
  - `{:ok, state}`: If the frame does not contain wildfire updates, it logs the message and returns the updated state.
  - `{:error, reason}`: If there is an error processing the frame.
  """
  @impl WebSockex
  @spec handle_frame(WebSockex.frame(), term()) ::
          {:ok, term()} | {:reply, WebSockex.frame(), term()}
  def handle_frame({:text, msg} = frame, state) do
    case Jason.decode(msg) do
      {:ok, %{"is_wildfire_update" => true} = json} ->
        handle_wildfire_updates(json, state)

      _ ->
        handle_other_frame(frame, state)
    end
  end

  # Handles wildfire updates received on the websocket.
  # Saves the updates to a timestamped JSON file and logs the action.
  #
  # ## Parameters
  # - `json`: The GeoJSON representation of the wildfire updates.
  # - `state`: The current state of the websocket handler.
  #
  # ## Returns
  # - `{:reply, {:text, message}, state}`: The updated state of the websocket with a confirmation message.
  @spec handle_wildfire_updates(map(), term()) :: {:reply, {:text, binary()}, term()}
  defp handle_wildfire_updates(%{"is_wildfire_update" => true} = json, state) do
    output_filepath =
      Application.get_env(:fwd_code_exercise, :output_filepath, @default_output_filepath) <>
        ".#{DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()}.json"

    with geojson <- Map.delete(json, "is_wildfire_update"),
         {:ok, stringified_json} <- Jason.encode(geojson, pretty: true),
         :ok <- File.write(output_filepath, stringified_json) do
      Logger.info("Received wildfire updates and saved to #{output_filepath}")
      {:reply, {:text, "Wildfire updates saved to #{output_filepath}"}, state}
    else
      {:error, Jason.EncodeError = reason} ->
        Logger.error("Failed to encode GeoJSON data: #{inspect(reason)}")
        {:reply, {:text, "Error processing wildfire updates"}, state}

      {:error, :enoent} ->
        output_directory = Path.dirname(output_filepath)
        case File.mkdir_p(output_directory) do
          :ok ->
            Logger.debug("Created directory for output file: #{output_directory}")
            handle_wildfire_updates(json, state)

          {:error, reason} ->
            Logger.error("Failed to create directory for output file: #{inspect(reason)}")
            {:reply, {:text, "Error saving wildfire updates"}, state}
        end

      {:error, reason} ->
        Logger.error("Failed to write wildfire updates to file: #{inspect(reason)}")
        {:reply, {:text, "Error saving wildfire updates"}, state}
    end
  end

  defp handle_wildfire_updates(_json, state) do
    Logger.warning("Received unexpected message format for wildfire updates")
    {:reply, {:text, "Unexpected message format"}, state}
  end

  # Handles other frames received on the websocket connection.
  # Logs the message and returns the updated state.
  #
  # ## Parameters
  # - `frame`: The frame received on the websocket.
  # - `state`: The current state of the websocket handler.
  #
  # ## Returns
  # - `{:ok, state}`: The updated state of the websocket handler.
  @spec handle_other_frame(WebSockex.frame(), term()) :: {:ok, term()}
  defp handle_other_frame({:text, msg}, state) do
    Logger.info("Received message: #{msg}")
    {:ok, state}
  end

  @doc """
  Handles the connection to the websocket server.
  Logs the connection status and returns the updated state.

  ## Parameters
  - `_conn`: The connection details _(not used in this implementation)_.
  - `state`: The current state of the websocket handler.

  ## Returns
  - `{:ok, state}`: The updated state of the websocket handler.
  """
  @impl WebSockex
  @spec handle_connect(WebSockex.Conn.t(), term()) :: {:ok, term()}
  def handle_connect(_conn, state) do
    Logger.info("Connected to websocket server")
    {:ok, state}
  end

  @doc """
  Handles disconnection from the websocket server.
  Logs the disconnection reason and returns the updated state.

  ## Parameters
  - `reason`: The reason for the disconnection.
  - `state`: The current state of the websocket handler.

  ## Returns
  - `{:ok, state}`: The updated state of the websocket handler.
  """
  @impl WebSockex
  @spec handle_disconnect(term(), term()) :: {:ok, term()}
  def handle_disconnect(reason, state) do
    Logger.warning("Disconnected from websocket server: #{inspect(reason)}")
    {:ok, state}
  end

  @doc """
  Handles the termination of the websocket connection.
  Logs the termination reason and returns `:ok`.

  ## Parameters
  - `reason`: The reason for the termination.
  - `_state`: The current state of the websocket handler _(not used in this implementation)_.

  ## Returns
  - `:ok`: Indicates successful termination.
  """
  @impl WebSockex
  @spec terminate(term(), term()) :: :ok
  def terminate(reason, _state) do
    Logger.info("Websocket connection terminated: #{inspect(reason)}")
    :ok
  end
end
