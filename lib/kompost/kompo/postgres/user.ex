defmodule Kompost.Kompo.Postgres.User do
  @moduledoc """
  Connector to operate on Postgres users/roles via Postgrex.
  """
  @type user_type :: :app | :inspector

  @spec apply(Postgrex.conn(), db_name :: binary(), type :: user_type(), password :: binary()) ::
          {:ok, map()} | {:error, Exception.t()}
  def apply(conn, db_name, type, password) do
    username = username(db_name, type)
    op = if exists?(username, conn), do: "ALTER", else: "CREATE"

    case Postgrex.query(
           conn,
           ~s(#{op} ROLE "#{username}" WITH PASSWORD '#{password}' NOCREATEDB NOCREATEROLE NOINHERIT LOGIN),
           []
         ) do
      {:ok, %Postgrex.Result{}} ->
        {:ok, %{DB_USER: username, DB_PASS: password}}

      {:error, exception} when is_exception(exception) ->
        Postgrex.query(conn, ~s(DROP ROLE "#{username}" IF EXISTS), [])
        {:error, ~s(User "#{username}" could not be applied: #{Exception.message(exception)})}
    end
  end

  @spec username(db_name :: binary(), type :: user_type()) :: binary()
  defp username(db_name, type) do
    Slugger.slugify_downcase("#{db_name}_#{type}", ?_)
  end

  @spec exists?(username :: binary(), conn :: Postgrex.conn()) :: boolean()
  defp exists?(username, conn) do
    result = Postgrex.query!(conn, "SELECT 1 FROM pg_roles WHERE rolname=$1", [username])
    result.num_rows == 1
  end
end
