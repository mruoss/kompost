import Config

config :logger,
  compile_time_purge_matching: [
    [library: :k8s],
    [library: :bonny]
  ]

import_config "bonny.exs"
