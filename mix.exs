defmodule FwdCodeExercise.MixProject do
  use Mix.Project

  def project do
    [
      app: :fwd_code_exercise,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {FwdCodeExercise.Application, []}
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:bandit, "~> 1.7"},
      {:websock, "~> 0.5.3"},
      {:websock_adapter, "~> 0.5.8"},
      {:websockex, "~> 0.4.3"},
      {:phoenix_pubsub, "~> 2.1"},
      {:req, "~> 0.5.15"},
      {:jason, "~> 1.4"},
      {:mock, "~> 0.3.9", only: :test},
    ]
  end
end
