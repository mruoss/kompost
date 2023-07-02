defmodule Kompost.Tools.NamespaceAccess do
  @moduledoc """
  Module handling access to resources across namespaces.
  """

  @allowed_namespaces_annotation "kompost.chuge.li/allowed_namespaces"

  @type allowed_namespaces :: list(Regex.t())

  @spec compile_allowed_namespaces!(binary() | nil) :: allowed_namespaces()
  defp compile_allowed_namespaces!(nil), do: [~r//]

  defp compile_allowed_namespaces!(allowed_ns) do
    allowed_ns
    |> String.split([" ", ","], trim: true)
    |> Enum.map(&String.trim_leading(&1, "^"))
    |> Enum.map(&String.trim_trailing(&1, "$"))
    |> Enum.map(&~r/^#{&1}$/)
  end

  @spec allowed_namespaces_annotation(map()) :: binary() | nil
  def allowed_namespaces_annotation(resource) do
    resource["metadata"]["annotations"][@allowed_namespaces_annotation]
  end

  @doc ~S"""
  Compiles the given string of comma separated Regex patterns.

  ### Examples

      iex> nil
      ...> |> then(&(%{"metadata" => %{"annotations" => %{"kompost.chuge.li/allowed_namespaces" => &1}}}))
      ...> |> Kompost.Tools.NamespaceAccess.allowed_namespaces!()
      [~r//]

      iex> "default, prefix-[a-z]{3}, ^.*-suffix$"
      ...> |> then(&(%{"metadata" => %{"annotations" => %{"kompost.chuge.li/allowed_namespaces" => &1}}}))
      ...> |> Kompost.Tools.NamespaceAccess.allowed_namespaces!()
      [~r/^default$/, ~r/^prefix-[a-z]{3}$/, ~r/^.*-suffix$/]
  """
  @spec allowed_namespaces!(map()) :: allowed_namespaces()
  def allowed_namespaces!(resource) do
    resource
    |> allowed_namespaces_annotation()
    |> compile_allowed_namespaces!()
  end
end
