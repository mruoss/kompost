defmodule Kompost.Kompo.Postgres.Utils do
  @moduledoc """
  Utility functions for the Postgrex Kompo
  """

  @spec process_trx_result({:ok, :ok} | term()) :: :ok | term()
  def process_trx_result({:ok, :ok}), do: :ok
  def process_trx_result({:error, error}), do: error
end
