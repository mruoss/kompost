defmodule Kompost.Test.IntegrationHelper do
  @moduledoc false

  @spec conn!() :: K8s.Conn.t()
  def conn!() do
    {:ok, conn} =
      "TEST_KUBECONFIG"
      |> System.get_env("./integration.yaml")
      |> K8s.Conn.from_file()

    struct!(conn, insecure_skip_tls_verify: true)
  end
end
