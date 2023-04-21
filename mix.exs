defmodule ExGitTest.MixProject do
  use Mix.Project

  @github_url "https://github.com/wisq/ex_git_test"

  def project do
    [
      app: :ex_git_test,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      docs: docs(),
      deps: deps(),
      source_url: @github_url
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
    Runs `mix test` on ONLY the code you currently have staged in git.  It's
    designed to go in a git `pre-commit` hook.
    """
  end

  defp package do
    [
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        "LICENSE"
      ],
      maintainers: ["Adrian Irving-Beer"],
      licenses: ["MIT"],
      links: %{GitHub: @github_url}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "CHANGELOG.md"
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:briefly, "~> 0.4.0", runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end
end
