defmodule Quex.Storage do

  def get(table_name, id, opts \\ []) do
    type = table_type(opts)
    case type.lookup(table_name, id) do
      [{^id, value}] -> value
      [] -> nil
    end
  end

  def open_table(name, opts \\ []) do
    type = table_type(opts)
    case type do
      :ets -> :ets.new(name, [:named_table, :ordered_set, :private])
      _ -> nil
    end
  end

  def table_type(opts), do: opts[:type] || :ets

end
