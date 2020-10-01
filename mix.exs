defmodule EctoPolymorphic.MixProject do
  use Mix.Project

  def project,
    do: [
      app: :ecto_polymorphic,
      version: "0.1.0",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "Library to polymorphism association for Ecto",
      package: [
        links: %{
          github: "https://github.com/aleDsz/ecto-polymorphic"
        },
        licenses: ["MIT"]
      ],
      docs: docs(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application,
    do: [
      extra_applications: [:logger]
    ]

  defp deps,
    do: [
      {:ecto, "~> 3.4"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]

  defp docs,
    do: [
      main: "EctoPolymorphic",
      extras: ["README.md"]
    ]
end
