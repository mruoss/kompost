defmodule Kompost.Application do
  @moduledoc false

  use Application
  @impl true
  def start(_type, env: env) do
    children = kompos(env)

    opts = [strategy: :one_for_one, name: Kompost.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp kompos(env) when env in [:dev, :test] do
    [{Kompost.Kompo.Postgres.Supervisor, operator_args: [conn: conn(:dev)]}]
  end

  defp kompos(_) do
    # TODO
    []
  end

  defp conn(env), do: Kompost.K8sConn.get!(env)
end
