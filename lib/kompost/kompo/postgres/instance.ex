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
      {:lookup, [{conn, _}]} -> {:ok, conn}
      connection_error -> connection_error
    end
  end

  @spec get_id(resource :: map()) :: id()
  def get_id(resource), do: {resource["metadata"]["namespace"], resource["metadata"]["name"]}

  @spec check_privileges(Postgrex.conn()) :: :ok | {:error, binary()}
  def check_privileges(conn) do
    case Postgrex.query(
           conn,
           "select rolcreaterole,rolcreatedb from pg_authid where rolname = CURRENT_USER",
           []
         ) do
      {:ok, result} ->
        case result.rows do
          [[true, true]] -> :ok
          [[false, _]] -> {:error, "The user does not have the CREATEROLE privilege."}
          [[_, false]] -> {:error, "The user does not have the CREATEDB privilege."}
        end

      _ ->
        {:error, "Unable to query the current user's privileges."}
    end
  end

  @spec disconnect(id()) :: :ok
  def disconnect(id) do
    case Registry.lookup(ConnectionRegistry, id) do
      [{conn, _}] ->
        Process.exit(conn, :normal)
        :ok

      [] ->
        :ok
    end
  end
end
