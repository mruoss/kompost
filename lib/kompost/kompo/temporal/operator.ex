defmodule Kompost.Kompo.Temporal.Operator do
  @moduledoc """
  This operator handles resources in temproal servers
  """

  use Bonny.Operator, default_watch_namespace: :all

  alias Kompost.Kompo.Temporal.Controller
  alias Kompost.Kompo.Temporal.V1Alpha1

  step(Bonny.Pluggable.Logger, level: :info)
  step(:delegate_to_controller)
  step(Bonny.Pluggable.ApplyStatus)
  step(Bonny.Pluggable.ApplyDescendants)

  @impl Bonny.Operator
  def controllers(watching_namespace, _opts) do
    [
      %{
        query:
          K8s.Client.watch("kompost.chuge.li/v1alpha1", "TemporalApiServer",
            namespace: watching_namespace
          ),
        controller: Controller.APIServerController
      },
      %{
        query:
          K8s.Client.watch("kompost.chuge.li/v1alpha1", "TemporalNamespace",
            namespace: watching_namespace
          ),
        controller: Controller.NamespaceController
      }
    ]
  end

  @impl Bonny.Operator
  def crds() do
    [
      %Bonny.API.CRD{
        group: "kompost.chuge.li",
        scope: :Namespaced,
        names: Bonny.API.CRD.kind_to_names("TemporalApiServer", ["tmprlas"]),
        versions: [V1Alpha1.TemporalApiServer]
      },
      %Bonny.API.CRD{
        group: "kompost.chuge.li",
        scope: :Namespaced,
        names: Bonny.API.CRD.kind_to_names("TemporalNamespace", ["tmprlns"]),
        versions: [V1Alpha1.TemporalNamespace]
      }
    ]
  end
end
