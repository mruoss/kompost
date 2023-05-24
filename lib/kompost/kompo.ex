defmodule Kompost.Kompo do
  @moduledoc """
  Helpers around Kompos
  """

  @dev_kompos [:postgres, :temporal]

  @spec get_enabled_kompos(atom()) :: list({module(), term()})
  def get_enabled_kompos(env) when env in [:dev, :test] do
    @dev_kompos
  end

  def get_enabled_kompos(_env) do
    config = Application.get_env(:kompost, __MODULE__, %{})
    Enum.filter(@dev_kompos, &config[&1])
  end
end
