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
            anyOf:
              - required: ["instanceRef"]
              - required: ["clusterInstanceRef"]
            properties:
              usingPrefixNamingStrategy:
                type: boolean
              instanceRef:
                type: object
                properties:
                  name:
                    type: string
              clusterInstanceRef:
                type: object
                properties:
                  name:
                    type: string
              params:
                description: "Parameters passed to CREATE TEMPLATE."
                type: object
                properties:
                  template:
                    description: "(Optional) The name of the template from which to create the new database."
                    type: string
                  encoding:
                    description: "(Optional) Character set encoding to use in the new database. Specify a string constant (e.g., 'SQL_ASCII'), or an integer encoding number."
                    x-kubernetes-int-or-string: true
                    anyOf:
                      - type: integer
                      - type: string
                  locale:
                    description: "(Optional) This is a shortcut for setting lc_collate and lc_type at once."
                    type: string
                  lc_collate:
                    description: "(Optional) Collation order (LC_COLLATE) to use in the new database."
                    type: string
                  lc_ctype:
                    description: "(Optional) Character classification (LC_CTYPE) to use in the new database."
                    type: string
                  connection_limit:
                    description: "(Optional) How many concurrent connections can be made to this database. -1 (the default) means no limit."
                    type: integer
                  is_template:
                    description: "(Optional) If true, then this database can be cloned by any user with CREATEDB privileges; if false (the default), then only superusers or the owner of the database can clone it."
                    type: boolean
          :status:
            :type: :object
            :properties:
              sql_db_name:
                type: string
              users:
                type: array
                items:
                  type: object
                  properties:
                    username:
                      type: string
                    secret:
                      type: string
      """a,
      additionalPrinterColumns: [
        %{
          name: "Postgres DB name",
          type: "string",
          description: "Name of the database on the Postgres instance",
          jsonPath: ".status.sql_db_name"
        }
      ]
    )
    |> add_observed_generation_status()
    |> add_conditions()
  end
end
