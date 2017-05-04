# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :bifroest,
  ecto_repos: [Bifroest.Repo],
  organization_name: "htl-ottakring.ac.at",
  domain_base: ".projekte.htl-ottakring.at",
  password_length: 8,
  admin_project_id: "4092ec0a093b452c9b80035ca4187d36",
  default_role_id: "8d25f9a481e44124b8f1d0071ff0f247",
  admin_role_id: "bb523f0c846c4c74a660f4ef52e66af0",
  admin_user_id: "3328200144804bc3a75bd373408008dd",
  openstack_username: System.get_env("OS_USERNAME"),
  openstack_password: System.get_env("OS_PASSWORD"),
  openstack_auth_url: System.get_env("OS_AUTH_URL"),
  openstack_compute_url: System.get_env("OS_COMPUTE_URL"),
  openstack_image_url: System.get_env("OS_IMAGE_URL"),
  openstack_network_url: System.get_env("OS_NETWORK_URL")

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
  serializer: Bifroest.GuardianSerializer,
  permissions: %{
    default: [
      :admin,
      :user,
    ]
  }

config :exredis,
  host: "127.0.0.1",
  port: 6379,
  password: "",
  db: 0,
  reconnect: :no_reconnect,
  max_queue: :infinity

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
