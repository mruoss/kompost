defmodule Kompost.Kompo.Postgres.Supervisor do
  use Supervisor

  def start_link(init_args) do
    Supervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @impl true
  def init(operator_args: operator_args) do
    children = [
      {Registry, keys: :unique, name: Kompost.Kompo.Postgres.ConnectionRegistry},
      {DynamicSupervisor, name: Kompost.Kompo.Postgres.ConnectionSupervisor},
      {Kompost.Kompo.Postgres.Operator,
       Keyword.put(operator_args, :name, Kompost.Kompo.Postgres.Operator)}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
