defmodule Quex do
  alias Quex.Util

  @moduledoc """
    An Elixir OTP GenServer that provides the ability to queue data with a priority and/or a delay.
    The data isn't removed from the queue until it is acknowledged.
    Data can be dequeued manually or by specifying a consumer which uses GenStage to subscribe to the queue.
  """

  @doc """
  Enqueues data to the queue
  """
  def enqueue(queue, data, opts \\ []) do
    queue
    |> Util.queue_name()
    |> GenServer.call({:enqueue, data, opts})
  end

  @doc """
  Dequeues data from the queue
  """
  @spec dequeue(atom) :: String.t()
  def dequeue(queue) do
    queue
    |> Util.queue_name()
    |> GenServer.call({:dequeue})
  end

  @doc """
  Acknowledges an item in the queue can be removed
  """
  @spec ack(atom, String.t()) :: :ok
  def ack(queue, id) do
    queue
    |> Util.queue_name()
    |> GenServer.call({:ack, id})
  end

  @doc """
  Acknowledges an item in the queue should be requeued
  """
  @spec nack(atom, String.t()) :: :ok
  def nack(queue, id) do
    queue
    |> Util.queue_name()
    |> GenServer.call({:nack, id})
  end

  @doc """
  Delete an item from the queue

  WARNING: If you delete an item from the queue the queue size won't be correct
  until the item reaches the head of the queue and is dropped
  """
  @spec delete(atom, String.t()) :: :ok
  def delete(queue, id) do
    queue
    |> Util.queue_name()
    |> GenServer.call({:delete, id})
  end

  @doc """
  Reset the queue
  """
  @spec reset(atom) :: :ok
  def reset(queue) do
    queue
    |> Util.queue_name()
    |> GenServer.call(:reset)
  end

  @doc """
  Gets the size of the queue
  """
  @spec size(String.t(), atom|nil) :: integer
  def size(queue, queue_type \\ nil) do
    queue
    |> Util.queue_name()
    |> GenServer.call({:size, queue_type})
  end

  @doc """
  Force check of delay queue
  """
  @spec force_delay_queue_check(atom) :: :ok
  def force_delay_queue_check(queue) do
    queue
    |> Util.queue_name()
    |> GenServer.call(:delay_queue_check)
  end

end
