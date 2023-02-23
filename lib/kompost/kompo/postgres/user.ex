defmodule Kompost.Kompo.Postgres.User do
  @moduledoc """
  Connector to operate on Postgres users/roles via Postgrex.
  """

  @doc """
  Creates a user if it does not exist. The user created on the instance will be
  named `db_name`_`username` in order for the username to be unique.
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

  @doc """
  Transfers all resources owned by the given `user` to the `new_owner` and drops
  the `user` thereafter. The `new_owner` has to exist on the instance prior to
  calling this function.
  """
  @spec drop(user :: binary(), new_owner :: binary(), Postgrex.conn()) ::
          :ok | {:error, message :: binary()}
  def drop(user, new_owner, conn) do
    Postgrex.transaction(conn, fn trx_conn ->
      with {:ok, %Postgrex.Result{}} <-
             Postgrex.query(trx_conn, ~s(REASSIGN OWNED BY "#{user}" TO "#{new_owner}"), []),
           {:ok, %Postgrex.Result{}} <- Postgrex.query(trx_conn, ~s(DROP ROLE "#{user}"), []) do
        :ok
      else
        {:error, exception} when is_exception(exception) ->
          {:error, Exception.message(exception)}
      end
    end)
    |> process_trx_result()
  end

  @spec process_trx_result({:ok, :ok} | term()) :: :ok | term()
  defp process_trx_result({:ok, :ok}), do: :ok
  defp process_trx_result(error), do: error
end
