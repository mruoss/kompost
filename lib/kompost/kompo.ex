defmodule Kompost.Kompo do
  @moduledoc """
  Helpers around Kompos
  """

  @kompos [:postgres]

  @spec get_enabled_kompos(atom()) :: list({module(), term()})
  def get_enabled_kompos(env) when env in [:dev, :test] do
    @kompos
  end

  def get_enabled_kompos(_env) do
    config = Application.get_env(:kompost, __MODULE__, %{}) |> dbg
    Enum.filter(@kompos, &config[&1])
  end
end
