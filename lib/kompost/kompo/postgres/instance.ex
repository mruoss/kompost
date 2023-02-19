defmodule Kompost.Kompo.Postgres.Instance do
  @moduledoc """
  Provides an interface to Postgrex. `connect/2` starts Postgrex under
  a dynamic supervisor (`Kompost.Kompo.Postgres.ConnectionSupervisor`) and
  register the process at the `Kompost.Kompo.Postgres.ConnectionRegistry`
  """

  alias Kompost.Kompo.Postgres.ConnectionRegistry
  alias Kompost.Kompo.Postgres.ConnectionSupervisor

  @typedoc """
  Defines the ID for an instance. The ID used as key when registering the
  Postgrex process at the `Kompost.Kompo.Postgres.ConnectionRegistry`
  """
  @type id :: {namespace :: binary(), name :: binary()}

  @doc """
  Checks in the `Kompost.Kompo.Postgres.ConnectionRegistry` for an existing
  connection defined by the given `id`. If no such connection exists, a new
  `Postgrex` process is started, connecting to a Postgres instance defined by
  the `conn_args`. The process is then registered at the
  `Kompost.Kompo.Postgres.ConnectionRegistry`.
  """
  @spec connect(id(), conn_args :: Keyword.t()) ::
          {:ok, Postgrex.conn()}
          | {:error, Postgrex.Error.t() | Exception.t()}
          | DynamicSupervisor.on_start_child()
  def connect(id, conn_args) do
    with {:lookup, []} <- {:lookup, lookup(id)},
         {:ok, _} <-
           conn_args
           |> Postgrex.Utils.default_opts()
           |> Postgrex.Protocol.connect() do
      args = Keyword.put(conn_args, :name, {:via, Registry, {ConnectionRegistry, id, conn_args}})
      DynamicSupervisor.start_child(ConnectionSupervisor, {Postgrex, args})
    else
      {:lookup, [{conn, _}]} -> {:ok, conn}
      connection_error -> connection_error
    end
  end

  @doc """
  Checks in the `Kompost.Kompo.Postgres.ConnectionRegistry` for an existing
  connection defined by the given `id`.
  """
  @spec lookup(id()) :: [{pid, any}]
  def lookup(id), do: Registry.lookup(ConnectionRegistry, id)

  @doc """
  Creates an instance id tuple from a resource.

  ### Example

      iex> resource = %{"metadata" => %{"namespace" => "default", "name" => "foo-bar"}}
      ...> Kompost.Kompo.Postgres.Instance.get_id(resource)
      {"default", "foo-bar"}
  """
  @spec get_id(resource :: map()) :: id()
  def get_id(resource), do: {resource["metadata"]["namespace"], resource["metadata"]["name"]}

  @doc """
  Checks if the user connected to the given `conn` has all the privileges
  required to work with this `Kompo`.
  """
  @spec check_privileges(conn :: Postgrex.conn()) :: :ok | {:error, binary()}
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

  @doc """
  Disconnects the connection with the given `id` by stopping the referenced
  `Postgrex` process.
  """
  @spec disconnect(id()) :: :ok
  def disconnect(id) do
    case lookup(id) do
      [{conn, _}] ->
        Process.exit(conn, :normal)
        :ok

      [] ->
        :ok
    end
  end
end
