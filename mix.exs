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
    apps = [:logger, :geolix, :poison, :cowboy, :plug]
    dev_apps = [:plug_code_reloader]
    [applications: case Mix.env do
                     :dev -> apps ++ dev_apps
                     _ -> apps end,
     mod: {GeoipDaemon, []}]
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
     {:poison, "~> 1.1.1"},
     {:plug, "~> 0.7.0"},
     {:cowboy, "~> 1.0.0"},
     {:exrm, "~> 0.14.7"},

     {:plug_code_reloader, github: "AgilionApps/PlugCodeReloader", only: [:dev]}]
  end
end
