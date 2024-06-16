# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :visual_garden,
  ecto_repos: [VisualGarden.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :visual_garden, VisualGardenWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: VisualGardenWeb.ErrorHTML, json: VisualGardenWeb.ErrorJSON],
    layout: false
  ],
  http_options: [log_protocol_errors: false],
  pubsub_server: VisualGarden.PubSub,
  live_view: [signing_salt: "/fv/WHvF"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :visual_garden, VisualGarden.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  visual_garden: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.0",
  visual_garden: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger,
  handle_sasl_reports: true

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :flashy,
  disconnected_module: VisualGardenWeb.Components.Notifications.Disconnected

config :sentry,
  environment_name: Mix.env(),
  enable_source_code_context: true,
  root_source_code_paths: [File.cwd!()],
  before_send: {VisualGarden.Sentry, :filter_non_500}

config :web_push_elixir,
  vapid_subject: "mailto:administrator@example.com",
  vapid_public_key:
    "BPyaCVdokvpTRkOb8PpbgVk4tBs73EkiB6_csKP8AsmGL5uEKH_-ykvlIel9OXIIAcoRmzu_PccPfrtNE1WSspQ",
  vapid_private_key: "mE_IQLIkxz7lfMak7rnc8gDA5J6SK-u3KeTWft4GdjA"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
