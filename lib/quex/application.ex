defmodule Quex.Application do
  use Application
  alias Quex.Util

  @moduledoc false

  def start(_type, args) do
    import Supervisor.Spec, warn: false

    queues = case args[:queues] do
      nil -> Application.get_env(:quex, :queues) || %{}
      queues -> queues
    end

    children = Enum.reduce(queues, [], fn({queue, config}, children) ->
      case config do
        config when is_map(config) ->
          children ++ build_children(queue, config)
        _ ->
          children
      end
    end)

    children = [worker(Quex.Tcp.Server, [])] ++ children

    opts = [strategy: :one_for_one, name: Quex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def build_children(queue, config) do
    import Supervisor.Spec, warn: false

    config = config
    |> Map.put(:queue_name, Util.queue_name(queue))
    |> Map.put(:producer_name, Util.producer_name(queue))

    consumers = case Map.get(config, :workers, 1) do
      num_workers when num_workers > 0 ->
        for worker_num <- 1..num_workers do
          config = Map.put(config, :consumer_name, Util.consumer_name(queue, worker_num))
          worker(Quex.Queue.Consumer, [config], id: config.consumer_name)
        end
      _ -> []
    end

    queue = [worker(Quex.Queue, [config])]
    producer = [worker(Quex.Queue.Producer, [config])]
    queue ++ producer ++ consumers
  end


end
