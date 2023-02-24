import Config

config :kompost, Kompost.Kompo,
  postgres: System.get_env("KOMPO_POSTGRES_ENABLED", "true") in ["true", "1"]
