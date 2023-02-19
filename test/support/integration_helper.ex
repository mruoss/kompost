defmodule Kompost.Test.IntegrationHelper do
  @moduledoc false

  @spec conn!() :: K8s.Conn.t()
  def conn!() do
    {:ok, conn} =
      File.cwd!()
      |> Path.join("integration.yaml")
      |> K8s.Conn.from_file()

    struct!(conn, insecure_skip_tls_verify: true)
  end
end
