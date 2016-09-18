defmodule Quex.Queue.Consumer do
  alias Experimental.GenStage
  use GenStage
  require Logger

  @moduledoc false

  def start_link(config) do
    GenStage.start_link(__MODULE__, config, name: config.consumer_name)
  end

  def init(config) do
    state = %{
      name: config.consumer_name,
      producer_name: config.producer_name,
      consumer: Map.get(config, :consumer, nil)
    }
    {:consumer, state, subscribe_to: [{config.producer_name, [max_demand: 1, min_demand: 0]}]}
  end

  def handle_info({arg, :ask}, state) do
    :ok = GenStage.ask(arg, 1)
    {:noreply, [], state}
  end

  def handle_events(events, _from, state) do
    _ = case state.consumer do
      consumer when is_function(consumer, 2) ->
        for event <- events do
          apply(consumer, [state.queue, event])
        end
      _ ->
        Logger.debug("Quex (#{state.name}) - #{inspect events}")
    end
    {:noreply, [], state}
  end

end
