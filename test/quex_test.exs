defmodule QuexPriorityTest do
  use ExUnit.Case, async: false
  doctest Quex

  setup context do
    {workers, timeout, consumer} = case context[:consumer] do
      true ->
        {:ok, _} = GenServer.start_link(Quex.Test.Consumer, [], name: Quex.Test.Consumer.name())
        {1, 100, &Quex.Test.Consumer.consume/2}
      _ ->
        {0, 0, nil}
    end

    queues = %{
      test: %{
        consumer: consumer,
        workers: workers,
        timeout: timeout,
        durable: context[:durable] || false,
      }
    }

    {:ok, _pid} = Quex.Application.start(:normal, [queues: queues])

    # on_exit fn ->
    #   if context[:persistent] do
    #     File.rm(table |> to_string)
    #   end
    # end

    :ok
  end

  test "manual priority queue" do
    assert Quex.size(:test) == 0
    assert {:ok, _id} = Quex.enqueue(:test, "test")
    assert Quex.size(:test) == 1
    assert Quex.size(:test, :priority_queue) == 1

    [{id, _meta, data}] = Quex.dequeue(:test)
    assert data == "test"

    [] = Quex.dequeue(:test)

    assert Quex.size(:test) == 0
    assert Quex.nack(:test, "fake-id") == :error
    assert Quex.size(:test) == 0
    assert Quex.nack(:test, id) == :ok
    assert Quex.size(:test) == 1

    [{id, _meta, data}] = Quex.dequeue(:test)
    assert data == "test"
    assert Quex.size(:test) == 0
    assert Quex.ack(:test, id) == :ok
    assert Quex.size(:test) == 0

    assert Quex.size(:test, :fake_queue_type) == :error

    id = "some-id"
    assert {:ok, ^id} = Quex.enqueue(:test, "test", [id: id])
    assert Quex.size(:test) == 1
    assert Quex.delete(:test, id) == :ok
    assert Quex.delete(:test, id) == :error
    [] = Quex.dequeue(:test)

    Quex.reset(:test)
  end

  test "manual delay queue" do
    assert Quex.size(:test) == 0
    assert {:ok, _id} = Quex.enqueue(:test, "test2", [delay: 1])
    assert Quex.size(:test) == 1

    assert Quex.size(:test, :delay_queue) == 1
    assert Quex.size(:test, :priority_queue) == 0

    :timer.sleep(500)
    Quex.force_delay_queue_check(:test)
    assert Quex.size(:test, :delay_queue) == 1
    assert Quex.size(:test, :priority_queue) == 0

    :timer.sleep(1500)
    Quex.force_delay_queue_check(:test)
    assert Quex.size(:test, :delay_queue) == 0
    assert Quex.size(:test, :priority_queue) == 1

    [{_id, _meta, data}] = Quex.dequeue(:test)
    assert data == "test2"
  end

  @tag consumer: true
  test "priority queue with consumer" do
    assert {:ok, id} = Quex.enqueue(:test, "test")
    :timer.sleep(50)
    assert {:test, {rtn_id, %{priority: 0, queued_at: _}, "test"}} = Quex.Test.Consumer.pop()
    assert rtn_id == id
    assert Quex.Test.Consumer.pop() == nil
  end


end
