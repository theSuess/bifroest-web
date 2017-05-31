defmodule Bifroest.Mixfile do
  use Mix.Project

  def project do
    {result, _exit_code} = System.cmd("git", ["describe", "--tags", "--long"])

    # We'll truncate the commit SHA to 7 chars. Feel free to change
    git_sha = String.trim(result)

    [app: :bifroest,
     version: git_sha,
     elixir: "~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {Bifroest.Application, []},
     extra_applications: [:logger, :ueberauth_google, :wobserver, :httpoison, :bamboo],
     applications: [:logger,
                    :ueberauth_google,
                    :wobserver,
                    :httpoison,
                    :bamboo,
                    :phoenix_html,
                    :postgrex,
                    :guardian,
                    :bamboo_smtp,
                    :cowboy,
                    :phoenix_pubsub,
                    :exredis,
                    :gettext,
                    :phoenix_ecto,
                    :phoenix
                   ]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.3.0-rc", override: true},
     {:phoenix_pubsub, "~> 1.0"},
     {:phoenix_ecto, "~> 3.2"},
     {:postgrex, ">= 0.0.0"},
     {:phoenix_html, "~> 2.6"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:gettext, "~> 0.11"},
     {:ueberauth_google, "~> 0.5"},
     {:guardian, "~> 0.14"},
     {:wobserver, "~> 0.1"},
     {:exredis, ">= 0.2.4"},
     {:httpoison, "~> 0.11.0"},
     {:exredis, ">= 0.2.4"},
     {:exrm, "~> 1.0"},
     {:bamboo, "~> 0.7"},
     {:bamboo_smtp, "~> 1.2.1"},
     {:cowboy, "~> 1.0"}]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
