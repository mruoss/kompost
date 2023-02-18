defmodule Kompost.Compo.PSQL.Instance do
  alias Kompost.Kompo.Postgres.ConnectionRegistry
  alias Kompost.Kompo.Postgres.ConnectionSupervisor

  def connect(id, args) do
    with {:lookup, []} <- {:lookup, Registry.lookup(ConnectionRegistry, id)},
         {:ok, _} <-
           args
           |> Postgrex.Utils.default_opts()
           |> Postgrex.Protocol.connect() do
      Keyword.put(args, :name, {:via, Registry, {ConnectionRegistry, id}})
      DynamicSupervisor.start_child(ConnectionSupervisor, {Postgrex, args})
    else
      {:lookup, [conn, _]} -> {:ok, conn}
      connection_error -> connection_error
    end
  end
end
