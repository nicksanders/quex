defmodule Quex.Util do
  require Logger

  @moduledoc false

  @spec now() :: no_return
  def now(), do: div(:os.system_time, 1_000_000_000)

  @spec queue_name(atom) :: atom
  def queue_name(queue) do
    "Quex.Queue.#{Atom.to_string(queue)}"
    |> String.to_atom()
  end

  @spec consumer_name(atom, integer) :: atom
  def consumer_name(queue, worker_num) do
    "Quex.Queue.Consumer.#{Atom.to_string(queue)}.#{worker_num}"
    |> String.to_atom()
  end

  @spec producer_name(atom) :: atom
  def producer_name(queue) do
    "Quex.Queue.Producer.#{Atom.to_string(queue)}"
    |> String.to_atom()
  end

end
