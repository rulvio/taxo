defmodule Taxo.MixProject do
  use Mix.Project

  @version "0.2.0"
  @source_url "https://github.com/rulvio/taxo"

  def project do
    [
      app: :taxo,
      version: @version,
      elixir: "~> 1.18",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Taxo",
      source_url: @source_url,
      docs: docs(),
      dialyzer: dialyzer()
    ]
  end

  def cli do
    [preferred_envs: [dialyzer: :dev, docs: :dev]]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    "Taxo is an Elixir port of the Clojure hierarchies provided by `derive` and `underive`."
  end

  defp package do
    [
      files: ~w(lib docs .formatter.exs mix.exs README.md CHANGELOG.md CONTRIBUTORS.md LICENSE),
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: [
        "README.md",
        "docs/hierarchies.md": [title: "How hierarchies work"],
        "CHANGELOG.md": [title: "Changelog"],
        LICENSE: [title: "License"]
      ],
      groups_for_extras: [
        Guides: ["README.md", "docs/hierarchies.md"],
        About: ["CHANGELOG.md", "LICENSE"]
      ]
    ]
  end

  defp dialyzer do
    [
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      plt_add_apps: [:mix, :ex_unit],
      flags: [:error_handling, :extra_return, :missing_return, :unmatched_returns]
    ]
  end
end
