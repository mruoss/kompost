defmodule Kompost.Webhooks.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  forward "/postgres", to: Kompost.Kompo.Postgres.Webhooks.Router
end
