import Config

config :kompost,
  operator_namespace: System.get_env("BONNY_POD_NAMESPACE", "kompost")

config :kompost, Kompost.Kompo,
  postgres: System.get_env("KOMPO_POSTGRES_ENABLED", "true") in ["true", "1"],
  temporal: System.get_env("KOMPO_TEMPORAL_ENABLED", "true") in ["true", "1"]

log_level = System.get_env("LOG_LEVEL")

if log_level do
  config :logger,
    level: log_level |> String.to_atom()
end
