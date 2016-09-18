defmodule Quex.DelayQueue do
  alias Quex.Util

  @moduledoc """
    Functions for creating and accessing the delay queue
  """

  def new(), do: :pqueue2.new()

  def enqueue(queue, id, priority, active_at) do
    :pqueue2.in({id, priority}, active_at, queue)
  end

  def dequeue(queue), do: dequeue(queue, Util.now())
  def dequeue(queue, now) when elem(queue, 0) < now do
    case :pqueue2.pout(queue) do
      {:empty, queue} -> {nil, queue}
      {{:value, {id, priority}, active_at}, queue} ->
        meta = %{priority: priority, active_at: active_at}
        {id, meta, queue}
    end
  end
  def dequeue(queue, _), do: {nil, queue}

  def size(queue), do: :pqueue2.len(queue)

  def meta(now, priority, delay) do
    active_at = delay + now
    %{queued_at: now, priority: priority, active_at: active_at}
  end

end
