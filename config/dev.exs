use Mix.Config

config :quex,
  queues: %{
    test: %{workers: 2}
  }
