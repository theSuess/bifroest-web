# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :bifroest,
  ecto_repos: [Bifroest.Repo]

# Configures the endpoint
config :bifroest, Bifroest.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "U/Hbl6HBEAwaulXErkbj81yMzfcB3rJxMp7glZmPl5bTprefcQReLbd2M5llpizI",
  render_errors: [view: Bifroest.Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Bifroest.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, []}
  ]

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: System.get_env("GOOGLE_CLIENT_ID"),
  client_secret: System.get_env("GOOGLE_CLIENT_SECRET")

config :guardian, Guardian,
  issuer: "bifroest",
  ttl: { 30, :days },
  allowed_drift: 2000,
  secret_key: "secret",
  serializer: Bifroest.GuardianSerializer


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
