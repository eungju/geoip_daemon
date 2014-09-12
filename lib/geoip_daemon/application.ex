defmodule GeoipDaemon.Application do
  use Application

  def start(_type, _args) do
    GeoipDaemon.Supervisor.start_link
  end
end
