defmodule Kompost.Kompo.Postgres.Privileges do
  @moduledoc """
  Grants and revokes privileges to/from users via Postgrex.
  """
  require Logger

  @type access :: :read_only | :read_write

  @doc """
  Grants pre-defined access privileges for the given `database` to the `user`.
  The `access` can bei either `:read_only` or `:read_write`.

  ### Examples

      iex> Kompost.Kompo.Postgres.Privileges.grant("myuser", :read_only, "some_db", conn)
      :ok
  """
  @spec grant(user :: binary(), access :: access(), database :: binary(), Postgrex.conn()) ::
          :ok | {:error, binary()}
  def grant(username, :read_only, database, conn) do
    Postgrex.transaction(conn, fn trx_conn ->
      with :ok <- grant(username, "CONNECT ON DATABASE \"#{database}\"", trx_conn),
           :ok <- grant(username, "USAGE ON SCHEMA public ", trx_conn),
           :ok <- grant(username, "SELECT ON ALL TABLES IN SCHEMA public ", trx_conn) do
        :ok
      else
        error -> DBConnection.rollback(trx_conn, error)
      end
    end)
    |> process_trx_result()
  end

  def grant(username, :read_write, database, conn) do
    Postgrex.transaction(conn, fn trx_conn ->
      with :ok <- grant(username, "ALL PRIVILEGES ON DATABASE \"#{database}\"", trx_conn),
           :ok <- grant(username, "ALL PRIVILEGES ON SCHEMA public", trx_conn),
           :ok <- grant(username, "ALL PRIVILEGES ON ALL TABLES IN SCHEMA public ", trx_conn),
           :ok <- grant(username, "ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public ", trx_conn),
           :ok <- grant(username, "ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public ", trx_conn),
           :ok <- grant(username, "ALL PRIVILEGES ON ALL PROCEDURES IN SCHEMA public ", trx_conn),
           :ok <- grant(username, "ALL PRIVILEGES ON ALL ROUTINES IN SCHEMA public ", trx_conn) do
        :ok
      else
        error -> DBConnection.rollback(trx_conn, error)
      end
    end)
    |> process_trx_result()
  end

  @doc """
  Grants privileges or role membership to `user`. `privileges_or_group_role` can
  be either a privileges definition or an existing role.

  ### Examples

  Grant privileges:

      iex> Kompost.Kompo.Postgres.Privileges.grant("myuser", "ALL PRIVILEGES ON DATABASE \"some_db\"", conn)
      :ok

  Grant group role membership:

      iex> Kompost.Kompo.Postgres.Privileges.grant("myuser", "superuser", conn)
      :ok
  """
  @spec grant(username :: binary(), privileges_or_group_role :: binary(), Postgrex.conn()) ::
          :ok | {:error, binary()}
  def grant(username, privileges_or_group_role, conn) do
    case Postgrex.query(conn, "GRANT #{privileges_or_group_role} TO \"#{username}\"", []) do
      {:ok, %Postgrex.Result{}} ->
        :ok

      {:error, exception} when is_exception(exception) ->
        message = Exception.message(exception)

        Logger.error(
          "#{privileges_or_group_role} could not be granted to user \"#{username}\": #{message}"
        )

        {:error, message}
    end
  end

  @doc """
  Revokes pre-defined access privileges for the given `database` from the
  `user`. The `access` can bei either one of `:read_only`, `:read_write` or
  `:all`.

  ### Examples

      iex> Kompost.Kompo.Postgres.Privileges.revoke("myuser", :read_only, "some_db", conn)
      :ok
  """
  @spec revoke(
          username :: binary(),
          access :: access() | :all,
          database :: binary(),
          Postgrex.conn()
        ) ::
          :ok | {:error, binary()}
  def revoke(username, :all, database, conn) do
    Postgrex.transaction(conn, fn trx_conn ->
      with :ok <- revoke(username, "ALL PRIVILEGES ON DATABASE \"#{database}\"", trx_conn),
           :ok <- revoke(username, "ALL PRIVILEGES ON SCHEMA public ", trx_conn),
           :ok <- revoke(username, "ALL PRIVILEGES ON ALL TABLES IN SCHEMA public ", trx_conn) do
        :ok
      else
        error -> DBConnection.rollback(trx_conn, error)
      end
    end)
    |> process_trx_result()
  end

  def revoke(username, :read_only, database, conn) do
    Postgrex.transaction(conn, fn trx_conn ->
      with :ok <- revoke(username, "CONNECT ON DATABASE \"#{database}\"", trx_conn),
           :ok <- revoke(username, "USAGE ON SCHEMA public ", trx_conn),
           :ok <- revoke(username, "SELECT ON ALL TABLES IN SCHEMA public ", trx_conn) do
        :ok
      else
        error -> DBConnection.rollback(trx_conn, error)
      end
    end)
    |> process_trx_result()
  end

  def revoke(username, :read_write, database, conn) do
    Postgrex.transaction(conn, fn trx_conn ->
      with :ok <- revoke(username, "CONNECT ON DATABASE \"#{database}\"", trx_conn),
           :ok <- revoke(username, "ALL PRIVILEGES ON SCHEMA public", trx_conn),
           :ok <- revoke(username, "ALL PRIVILEGES ON ALL TABLES IN SCHEMA public ", trx_conn),
           :ok <- revoke(username, "ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public ", trx_conn),
           :ok <- revoke(username, "ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public ", trx_conn),
           :ok <-
             revoke(username, "ALL PRIVILEGES ON ALL PROCEDURES IN SCHEMA public ", trx_conn),
           :ok <- revoke(username, "ALL PRIVILEGES ON ALL ROUTINES IN SCHEMA public ", trx_conn) do
        :ok
      else
        error -> DBConnection.rollback(trx_conn, error)
      end
    end)
    |> process_trx_result()
  end

  @doc """
  Revokes privileges or role membership from `user`. `privileges_or_group_role`
  can be either a privileges definition or an existing role.

  ### Examples

  Revoke privileges:

      iex> Kompost.Kompo.Postgres.Privileges.revoke("myuser", "CONNECT ON DATABASE \"some_db\"", conn)
      :ok

  Revoke group role membership:

      iex> Kompost.Kompo.Postgres.Privileges.revoke("myuser", "superuser", conn)
      :ok
  """
  @spec revoke(username :: binary(), privileges_or_group_role :: binary(), Postgrex.conn()) ::
          :ok | {:error, binary}
  def revoke(username, privileges_or_group_role, conn) do
    case Postgrex.query(conn, "REVOKE #{privileges_or_group_role} FROM \"#{username}\"", []) do
      {:ok, %Postgrex.Result{}} ->
        :ok

      {:error, exception} when is_exception(exception) ->
        message = Exception.message(exception)

        Logger.error(
          "#{privileges_or_group_role} could not be revoked from user \"#{username}\": #{message}"
        )

        {:error, message}
    end
  end

  @spec process_trx_result({:ok, :ok} | term()) :: :ok | term()
  defp process_trx_result({:ok, :ok}), do: :ok
  defp process_trx_result(error), do: error
end
