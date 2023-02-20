defmodule Kompost.Kompo.Postgres.User do
  @moduledoc """
  Connector to operate on Postgres users/roles via Postgrex.
  """
  @spec apply(username :: binary(), Postgrex.conn(), db_name :: binary(), password :: binary()) ::
          {:ok, map()} | {:error, Exception.t()}
  def apply(username, conn, db_name, password) do
    db_username = Slugger.slugify_downcase("#{db_name}_#{username}", ?_)
    op = if exists?(db_username, conn), do: "ALTER", else: "CREATE"

    case Postgrex.query(
           conn,
           ~s(#{op} ROLE "#{db_username}" WITH PASSWORD '#{password}' NOCREATEDB NOCREATEROLE NOINHERIT LOGIN),
           []
         ) do
      {:ok, %Postgrex.Result{}} ->
        {:ok, %{DB_USER: db_username, DB_PASS: password, DB_NAME: db_name}}

      {:error, exception} when is_exception(exception) ->
        Postgrex.query(conn, ~s(DROP ROLE "#{db_username}" IF EXISTS), [])
        {:error, ~s(User "#{db_username}" could not be applied: #{Exception.message(exception)})}
    end
  end

  @spec exists?(db_username :: binary(), conn :: Postgrex.conn()) :: boolean()
  defp exists?(db_username, conn) do
    result = Postgrex.query!(conn, "SELECT 1 FROM pg_roles WHERE rolname=$1", [db_username])
    result.num_rows == 1
  end
end
