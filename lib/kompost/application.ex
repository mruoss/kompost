defmodule Kompost.Application do
  @moduledoc false

  @spec bandit(:adom) :: {module(), keyword()}
  defp bandit(:prod) do
    {Bandit,
     plug: Kompost.Webhooks.Router,
     port: 4000,
     certfile: "/mnt/cert/cert.pem",
     keyfile: "/mnt/cert/key.pem",
     scheme: :https}
  end

  defp bandit(_) do
    {Bandit, plug: Kompost.Webhooks.Router, port: 4000, scheme: :http}
  end

  use Application
  @impl true
  def start(_type, env: env) do
    children = [bandit(env) | kompos(env)]
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
