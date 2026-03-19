import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :la_tasks, LaTasks.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "la_tasks_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :la_tasks, LaTasksWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "rpmbjg1Sd7tPL2kUVi4yUWI17RDOaNq8mg7cWrdXZwj9K0mXC1m1/z8q/uSE2HqU",
  server: false

# In test we don't send emails
config :la_tasks, LaTasks.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# argon2
config :argon2_elixir,
  t_cost: 1,
  m_cost: 8

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
