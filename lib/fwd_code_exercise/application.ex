defmodule FwdCodeExercise.Application do
  @moduledoc """
  The main application module for application.
  Starts the application and its supervision tree.
  """

  use Application

  @impl true
  @spec start(any(), any()) :: {:ok, pid()} | {:error, {:already_started, pid()} | {:shutdown, term()} | term()}
  def start(_type, _args) do
    children = [
      {Bandit, plug: FwdCodeExercise.Router, scheme: :http, port: 4000}
    ]

    opts = [strategy: :one_for_one, name: FwdCodeExercise.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
