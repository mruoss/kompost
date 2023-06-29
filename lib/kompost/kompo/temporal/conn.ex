defmodule Kompost.Kompo.Temporal.Conn do
  @moduledoc """
  Provides an interface to gRPC. `connect/2` establishes a connection with the
  gRPC server and stores the channel information in the
  `Kompost.Kompo.Temporal.ConnectionRegistry`
  """

  require Logger

  alias Temporal.Api.Workflowservice.V1.{
    ListNamespacesRequest,
    WorkflowService
  }

  alias Kompost.Kompo.Temporal.ConnectionRegistry

  @typedoc """
  Defines the ID for an instance. The ID is used as key when registering the
  Channel info at the `Kompost.Kompo.Temporal.ConnectionRegistry`
  """
  @type server_t :: {namespace :: binary(), name :: binary()}

  @doc """
  Checks in the `Kompost.Kompo.Temporal.ConnectionRegistry` for an existing
  connection defined by the given `id`. If no such connection exists, a new
  connection is established. The returned channel info is then registered at the
  `Kompost.Kompo.Temporal.ConnectionRegistry`.
  """
  @spec connect(server :: server_t(), addr :: String.t()) ::
          {:ok, GRPC.Channel.t()} | {:error, any()}
  def connect(server, addr) do
    with {:lookup, nil} <- {:lookup, lookup(server)},
         {:ok, channel} <- GRPC.Stub.connect(addr, adapter: GRPC.Client.Adapters.Mint),
         :ok <- verify_connection(server, channel) do
      Agent.update(ConnectionRegistry, &Map.put(&1, server, channel))
      {:ok, channel}
    else
      {:lookup, channel} -> {:ok, channel}
      :error -> {:error, "Connection failed."}
      connection_error -> connection_error
    end
  end

  @spec verify_connection(server :: server_t(), channel :: GRPC.Channel.t()) :: :ok | :error
  defp verify_connection(server, channel) do
    case WorkflowService.Stub.list_namespaces(channel, %ListNamespacesRequest{}) do
      {:ok, _} ->
        :ok

      {:error, %GRPC.RPCError{} = error} ->
        Logger.warning(
          "Temporal connection #{inspect(server)} was found but connection failed: #{Exception.message(error)}"
        )

        Agent.update(ConnectionRegistry, &Map.delete(&1, server))
        :error

      {:error, error} ->
        Logger.warning(
          "Temporal connection #{inspect(server)} was found but connection failed: #{inspect(error)}"
        )

        Agent.update(ConnectionRegistry, &Map.delete(&1, server))
        :error

      :error ->
        Logger.warning("Temporal connection #{inspect(server)} was not found.")
        :error
    end
  end

  @doc """
  Checks in the `Kompost.Kompo.Temporal.ConnectionRegistry` for an existing
  connection defined by the given `id`. If one is found, checks if the
  connection is alive by requesting a list of namespaces.
  """
  @spec lookup(server_t()) :: GRPC.Channel.t() | nil
  def lookup(server) do
    with {:find, {:ok, channel}} <-
           {:find, Agent.get(ConnectionRegistry, &Map.fetch(&1, server))},
         {:verify, :ok} <- {:verify, verify_connection(server, channel)} do
      channel
    else
      {:find, :error} ->
        Logger.warning("Temporal connection #{inspect(server)} was not found.")
        nil

      _ ->
        nil
    end
  end

  @doc """
  Creates an instance id tuple from a resource.

  ### Example

      iex> resource = %{"metadata" => %{"namespace" => "default", "name" => "foo-bar"}}
      ...> Kompost.Kompo.Postgres.Instance.get_id(resource)
      {"default", "foo-bar"}
  """
  @spec get_id(resource :: map()) :: server_t()
  def get_id(%{"metadata" => metadata}), do: {metadata["namespace"], metadata["name"]}
  def get_id(reference), do: {reference["namespace"], reference["name"]}

  @doc """
  Removes the channel from the `ConnectionRegistry`.
  """
  @spec disconnect(server_t()) :: :ok
  def disconnect(server) do
    case Agent.get_and_update(ConnectionRegistry, &Map.pop(&1, server)) do
      nil ->
        :ok

      channel ->
        GRPC.Stub.disconnect(channel)
        :ok
    end
  end
end
