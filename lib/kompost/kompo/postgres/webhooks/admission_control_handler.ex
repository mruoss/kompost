defmodule Kompost.Kompo.Postgres.Webhooks.AdmissionControlHandler do
  @moduledoc """
  Admission Webhook Handler for Postgres Kompo
  """
  alias Kompost.Tools.NamespaceAccess

  use K8sWebhoox.AdmissionControl.Handler

  import K8sWebhoox.AdmissionControl.AdmissionReview

  validate "kompost.chuge.li/v1alpha1/postgresdatabases", conn do
    conn
    |> check_immutable(["spec", "params", "template"])
    |> check_immutable(["spec", "params", "encoding"])
    |> check_immutable(["spec", "params", "locale"])
    |> check_immutable(["spec", "params", "lc_collate"])
    |> check_immutable(["spec", "params", "lc_ctype"])
    |> check_immutable(["spec", "params", "connection_limit"])
    |> check_immutable(["spec", "params", "is_template"])
    |> check_immutable(["spec", "databaseNamingStrategy"])
  end

  validate "kompost.chuge.li/v1alpha1/postgresclusterinstances", conn do
    try do
      NamespaceAccess.allowed_namespaces!(conn.request["object"])

      conn
      |> check_allowed_values(
        ~w(spec ssl verify),
        ~w(verify_none verify_peer),
        ".spec.ssl.verify"
      )
      |> check_certificate()
    catch
      %Regex.CompileError{} = error ->
        deny(
          conn,
          ~s(Invalid regular expression in the annotation "kompost.chuge.li/allowed-namespaces": #{Exception.message(error)})
        )
    end
  end

  validate "kompost.chuge.li/v1alpha1/postgresinstances", conn do
    try do
      NamespaceAccess.allowed_namespaces!(conn.request["object"])

      conn
      |> check_allowed_values(~w(spec ssl verify), ~w(verify_none verify_peer), ".spec.verify")
      |> check_certificate()
    catch
      %Regex.CompileError{} = error ->
        deny(
          conn,
          ~s(Invalid regular expression in the annotation "kompost.chuge.li/allowed-namespaces": #{Exception.message(error)})
        )
    end
  end

  @spec check_certificate(K8sWebhoox.Conn.t()) :: K8sWebhoox.Conn.t()
  defp check_certificate(conn) do
    case conn.request["object"]["spec"]["ssl"]["ca"] do
      nil ->
        conn

      cacert ->
        cacert
        |> :public_key.pem_decode()
        |> Enum.map(fn {_, der, _} -> der end)
        |> then(fn
          [] -> deny(conn, "The CA certificate you passed in .spec.ssl.ca cannot be parsed.")
          _ -> conn
        end)
    end
  end
end
