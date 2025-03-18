defmodule Taxo.MixProject do
  use Mix.Project

  def project do
    [
      app: :taxo,
      version: "0.1.0",
      elixir: "~> 1.18",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Taxo",
      source_url: "https://github.com/rulvio/taxo"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [{:ex_doc, ">= 0.0.0", only: :dev, runtime: false}]
  end

  defp description() do
    "Taxo is an Elixir port of the Clojure hierarchies provided by `derive` and `underive`."
  end

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README.md CHANGELOG.md CONTRIBUTORS.md LICENSE),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/rulvio/taxo"}
    ]
  end
end
