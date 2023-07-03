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
  end

  validate "kompost.chuge.li/v1alpha1/postgresclusterinstances", conn do
    try do
      NamespaceAccess.allowed_namespaces!(conn.request["object"])

      conn
      |> check_allowed_values(~w(spec ssl verify), ~w(verify_none verify_peer), ".spec.verify")
    catch
      %Regex.CompileError{} = error ->
        deny(
          conn,
          ~s(Invalid regular expression in the annotation "kompost.chuge.li/allowed_namespaces": #{Exception.message(error)})
        )
    end
  end

  validate "kompost.chuge.li/v1alpha1/postgresinstances", conn do
    try do
      NamespaceAccess.allowed_namespaces!(conn.request["object"])
      conn
    catch
      %Regex.CompileError{} = error ->
        deny(
          conn,
          ~s(Invalid regular expression in the annotation "kompost.chuge.li/allowed_namespaces": #{Exception.message(error)})
        )
    end
  end
end
