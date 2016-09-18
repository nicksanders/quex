defmodule Quex.Queue do
  use GenServer
  alias Experimental.GenStage
  alias Quex.{DelayQueue, PriorityQueue, Util}

  @moduledoc """
    The queue server handles all access to the queue
  """

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: config.queue_name)
  end

  def init(config) do
    state = %{
      queue_name: config.queue_name,
      producer_name: config.producer_name,
      priority_queue: PriorityQueue.new(),
      delay_queue: DelayQueue.new(),
      to_ack: %{},
      durable: Map.get(config, :durable, false),
      timeout: Map.get(config, :timeout, 500),
    }
    open_table(state.queue_name, state.durable)
    schedule_delay_queue_check(state.timeout)
    {:ok, state}
  end

  def handle_call({:enqueue, data, opts}, _from, state) do
    opts = opts
    |> Keyword.put_new(:priority, 0)
    |> Keyword.put_new(:delay, 0)
    queue_type = get_queue_type(opts[:delay])
    {res, id, state} = enqueue(state, queue_type, data, opts)
    {:reply, {res, id}, state}
  end

  def handle_call({:dequeue}, _from, state) do
    case dequeue(:priority_queue, state) do
      {state, id, meta, data} -> {:reply, [{id, meta, data}], state}
      state -> {:reply, [], state}
    end
  end

  def handle_call({:ack, id}, _from, state) do
    to_ack = Map.delete(state.to_ack, id)
    :ets.delete(state.queue_name, id)
    state = Map.put(state, :to_ack, to_ack)
    {:reply, :ok, state}
  end

  def handle_call({:nack, id}, _from, state) do
    case state.to_ack[id] do
      nil ->
        {:reply, :error, state}
      meta ->
        to_ack = Map.delete(state.to_ack, id)
        state = state
        |> Map.put(:to_ack, to_ack)
        |> update_state_queue(:priority_queue, id, meta)
        :ok = GenStage.async_notify(state.producer_name, :ask)
        {:reply, :ok, state}
    end
  end

  def handle_call({:delete, id}, _from, state) do
    reply = case :ets.lookup(state.queue_name, id) do
      [] ->
        :error
      _ ->
        :ets.delete(state.queue_name, id)
        :ok
    end
    {:reply, reply, state}
  end

  def handle_call(:reset, _from, state) do
    :ets.delete(state.queue_name)
    open_table(state.queue_name, state.durable)
    state = state
    |> Map.put(:priority_queue, PriorityQueue.new())
    |> Map.put(:delay_queue, DelayQueue.new())
    |> Map.put(:to_ack, %{})
    {:reply, :ok, state}
  end

  def handle_call({:size, queue_type}, _from, state) do
    size = case queue_type do
      :delay_queue ->
        DelayQueue.size(state.delay_queue)
      :priority_queue ->
        PriorityQueue.size(state.priority_queue)
      nil ->
        DelayQueue.size(state.delay_queue) + PriorityQueue.size(state.priority_queue)
      _ ->
        :error
    end
    {:reply, size, state}
  end

  def handle_call(:delay_queue_check, _from, state) do
    state = dequeue(:delay_queue, state)
    {:reply, :ok, state}
  end

  def handle_info(:delay_queue_check, state) do
    state = dequeue(:delay_queue, state)
    schedule_delay_queue_check(state.timeout)
    {:noreply, state}
  end

  defp schedule_delay_queue_check(timeout) do
    case timeout > 0 do
      true -> Process.send_after(self(), :delay_queue_check, timeout)
      false -> nil
    end
  end

  defp enqueue(state, queue_type, data, opts) do
    now = Util.now()
    id = opts[:id] || UUID.uuid4()
    meta = get_meta(now, opts[:priority], opts[:delay])
    res = case :ets.insert_new(state.queue_name, {id, {meta, data}}) do
      true -> :ok
      _ -> :error
    end
    state = update_state_queue(state, queue_type, id, meta)
    {res, id, state}
  end

  defp update_state_queue(state, :priority_queue, id, meta) do
    :ok = GenStage.async_notify(state.producer_name, :ask)
    Map.put(state, :priority_queue, PriorityQueue.enqueue(state.priority_queue, id, meta.priority))
  end
  defp update_state_queue(state, :delay_queue, id, meta) do
    Map.put(state, :delay_queue, DelayQueue.enqueue(state.delay_queue, id, meta.priority, meta.active_at))
  end

  defp get_meta(now, priority, 0), do: PriorityQueue.meta(now, priority)
  defp get_meta(now, priority, delay), do: DelayQueue.meta(now, priority, delay)

  defp dequeue(:priority_queue, state) do
    case PriorityQueue.dequeue(state.priority_queue) do
      {nil, _} ->
        state
      {id, priority_queue} ->
        case get(state.queue_name, id) do
          nil ->
            state = state
            |> Map.put(:priority_queue, priority_queue)
            dequeue(:priority_queue, state)
          {meta, data} ->
            to_ack = Map.put(state.to_ack, id, meta)
            state = state
            |> Map.put(:priority_queue, priority_queue)
            |> Map.put(:to_ack, to_ack)
            {state, id, meta, data}
        end
    end
  end

  defp dequeue(:delay_queue, state) do
    case DelayQueue.dequeue(state.delay_queue) do
      {nil, _} -> state
      {id, meta, delay_queue} ->
        state = state
        |> Map.put(:delay_queue, delay_queue)
        |> update_state_queue(:priority_queue, id, meta)
        dequeue(:delay_queue, state)
    end
  end

  defp get_queue_type(0), do: :priority_queue
  defp get_queue_type(_), do: :delay_queue

  defp open_table(queue_name, false) do
    :ets.new(queue_name, [:named_table, :ordered_set, :private])
  end

  defp open_table(queue_name, true) do
    open_table(queue_name, false)
    :dets.open_file(queue_name, [{:file, queue_name}, {:repair, true}])
    :ets.delete_all_objects(queue_name)
    :ets.from_dets(queue_name, queue_name)
  end

  defp get(queue_name, id) do
    case :ets.lookup(queue_name, id) do
      [{^id, value}] -> value
      [] -> nil
    end
  end

end
