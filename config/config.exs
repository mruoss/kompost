import Config

import_config "bonny.exs"

config :logger,
  level: :debug

if File.exists?("config/#{Mix.env()}.exs") do
  import_config("#{Mix.env()}.exs")
end
