defmodule Kompost.Tools.Resource do
  @moduledoc """
  Helper functions to work with Kubernetes Resources
  """
  @spec k8s_apply!(map, K8s.Conn.t()) :: map()
  def k8s_apply!(resource, conn) do
    {:ok, applied_resource} = k8s_apply(resource, conn)

    applied_resource
  end

  @spec k8s_apply(map, K8s.Conn.t()) :: {:ok, map()} | {:error, any}
  def k8s_apply(resource, conn) do
    resource
    |> K8s.Client.apply()
    |> K8s.Client.put_conn(conn)
    |> K8s.Client.run()
  end

  @spec delete!(map, K8s.Conn.t()) :: {:ok, map()}
  def delete!(resource, conn) do
    {:ok, _} =
      resource
      |> K8s.Client.delete()
      |> K8s.Client.put_conn(conn)
      |> K8s.Client.run()
  end

  @spec wait_until_observed!(map, K8s.Conn.t(), non_neg_integer()) :: map
  def wait_until_observed!(resource, conn, timeout) do
    wait_until!(
      resource,
      conn,
      ["status", "observedGeneration"],
      resource["metadata"]["generation"],
      timeout
    )
  end

  @spec wait_for_condition!(map, K8s.Conn.t(), binary(), binary(), non_neg_integer()) :: map
  def wait_for_condition!(resource, conn, condition, status \\ "True", timeout) do
    wait_until!(
      resource,
      conn,
      &find_condition_status(&1, condition),
      status,
      timeout
    )
  end

  @spec wait_until!(
          resource :: map(),
          K8s.Conn.t(),
          find :: list | function(),
          term,
          non_neg_integer()
        ) :: map
  def wait_until!(%K8s.Operation{} = op, conn, find, eval, timeout) do
    {:ok, resource} =
      op
      |> K8s.Client.put_conn(conn)
      |> K8s.Client.wait_until(
        find: find,
        eval: eval,
        timeout: timeout
      )

    resource
  end

  def wait_until!(resource, conn, find, eval, timeout) do
    get_op =
      resource
      |> K8s.Client.get()
      |> K8s.Client.put_conn(conn)

    wait_until!(get_op, conn, find, eval, timeout)
  end

  @spec find_condition_status(map(), binary()) :: binary()
  defp find_condition_status(resource, condition) do
    get_in(resource, [
      "status",
      "conditions",
      Access.filter(&(&1["type"] == condition)),
      "status"
    ])
    |> List.wrap()
    |> List.first()
  end

  @spec config_map!(
          name :: binary(),
          namespace :: binary(),
          files :: binary() | list(binary())
        ) :: map()
  def config_map!(name, namespace, files) do
    data =
      files
      |> List.wrap()
      |> Map.new(fn file_path ->
        filename = Path.basename(file_path)
        content = File.read!(file_path)
        {filename, content}
      end)

    %{
      "apiVersion" => "v1",
      "kind" => "ConfigMap",
      "metadata" => %{"namespace" => namespace, "name" => name},
      "data" => data
    }
  end
end
