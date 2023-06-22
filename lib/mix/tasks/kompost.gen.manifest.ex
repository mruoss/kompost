defmodule Mix.Tasks.Kompost.Gen.Manifest do
  @moduledoc """
  Generates the Kubernetes YAML manifest for Kompost. For :dev and :test, this
  task also creats a local cluster using Kind if it does not already exit,
  creates the namespace and applies the resulting manifest to it.
  """

  use Mix.Task

  alias Bonny.Mix.Operator
  alias Mix.Tasks.Bonny.Gen.Manifest.KompostCustomizer

  import YamlElixir.Sigil

  @default_opts [namespace: "kompost"]
  @switches [namespace: :string, image: :string, out: :string]
  @aliases [n: :namespace, i: :image, o: :out]

  @shortdoc "Generate Kubernetes YAML manifest for this operator"

  @spec run(list()) :: :ok
  def run(args) do
    Mix.Task.run("compile")

    {opts, _, _} =
      Mix.Bonny.parse_args(args, @default_opts, switches: @switches, aliases: @aliases)

    do_run(Mix.env(), opts)
  end

  @spec do_run(atom(), Keyword.t()) :: :ok
  def do_run(env, opts) when env in [:dev, :test] do
    cluster_name = "kompost-#{env}"

    Application.ensure_all_started(:k8s)
    ensure_cluster(cluster_name)

    {:ok, conn} =
      K8s.Conn.from_file("~/.kube/config",
        context: "kind-#{cluster_name}",
        insecure_skip_tls_verify: true
      )

    ensure_namespace(conn, Keyword.fetch!(opts, :namespace))

    operations =
      generate_manifest(env, opts)
      |> Ymlr.documents!()
      |> YamlElixir.read_all_from_string!()
      |> Enum.map(&K8s.Client.apply/1)

    errors =
      conn
      |> K8s.Client.async(operations)
      |> Enum.reject(&match?({:ok, _}, &1))

    if errors == [] do
      Mix.Shell.IO.info("Manifest applied to cluster #{cluster_name}")
    else
      Mix.Shell.IO.error("Error occurred when applying manifests to cluster:")
      dbg(errors)
    end

    :ok
  end

  def do_run(:prod, opts) do
    out = Keyword.fetch!(opts, :out)

    generate_manifest(:prod, opts)
    |> Enum.map(&KompostCustomizer.override/1)
    |> Ymlr.documents!()
    |> Mix.Bonny.render(out)
  end

  @spec ensure_cluster(binary()) :: :ok
  defp ensure_cluster(cluster_name) do
    {clusters, 0} = System.cmd("kind", ~w(get clusters))

    if cluster_name not in String.split(clusters, "\n", trim: true) do
      Mix.Shell.IO.info("Creating kind cluster #{cluster_name}")
      Mix.Shell.IO.cmd("kind create cluster --name #{cluster_name}")
    end

    :ok
  end

  @spec ensure_namespace(K8s.Conn.t(), binary()) :: :ok
  defp ensure_namespace(conn, namespace) do
    {:ok, _} =
      K8s.Client.apply(~y"""
      apiVersion: v1
      kind: Namespace
      metadata:
        name: #{namespace}
      """)
      |> K8s.Client.put_conn(conn)
      |> K8s.Client.run()

    :ok
  end

  @spec generate_manifest(atom(), Keyword.t()) :: list(map())
  defp generate_manifest(:prod, opts) do
    image = Keyword.fetch!(opts, :image)
    namespace = Keyword.fetch!(opts, :namespace)

    deployment =
      Operator.deployment(image, namespace)

    [deployment | generate_manifest(:dev, opts)]
  end

  defp generate_manifest(_, opts) do
    namespace = Keyword.fetch!(opts, :namespace)
    operators = Operator.find_operators()

    Operator.crds(operators) ++
      [
        Operator.cluster_role(operators),
        Operator.service_account(namespace),
        Operator.cluster_role_binding(namespace)
      ]
  end
end
