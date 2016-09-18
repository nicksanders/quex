defmodule Quex.PriorityQueue do

  @moduledoc """
    Functions for creating and accessing the priority queue
  """

  def new() do
    :pqueue.new()
  end

  def enqueue(queue, id, priority) do
    :pqueue.in(id, priority, queue)
  end

  def dequeue(queue) do
    case :pqueue.out(queue) do
      {:empty, queue} -> {nil, queue}
      {{:value, id}, queue} -> {id, queue}
    end
  end

  def size(queue), do: :pqueue.len(queue)

  def meta(now, priority) do
    %{queued_at: now, priority: priority}
  end

end
