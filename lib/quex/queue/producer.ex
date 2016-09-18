defmodule Quex.Queue.Producer do
  alias Experimental.GenStage
  use GenStage
  require Logger

  @moduledoc false

  def start_link(config) do
    GenStage.start_link(__MODULE__, config, name: config.producer_name)
  end

  def init(config) do
    state = %{
      name: config.producer_name,
      queue_name: config.queue_name,
    }
    {:producer, state, buffer_size: 1}
  end

  def handle_demand(demand, state) when demand > 0 do
    # Logger.debug("Quex (#{state.name}) - received demand #{demand}")
    events = GenServer.call(state.queue_name, {:dequeue})
    {:noreply, events, state}
  end

end
