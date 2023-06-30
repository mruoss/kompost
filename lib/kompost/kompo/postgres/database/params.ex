defmodule Kompost.Kompo.Postgres.Database.Params do
  @moduledoc """
  Database creation parameters.
  See PostgreSQL documentation: https://www.postgresql.org/docs/current/sql-createdatabase.html
  """

  defstruct [
    :template,
    :encoding,
    :locale,
    :lc_collate,
    :lc_ctype,
    :connection_limit,
    :is_template
  ]

  @type t :: %__MODULE__{
          template: binary(),
          encoding: binary(),
          locale: binary() | integer(),
          lc_collate: binary(),
          lc_ctype: binary(),
          connection_limit: non_neg_integer(),
          is_template: boolean()
        }

  @spec new!(map()) :: t()
  def new!(params) do
    params
    |> Map.new(fn {key, value} -> {String.to_existing_atom(key), value} end)
    |> then(&struct(__MODULE__, &1))
  end

  @spec render(t()) :: iodata()
  def render(params) do
    params
    |> Map.from_struct()
    |> Enum.reject(&is_nil(elem(&1, 1)))
    |> Enum.map(fn {key, value} -> render_param(key, value) end)
  end

  @spec render_param(atom(), term()) :: iodata()
  defp render_param(:template, value), do: [" TEMPLATE '", value, "'"]
  defp render_param(:encoding, value), do: [" ENCODING '", value, "'"]
  defp render_param(:locale, value) when is_binary(value), do: [" LOCALE '", value, "'"]

  defp render_param(:locale, value) when is_integer(value),
    do: [" LOCALE ", Integer.to_string(value)]

  defp render_param(:lc_collate, value), do: [" LC_COLLATE '", value, "'"]
  defp render_param(:lc_ctype, value), do: [" LC_CTYPE '", value, "'"]

  defp render_param(:connection_limit, value),
    do: [" CONNECTION LIMIT ", Integer.to_string(value)]

  defp render_param(:is_template, true), do: [" IS_TEMPLATE TRUE"]
  defp render_param(:is_template, false), do: [" IS_TEMPLATE FALSE"]
end
