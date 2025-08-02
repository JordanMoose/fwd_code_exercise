defmodule FwdCodeExercise.Application do
  @moduledoc """
  The main application module for the project.
  Starts the application and its supervision tree.
  """

  use Application

  @spec start(Application.start_type(), start_args :: term())
  :: {:ok, pid()} | {:error, {:already_started, pid()} | {:shutdown, term()} | term()}
  def start(_type, _args) do
    children = [
      {Bandit, plug: FwdCodeExercise.Router}
    ]

    opts = [strategy: :one_for_one, name: FwdCodeExercise.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
