if Mix.env() in [:dev, :test] do
  defmodule Mix.Tasks.Kompost.Gen.Periphery do
    @moduledoc """
    Generates the manifest for peripheral systems  for testing
    (Postgres, etc).
    """
    alias Kompost.Tools.Resource

    use Mix.Task

    @spec run([]) :: :ok
    def run([]) do
      Application.ensure_all_started(:k8s)
      DotenvParser.load_file("test/integration/.env")

      conn = Kompost.K8sConn.get!(Mix.env())
      gen_kompo(:postgres, conn)
      gen_kompo(:temporal, conn)

      Mix.Shell.IO.info("We're good to go, captain!")
    end

    @spec gen_kompo(atom(), K8s.Conn.t()) :: :ok
    defp gen_kompo(:postgres, conn) do
      "priv/periphery/postgres.yaml"
      |> YamlElixir.read_all_from_file!()
      |> Enum.map(&override/1)
      |> Enum.map(&K8s.Client.apply/1)
      |> then(&K8s.Client.async(conn, &1))
      |> Enum.each(fn
        {:ok, _} ->
          :ok

        {:error, error} when is_exception(error) ->
          Mix.Shell.IO.error("Error applying postgres manifest: #{Exception.message(error)}")
      end)

      Mix.Shell.IO.info("Waiting for postgres deployment to become ready")

      K8s.Client.get("apps/v1", "Deployment", name: "postgres", namespace: "postgres")
      |> Resource.wait_for_condition!(conn, "Available", 120_000)

      :ok
    end

    defp gen_kompo(:temporal, conn) do
      configmap =
        Resource.config_map!(
          "dynamicconfig",
          "temporal",
          "./priv/periphery/temporal/development-sql.yaml"
        )

      "priv/periphery/temporal.yaml"
      |> YamlElixir.read_all_from_file!()
      |> then(&[configmap | &1])
      |> Enum.map(&override/1)
      |> Enum.map(&K8s.Client.apply/1)
      |> then(&K8s.Client.async(conn, &1))
      |> Enum.each(fn
        {:ok, _} ->
          :ok

        {:error, error} when is_exception(error) ->
          Mix.Shell.IO.error("Error applying temporal manifest: #{Exception.message(error)}")
      end)

      Mix.Shell.IO.info("Waiting for postgres deployment to become ready")

      K8s.Client.get("apps/v1", "Deployment", name: "temporal", namespace: "temporal")
      |> Resource.wait_for_condition!(conn, "Available", 120_000)

      :ok
    end

    @spec override(map()) :: map()
    defp override(%{"kind" => "Deployment", "metadata" => %{"name" => "postgres"}} = resource) do
      resource
      |> put_in(
        [
          "spec",
          "template",
          "spec",
          "containers",
          Access.filter(&(&1["name"] == "postgres")),
          "env"
        ],
        [
          %{"name" => "POSTGRES_USER", "value" => System.get_env("POSTGRES_USER")},
          %{"name" => "POSTGRES_PASSWORD", "value" => System.get_env("POSTGRES_PASSWORD")},
          %{"name" => "POSTGRES_DB", "value" => System.get_env("POSTGRES_DB")}
        ]
      )
    end

    defp override(%{"kind" => "Deployment", "metadata" => %{"name" => "temporal"}} = resource) do
      resource
      |> update_in(
        [
          "spec",
          "template",
          "spec",
          "containers",
          Access.filter(&(&1["name"] == "temporal")),
          "env"
        ],
        &[
          %{"name" => "DB_PORT", "value" => System.get_env("POSTGRES_EXPOSED_PORT")},
          %{"name" => "POSTGRES_USER", "value" => System.get_env("POSTGRES_USER")},
          %{"name" => "POSTGRES_PWD", "value" => System.get_env("POSTGRES_PASSWORD")}
          | &1
        ]
      )
    end

    defp override(%{"kind" => "Service", "metadata" => %{"name" => "postgres"}} = resource) do
      port = System.get_env("POSTGRES_EXPOSED_PORT") |> String.to_integer()

      resource
      |> update_in(
        ["spec", "ports", Access.filter(&(&1["name"] == "postgres"))],
        &Map.merge(&1, %{"nodePort" => port, "port" => port})
      )
    end

    defp override(%{"kind" => "Service", "metadata" => %{"name" => "temporal"}} = resource) do
      port = System.get_env("TEMPORAL_EXPOSED_PORT") |> String.to_integer()

      resource
      |> update_in(
        ["spec", "ports", Access.filter(&(&1["name"] == "temporal"))],
        &Map.merge(&1, %{"nodePort" => port, "port" => port})
      )
    end

    defp override(resource), do: resource
  end
end
