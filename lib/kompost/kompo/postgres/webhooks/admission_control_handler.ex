defmodule Kompost.Kompo.Postgres.Webhooks.AdmissionControlHandler do
  @moduledoc """
  Admission Webhook Handler for Postgres Kompo
  """

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
end
