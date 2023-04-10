defmodule Kompost.Webhooks do
  alias Kompost.K8sConn

  require Logger

  def bootstrap_tls(env) do
    Application.ensure_all_started(:k8s)
    conn = K8sConn.get!(env)

    with {:certs, {:ok, ca_bundle}} <-
           {:certs,
            K8sWebhoox.ensure_certificates(conn, "kompost", "kompost", "kompost", "tls-certs")},
         {:webhook_config, :ok} <-
           {:webhook_config,
            K8sWebhoox.update_admission_webhook_configs(conn, "kompost", ca_bundle)} do
      Logger.info("TLS Bootstrap completed.")
    end
  end
end
