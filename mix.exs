defmodule GeoipDaemon.Mixfile do
  use Mix.Project

  def project do
    [app: :geoip_daemon,
     version: "0.0.1",
     elixir: "~> 1.0.0",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:geolix, :cowboy, :plug, :logger, :plug_code_reloader],
     mod: {GeoipDaemon.Application, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [{:geolix, github: "mneudert/geolix" },
     {:jazz, "~> 0.2.1"},
     {:cowboy, "~> 1.0.0"},
     {:plug, "~> 0.7.0"},

     {:plug_code_reloader, github: "AgilionApps/PlugCodeReloader"}]
  end
end
