use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :bifroest, Bifroest.Web.Endpoint,
  http: [port: 4001],
  server: false

config :bifroest, :openstack_api, Bifroest.Openstack.ApiMock
# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :bifroest, Bifroest.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "",
  database: "bifroest_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
