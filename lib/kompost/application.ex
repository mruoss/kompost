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
  defp kompos(env) do
    env
    |> Kompost.Kompo.get_enabled_kompos()
    |> Enum.map(fn
      :postgres ->
        {Kompost.Kompo.Postgres.Supervisor, operator_args: [conn: conn(env)]}

      :temporal ->
        {Kompost.Kompo.Temporal.Supervisor, operator_args: [conn: conn(env)]}
    end)
  end

  @spec conn(atom()) :: K8s.Conn.t()
  defp conn(env), do: Kompost.K8sConn.get!(env)
end
