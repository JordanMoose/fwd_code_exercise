defmodule FwdCodeExercise.Router do
  @moduledoc """
  The router module for the application.
  Upgrades the connection to a WebSocket and passes it to the SocketHandler module.
  """

  use Plug.Router

  plug Plug.Logger
  plug :match
  plug :dispatch

  # WebSocket connection timeout set to 16 minutes because the ArcGIS API updates every 15 minutes.
  # This allows for small a buffer in case of delays or issues with the connection.
  @timeout 60_000 * 16

  get "/" do
    WebSockAdapter.upgrade(conn, FwdCodeExercise.SocketHandler, %{}, [timeout: @timeout])
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
