defmodule PortScanner.MixProject do
  use Mix.Project

  def project do
    [
      app: :port_scanner,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"}
    ]
  end

  # Add this function
  defp escript do
    [
      main_module: PortScanner.CLI,
      name: "enmap"
    ]
  end
end

