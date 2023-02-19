defmodule Kompost.Kompo.Postgre.Instance do
  @moduledoc """
  Provides an interface to Postgrex. `connect/2` starts Postgrex under
  a dynamic supervisor (`Kompost.Kompo.Postgres.ConnectionSupervisor`) and
  register the process at the `Kompost.Kompo.Postgres.ConnectionRegistry`
  """

  alias Kompost.Kompo.Postgres.ConnectionRegistry
  alias Kompost.Kompo.Postgres.ConnectionSupervisor

  @type id :: {namespace :: binary(), name :: binary()}

  @spec connect(id, Keyword.t()) ::
          {:ok, Postgrex.conn()}
          | {:error, Postgrex.Error.t() | struct()}
          | DynamicSupervisor.on_start_child()
  def connect(id, args) do
    with {:lookup, []} <- {:lookup, Registry.lookup(ConnectionRegistry, id)},
         {:ok, _} <-
           args
           |> Postgrex.Utils.default_opts()
           |> Postgrex.Protocol.connect() do
      args = Keyword.put(args, :name, {:via, Registry, {ConnectionRegistry, id}})
      DynamicSupervisor.start_child(ConnectionSupervisor, {Postgrex, args})
    else
      {:lookup, [conn, _]} -> {:ok, conn}
      connection_error -> connection_error
    end
  end
end
