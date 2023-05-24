defmodule Kompost.Kompo.Temporal.Conn do
  @moduledoc """
  Provides an interface to gRPC. `connect/2` establishes a connection with the
  gRPC server and stores the channel information in the
  `Kompost.Kompo.Temporal.ConnectionRegistry`
  """

  alias Temporal.Api.Workflowservice.V1.{
    ListNamespacesRequest,
    WorkflowService
  }

  alias Kompost.Kompo.Temporal.ConnectionRegistry

  @typedoc """
  Defines the ID for an instance. The ID is used as key when registering the
  Channel info at the `Kompost.Kompo.Temporal.ConnectionRegistry`
  """
  @type id_t :: {namespace :: binary(), name :: binary()}

  @doc """
  Checks in the `Kompost.Kompo.Temporal.ConnectionRegistry` for an existing
  connection defined by the given `id`. If no such connection exists, a new
  connection is established. The returned channel info is then registered at the
  `Kompost.Kompo.Temporal.ConnectionRegistry`.
  """
  @spec connect(id :: id_t(), addr :: String.t()) ::
          {:ok, GRPC.Channel.t()} | {:error, any()}
  def connect(id, addr) do
    with {:lookup, nil} <- {:lookup, lookup(id)},
         {:ok, channel} <- GRPC.Stub.connect(addr) do
      Agent.update(ConnectionRegistry, &Map.put(&1, id, channel))
      {:ok, channel}
    else
      {:lookup, channel} -> {:ok, channel}
      connection_error -> connection_error
    end
  end

  @doc """
  Checks in the `Kompost.Kompo.Temporal.ConnectionRegistry` for an existing
  connection defined by the given `id`. If one is found, checks if the
  connection is alive by requesting a list of namespaces.
  """
  @spec lookup(id_t()) :: GRPC.Channel.t() | nil
  def lookup(server) do
    with {:ok, channel} <- Agent.get(ConnectionRegistry, &Map.fetch(&1, server)),
         {:ok, _} <-
           WorkflowService.Stub.list_namespaces(channel, %ListNamespacesRequest{}) do
      channel
    else
      _ -> nil
    end
  end

  @doc """
  Creates an instance id tuple from a resource.

  ### Example

      iex> resource = %{"metadata" => %{"namespace" => "default", "name" => "foo-bar"}}
      ...> Kompost.Kompo.Postgres.Instance.get_id(resource)
      {"default", "foo-bar"}
  """
  @spec get_id(resource :: map()) :: id_t()
  def get_id(%{"metadata" => metadata}), do: {metadata["namespace"], metadata["name"]}
  def get_id(reference), do: {reference["namespace"], reference["name"]}

  @doc """
  Removes the channel from the `ConnectionRegistry`.
  """
  @spec disconnect(id_t()) :: :ok
  def disconnect(id), do: Agent.update(ConnectionRegistry, &Map.delete(&1, id))
end
