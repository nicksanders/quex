defmodule Quex.Test.Consumer do
  use GenServer

  @moduledoc false

  @name :test_consumer

  def name(), do: @name

  def consume(queue, data) do
    GenServer.call(@name, {:consume, {queue, data}})
  end

  def pop() do
    GenServer.call(@name, :pop)
  end

  # Callbacks
  def handle_call({:consume, item}, _from, state) do
    {:noreply, [item | state]}
  end

  def handle_call(:pop, _from, []), do: {:reply, nil, []}
  def handle_call(:pop, _from, [h | t]) do
    {:reply, h, t}
  end

end
