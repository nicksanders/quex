defmodule Quex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :quex,
      version: "0.1.0",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: [plt_add_deps: :transitive],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        "coveralls": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
   ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [:logger, :uuid, :pqueue, :gen_stage, :ranch],
      mod: {Quex.Application, []}
    ]
  end

  defp deps do
    [
      {:ranch, "~> 1.2.1" },
      {:uuid, "~> 1.1" },
      {:pqueue, "~> 1.5"},
      {:gen_stage, "~> 0.5"},
      {:ex_doc, "~> 0.13", only: :dev},
      {:excoveralls, "~> 0.5", only: :test},
      {:credo, "~> 0.4", only: [:dev, :test]},
      {:dialyxir, "~> 0.3.5", only: [:dev]}
    ]
  end

  defp aliases do
    [
      "test": ["test --no-start"]
    ]
  end
end
