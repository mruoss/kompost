defmodule Kompost.Kompo.Postgres.Operator do
  @moduledoc """
  This operator handles resources regarding postgres instances and databases.
  """

  use Bonny.Operator, default_watch_namespace: :all

  alias Kompost.Kompo.Postgres.Controller
  alias Kompost.Kompo.Postgres.V1Alpha1

  step(Bonny.Pluggable.Logger, level: :info)
  step(:delegate_to_controller)
  step(Bonny.Pluggable.ApplyStatus)
  step(Bonny.Pluggable.ApplyDescendants)

  @impl Bonny.Operator
  def controllers(watching_namespace, _opts) do
    [
      %{
        query:
          K8s.Client.watch("kompost.chuge.li/v1alpha1", "PostgresInstance",
            namespace: watching_namespace
          ),
        controller: Controller.InstanceController
      },
      %{
        query:
          K8s.Client.watch("kompost.chuge.li/v1alpha1", "PostgresDatabase",
            namespace: watching_namespace
          ),
        controller: Controller.DatabaseController
      }
    ]
  end

  @impl Bonny.Operator
  def crds() do
    [
      %Bonny.API.CRD{
        group: "kompost.chuge.li",
        scope: :Namespaced,
        names: Bonny.API.CRD.kind_to_names("PostgresInstance", ["pginst"]),
        versions: [V1Alpha1.PostgresInstance]
      },
      %Bonny.API.CRD{
        group: "kompost.chuge.li",
        scope: :Namespaced,
        names: Bonny.API.CRD.kind_to_names("PostgresDatabase", ["pgdb"]),
        versions: [V1Alpha1.PostgresDatabase]
      }
    ]
  end
end
