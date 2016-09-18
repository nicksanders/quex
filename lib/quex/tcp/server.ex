defmodule Quex.Tcp.Server do

  def start_link do
    opts = [port: 11301]
    {:ok, _} = :ranch.start_listener(Quex.Application, 100, :ranch_tcp, opts, Quex.Tcp.Handler, [])
  end

end
