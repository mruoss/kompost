import Config

import_config "bonny.exs"

if File.exists?("#{Mix.env()}.exs"), do: import_config("#{Mix.env()}.exs")
