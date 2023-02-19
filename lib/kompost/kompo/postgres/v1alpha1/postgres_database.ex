defmodule Kompost.Kompo.Postgres.V1Alpha1.PostgresDatabase do
  @moduledoc """
  Postgres Database CRD v1alpha1 version.
  """

  import YamlElixir.Sigil

  use Bonny.API.Version,
    hub: true

  @impl true
  def manifest() do
    struct!(
      defaults(),
      name: "v1alpha1",
      schema: ~y"""
      :openAPIV3Schema:
        :type: object
        :required: ["spec"]
        :properties:
          :spec:
            type: object
            properties:
              instanceRef:
                type: object
                properties:
                  namespace:
                    type: string
                  name:
                    type: string
          :status:
            :type: :object
            :properties:
              sql_db_name:
                type: string
              app_user_secret:
                type: string
              inspector_user_secret:
                type: string
      """a
    )
    |> add_observed_generation_status()
    |> add_conditions()
  end
end
