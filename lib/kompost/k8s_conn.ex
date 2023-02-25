defmodule Kompost.K8sConn do
  @moduledoc """
  Initializes the %K8s.Conn{} struct depending on the mix environment. To be used in config.exs (bonny.exs):

  ```
  # Function to call to get a K8s.Conn object.
  # The function should return a %K8s.Conn{} struct or a {:ok, %K8s.Conn{}} tuple
  get_conn: {MichiOperator.K8sConn, :get, [config_env()]},
  ```
  """

  @spec get!(atom()) :: K8s.Conn.t()
  def get!(:dev) do
    {:ok, conn} =
      File.cwd!()
      |> Path.join("test/integration/cluster.yaml")
      |> K8s.Conn.from_file()

    struct!(conn, insecure_skip_tls_verify: true)
  end

  def get!(:test) do
    {:ok, conn} =
      "TEST_KUBECONFIG"
      |> System.get_env("./test/integration/cluster.yaml")
      |> K8s.Conn.from_file()

    struct!(conn, insecure_skip_tls_verify: true)
  end

  def get!(_) do
    {:ok, conn} = K8s.Conn.from_service_account()
    # make this configurable?
    struct!(conn, insecure_skip_tls_verify: true)
  end
end
