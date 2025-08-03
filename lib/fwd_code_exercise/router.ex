defmodule FwdCodeExercise.Router do
  @moduledoc """
  The router module for the application.
  Upgrades the connection to a WebSocket and passes it to the SocketHandler module.
  """

  use Plug.Router

  plug Plug.Logger
  plug :match
  plug :dispatch

  get "/" do
    WebSockAdapter.upgrade(conn, FwdCodeExercise.SocketHandler, %{}, [])
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
