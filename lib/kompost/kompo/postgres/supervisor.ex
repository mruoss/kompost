defmodule Kompost.Kompo.Postgres.Supervisor do
  @moduledoc """
  Supervisor for the Postgres Kompo.
  """

  use Supervisor

  alias Kompost.Kompo.Postgres.{
    ConnectionRegistry,
    ConnectionSupervisor,
    Operator
  }

  @spec start_link(Keyword.t()) :: Supervisor.on_start()
  def start_link(init_args) do
    Supervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @impl true
  def init(operator_args: operator_args) do
    children = [
      {Registry, keys: :unique, name: ConnectionRegistry},
      {DynamicSupervisor, name: ConnectionSupervisor},
      {Operator, Keyword.put(operator_args, :name, Operator)}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
