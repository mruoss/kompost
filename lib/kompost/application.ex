defmodule Kompost.Application do
  @moduledoc false

  use Application
  @impl true
  def start(_type, env: env) do
    children = kompos(env)

    opts = [strategy: :one_for_one, name: Kompost.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @spec kompos(atom()) :: list({module(), term()})
  defp kompos(env) when env in [:dev, :test] do
    [{Kompost.Kompo.Postgres.Supervisor, operator_args: [conn: conn(env)]}]
  end

  defp kompos(_) do
    # TODO
    []
  end

  @spec conn(atom()) :: K8s.Conn.t()
  defp conn(env), do: Kompost.K8sConn.get!(env)
end
