defmodule Kompost.Webhooks.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  post("/postgres", to: Kompost.Kompo.Postgres.Webhooks.Router)
end
