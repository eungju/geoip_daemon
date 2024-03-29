defmodule GeoipDaemon.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [Plug.Adapters.Cowboy.child_spec(:http, GeoipDaemon.RestPlug, [])]
    supervise(children, strategy: :one_for_one)
  end
end
