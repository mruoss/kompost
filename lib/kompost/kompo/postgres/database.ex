defmodule Kompost.Kompo.Postgres.Database do
  @moduledoc """
  Connector to operate on Postgres databases via Postgrex.
  """

  @doc """
  Creates a Postgres safe db name from a resource.

  ### Example

      iex> resource = %{"metadata" => %{"namespace" => "default", "name" => "foo-bar"}}
      ...> Kompost.Kompo.Postgres.Database.name(resource)
      "default_foo_bar"
  """
  @spec name(map()) :: binary()
  def name(resource) do
    Slugger.slugify_downcase(
      "#{resource["metadata"]["namespace"]}_#{resource["metadata"]["name"]}",
      ?_
    )
  end

  @spec apply(db_name :: binary(), Postgrex.conn()) :: :ok | {:error, message :: binary()}
  def apply(db_name, conn) do
    if exists?(db_name, conn), do: :ok, else: create(db_name, conn)
  end

  @spec create(db_name :: binary(), Postgrex.conn()) :: :ok | {:error, message :: binary()}
  defp create(db_name, conn) do
    case Postgrex.query(conn, ~s(CREATE DATABASE "#{db_name}"), []) do
      {:ok, %Postgrex.Result{}} ->
        :ok

      {:error, exception} when is_exception(exception) ->
        {:error, Exception.message(exception)}
    end
  end

  @spec exists?(db_name :: binary(), Postgrex.conn()) :: boolean()
  defp exists?(db_name, conn) do
    result = Postgrex.query!(conn, "SELECT 1 FROM pg_database WHERE datname='#{db_name}'", [])
    result.num_rows == 1
  end
end
