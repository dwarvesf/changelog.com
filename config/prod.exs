use Mix.Config

config :changelog, ChangelogWeb.Endpoint,
  http: [port: 4000],
  url: [scheme: (System.get_env("URL_SCHEME") || "https"), host: (System.get_env("URL_HOST") || "next.superbits.co"), port: (System.get_env("URL_PORT") || 443)],
  force_ssl: [
    rewrite_on: [:x_forwarded_proto],
    exclude: ["127.0.0.1", "localhost", "changelog.localhost"]
  ],
  secret_key_base: DockerSecret.get("SECRET_KEY_BASE"),
  static_url: [scheme: (System.get_env("URL_SCHEME") || "https"), host: (System.get_env("URL_STATIC_HOST") || "next.superbits.co"), port: (System.get_env("URL_PORT") || 443)],
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info
# config :logger, :console, level: :debug, format: "[$level] $message\n"

config :arc,
  storage_dir: "/uploads"

config :changelog, Changelog.Repo,
  url: DockerSecret.get("DB_URL"),
  adapter: Ecto.Adapters.Postgres,
  pool_size: 20,
  timeout: 60000

config :changelog, Changelog.Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: "smtp.gmail.com",
  port: 587,
  username: "no-reply@dwarvesv.com",
  password: DockerSecret.get("CM_SMTP_TOKEN"),
  tls: :if_available, # can be `:always` or `:never`
  allowed_tls_versions: [:"tlsv1", :"tlsv1.1", :"tlsv1.2"], # or {":system", ALLOWED_TLS_VERSIONS"} w/ comma seprated values (e.g. "tlsv1.1,tlsv1.2")
  ssl: false, # can be `true`
  retries: 1

config :changelog, Changelog.Scheduler,
  global: true,
  timezone: "Asia/Ho_Chi_Minh",
  jobs: [
    {"0 4 * * *", {Changelog.Stats, :process, []}},
    {"0 3 * * *", {Changelog.Slack.Tasks, :import_member_ids, []}},
    {"* * * * *", {Changelog.NewsQueue, :publish, []}}
  ]

config :rollbax,
  access_token: DockerSecret.get("ROLLBAR_ACCESS_TOKEN"),
  environment: "production"
