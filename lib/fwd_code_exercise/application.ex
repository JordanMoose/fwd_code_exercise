defmodule FwdCodeExercise.Application do
  @moduledoc """
  The main application module for the project.
  Starts the application and its supervision tree.
  """

  use Application

  @doc """
  Starts the application and its supervision tree.
  """
  @impl Application
  @spec start(Application.start_type(), term()) ::
          {:ok, pid()}
          | {:error, {:already_started, pid()} | {:shutdown, term()} | term()}
  def start(_type, _args) do
    children =
      if Mix.env() == :test do
        []
      else
        [
          {Phoenix.PubSub, name: FwdCodeExercise.PubSub},
          {Bandit, plug: FwdCodeExercise.Router, ip: :loopback, port: 4000},
          FwdCodeExercise.ArcGisPoller,
          {FwdCodeExercise.SocketClient,
           Application.get_env(:fwd_code_exercise, :websocket_url, "ws://localhost:4000/")}
        ]
      end

    opts = [strategy: :one_for_one, name: FwdCodeExercise.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
