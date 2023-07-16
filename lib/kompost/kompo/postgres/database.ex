defmodule Kompost.Kompo.Postgres.Database do
  @moduledoc """
  Connector to operate on Postgres databases via Postgrex.
  """

  alias Kompost.Kompo.Postgres.Database.Params
  alias Kompost.Kompo.Postgres.Utils

  require Logger

  @doc """
  Creates a Postgres safe db name from a resource.

  ### Example

      iex> resource = %{"metadata" => %{"namespace" => "default", "name" => "foo-bar"}}
      ...> Kompost.Kompo.Postgres.Database.name(resource)
      "default_foo_bar"

      iex> resource = %{"metadata" => %{"namespace" => "default", "name" => "foo-bar"}}
      ...> Kompost.Kompo.Postgres.Database.name(resource, strategy: "resource_name")
      "foo_bar"
  """
  @spec name(map(), Keyword.t()) :: binary()
  def name(resource, opts \\ [])

  def name(resource, opts) do
    case Keyword.get(opts, :strategy, "prefix_namespace") do
      "resource_name" ->
        Slugger.slugify_downcase(
          "#{resource["metadata"]["name"]}",
          ?_
        )

      "prefix_namespace" ->
        Slugger.slugify_downcase(
          "#{resource["metadata"]["namespace"]}_#{resource["metadata"]["name"]}",
          ?_
        )
    end
  end

  @spec apply(db_name :: binary(), db_params :: Params.t(), Postgrex.conn()) ::
          :ok | {:error, message :: binary()}
  def apply(db_name, db_params, conn) do
    if exists?(db_name, conn), do: :ok, else: create(db_name, db_params, conn)
  end

  @spec create(db_name :: binary(), db_params :: Params.t(), Postgrex.conn()) ::
          :ok | {:error, message :: binary()}
  defp create(db_name, db_params, conn) do
    case Postgrex.query(conn, ~s(CREATE DATABASE "#{db_name}" #{Params.render(db_params)}), []) do
      {:ok, %Postgrex.Result{}} ->
        :ok

      {:error, exception} when is_exception(exception) ->
        {:error, Exception.message(exception)}
    end
  end

  @spec exists?(db_name :: binary(), Postgrex.conn()) :: boolean()
  defp exists?(db_name, conn) do
    result = Postgrex.query!(conn, ~s(SELECT 1 FROM pg_database WHERE datname='#{db_name}'), [])
    result.num_rows == 1
  end

  @spec drop(db_name :: binary(), Postgrex.conn()) :: :ok | :error
  def drop(db_name, conn) do
    with {:ok, %Postgrex.Result{}} <-
           Postgrex.query(conn, ~s(REVOKE CONNECT ON DATABASE "#{db_name}" FROM public), []),
         {:ok, %Postgrex.Result{}} <-
           Postgrex.query(
             conn,
             ~s|SELECT pid, pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '#{db_name}' AND pid <> pg_backend_pid()|,
             []
           ),
         {:ok, %Postgrex.Result{}} <- Postgrex.query(conn, ~s(DROP DATABASE "#{db_name}"), []) do
      :ok
    else
      {:error, exception} when is_exception(exception) ->
        {:error, Exception.message(exception)}
    end
  end

  @spec apply_extensions(Postgrex.conn(), extensions :: [binary()]) ::
          :ok | {:error, binary()}
  # credo:disable-for-lines:16 Credo.Check.Refactor.Nesting
  def apply_extensions(conn, extensions) do
    Postgrex.transaction(conn, fn trx_conn ->
      Enum.each(extensions, fn ext ->
        case Postgrex.query(trx_conn, ~s(CREATE EXTENSION IF NOT EXISTS "#{ext}"), []) do
          {:ok, _} ->
            :ok

          {:error, error} ->
            message = Exception.message(error)
            Logger.warning("Could not create extension: " <> message)
            DBConnection.rollback(trx_conn, message)
        end
      end)
    end)
    |> Utils.process_trx_result()
  end

  # credo:disable-for-lines:16 Credo.Check.Refactor.Nesting
  @spec drop_extensions(Postgrex.conn(), extensions :: [binary()]) ::
          :ok | {:error, binary()}
  def drop_extensions(conn, extensions) do
    Postgrex.transaction(conn, fn trx_conn ->
      Enum.each(extensions, fn ext ->
        case Postgrex.query(trx_conn, ~s(DROP EXTENSION IF EXISTS "#{ext}"), []) do
          {:ok, _} ->
            :ok

          {:error, error} ->
            message = Exception.message(error)
            Logger.warning("Could not drop extension: " <> message)
            DBConnection.rollback(trx_conn, message)
        end
      end)
    end)
    |> Utils.process_trx_result()
  end
end
