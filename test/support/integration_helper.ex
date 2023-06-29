defmodule Kompost.Test.IntegrationHelper do
  @moduledoc false

  @spec conn!() :: K8s.Conn.t()
  def conn!(), do: Kompost.K8sConn.get!(:test)
end
