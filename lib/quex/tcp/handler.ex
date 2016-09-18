defmodule Quex.Tcp.Handler do

  def start_link(ref, socket, transport, opts) do
    pid = spawn_link(__MODULE__, :init, [ref, socket, transport, opts])
    {:ok, pid}
  end

  def init(ref, socket, transport, _Opts = []) do
    :ok = :ranch.accept_ack(ref)
    loop(socket, transport)
  end

  def loop(socket, transport) do
    case transport.recv(socket, 0, :infinity) do
      {:ok, data} ->
        reply = process(data)
        transport.send(socket, reply <> ":" <> data <> ":")
        loop(socket, transport)
      _ ->
        :ok = transport.close(socket)
    end
  end

  def process("put " <> data) do
    case String.split(data, "\r\n", parts: 2) do
      [parts, data] ->
        case String.split(parts) do
          [delay, ttl, bytes] ->
            put(delay, ttl, bytes, data)
          _ ->
            "BAD_FORMAT\r\n"
        end
      _ ->
        "BAD_FORMAT\r\n"
    end
  end

  def process("reserve\r\n") do
    "RESERVED <id> <bytes>\r\n<data>\r\n"
  end

  def process(_), do: "UNKNOWN_COMMAND\r\n"

  defp put(delay, ttl, bytes, data) do
    case String.split_at(data, -1) do
      {data, "\r\n"} ->
        IO.puts("Recived PUT")
        "INSERTED <id>\r\n"
      x ->
        "#{inspect x}"
        # "EXPECTED_CRLF\r\n"
    end
  end

  defp check_bytes(bytes) do

  end

end
