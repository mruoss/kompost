import Config

config :logger,
  compile_time_purge_matching: [
    [library: :bonny],
    [library: :k8s],
    [library: :k8s_webhoox]
  ]

import_config "bonny.exs"
