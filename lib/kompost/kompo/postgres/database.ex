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
end
