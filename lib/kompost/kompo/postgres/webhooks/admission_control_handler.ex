defmodule Kompost.Kompo.Postgres.Webhooks.AdmissionControlHandler do
  use K8sWebhoox.AdmissionControl.Handler

  import K8sWebhoox.AdmissionControl.AdmissionReview

  validate "kompost.chuge.li/v1alpha1/postgresinstances", conn do
    check_immutable(conn, ["spec", "hostname"])
    check_immutable(conn, ["spec", "port"])
  end
end
