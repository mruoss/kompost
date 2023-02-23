defmodule Kompost.Pluggable.InitConditions do
  @moduledoc """
  Initializes all conditions passed to `init/1` with a status of "False".
  """

  @behaviour Pluggable

  @impl true
  def init(opts), do: Keyword.fetch!(opts, :conditions)

  @impl true
  def call(%Bonny.Axn{action: :add} = axn, conditions) do
    Enum.reduce(conditions, axn, &Bonny.Axn.set_condition(&2, &1, false))
  end

  def call(axn, _), do: axn
end
