defmodule Kompost.K8sConn do
  @moduledoc """
  Initializes the %K8s.Conn{} struct depending on the mix environment. To be used in config.exs (bonny.exs):

  ```
  # Function to call to get a K8s.Conn object.
  # The function should return a %K8s.Conn{} struct or a {:ok, %K8s.Conn{}} tuple
  get_conn: {MichiOperator.K8sConn, :get, [config_env()]},
  ```
  """

  @spec get!(env :: atom()) :: K8s.Conn.t()
  def get!(:dev) do
    {:ok, conn} =
      "KUBECONFIG"
      |> System.get_env("./test/integration/kubeconfig-dev.yaml")
      |> K8s.Conn.from_file(insecure_skip_tls_verify: true)

    conn
  end

  def get!(:test) do
    {:ok, conn} =
      "KUBECONFIG"
      |> System.get_env("./test/integration/kubeconfig-test.yaml")
      |> K8s.Conn.from_file(insecure_skip_tls_verify: true)

    conn
  end

  def get!(_) do
    kubeconfig = System.get_env("KUBECONFIG")

    {:ok, conn} =
      if not is_nil(kubeconfig) and File.exists?(kubeconfig) do
        K8s.Conn.from_file(kubeconfig, insecure_skip_tls_verify: true)
      else
        K8s.Conn.from_service_account(insecure_skip_tls_verify: true)
      end

    conn
  end
end
