defmodule Kompost.Kompo.Postgres.Operator do
  @moduledoc """
  This operator handles resources regarding postgres instances and databases.
  """

  use Bonny.Operator, default_watch_namespace: "default"

  alias Kompost.Kompo.Postgres.V1Alpha1
  alias Kompost.Kompo.Postgres.Controller

  step(Bonny.Pluggable.Logger, level: :info)
  step(:delegate_to_controller)
  step(Bonny.Pluggable.ApplyStatus)
  step(Bonny.Pluggable.ApplyDescendants)

  @impl Bonny.Operator
  def controllers(watching_namespace, _opts) do
    [
      %{
        query:
          K8s.Client.watch("kompost.io/v1alpha1", "PostgresInstance",
            namespace: watching_namespace
          ),
        controller: Controller.InstanceController
      }
    ]
  end

  @impl Bonny.Operator
  def crds() do
    [
      %Bonny.API.CRD{
        group: "kompost.io",
        scope: :Namespaced,
        names: Bonny.API.CRD.kind_to_names("PostgresInstance", ["pginst"]),
        versions: [V1Alpha1.PostgresInstance]
      }
    ]
  end
end
