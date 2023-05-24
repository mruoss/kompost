defmodule Kompost.Kompo.Temporal.APIClient do
  @moduledoc """
  Connector to Tepmoral's `WorkflowService`. Uses the gRPC API
  to apply resources on the Temporal cluster.
  """

  alias Temporal.Api.Operatorservice.V1.DeleteNamespaceResponse

  alias Temporal.Api.Workflowservice.V1.{
    ListNamespacesRequest,
    RegisterNamespaceRequest,
    RegisterNamespaceResponse,
    UpdateNamespaceRequest,
    UpdateNamespaceResponse,
    WorkflowService
  }

  alias Temporal.Api.Namespace.V1.{
    NamespaceConfig,
    NamespaceInfo
  }

  alias Temporal.Api.Operatorservice.V1.{
    DeleteNamespaceRequest,
    DeleteNamespaceResponse,
    OperatorService
  }

  alias Google.Protobuf.Duration

  @list_ns_req %ListNamespacesRequest{}

  @doc """
  Applies a namespace.
  """

  @spec apply_namespace(GRPC.Channel.t(), name :: String.t(), spec :: map()) ::
          {:ok, response :: UpdateNamespaceResponse.t() | RegisterNamespaceResponse.t()}
          | {:error, GRPC.RPCError.t()}
  def apply_namespace(channel, name, spec) do
    with {:list, {:ok, list_ns_resp}} <-
           {:list, WorkflowService.Stub.list_namespaces(channel, @list_ns_req)},
         {:ns, namespace} when not is_nil(namespace) <-
           {:ns, Enum.find(list_ns_resp.namespaces, &(&1.namespace_info.name == name))} do
      update_namespace(channel, name, spec)
    else
      {:list, {:error, error}} -> {:error, error}
      {:ns, nil} -> register_namespace(channel, name, spec)
    end
  end

  @spec register_namespace(GRPC.Channel.t(), String.t(), map()) ::
          {:ok, response :: RegisterNamespaceResponse.t()} | {:error, GRPC.RPCError.t()}
  def register_namespace(channel, name, spec) do
    request = %RegisterNamespaceRequest{
      namespace: name,
      description: spec["description"],
      owner_email: spec["ownerEmail"],
      workflow_execution_retention_period: %Duration{
        seconds: spec["workflowExecutionRetentionPeriod"]
      }
    }

    WorkflowService.Stub.register_namespace(channel, request)
  end

  @spec update_namespace(GRPC.Channel.t(), String.t(), map()) ::
          {:ok, response :: UpdateNamespaceResponse.t()} | {:error, GRPC.RPCError.t()}
  def update_namespace(channel, name, spec) do
    request = %UpdateNamespaceRequest{
      namespace: name,
      update_info: %NamespaceInfo{
        description: spec["description"],
        owner_email: spec["ownerEmail"]
      },
      config: %NamespaceConfig{
        workflow_execution_retention_ttl: %Duration{
          seconds: spec["workflowExecutionRetentionPeriod"]
        }
      }
    }

    WorkflowService.Stub.update_namespace(channel, request)
  end

  @spec delete_namespace(GRPC.Channel.t(), String.t()) ::
          {:ok, response :: DeleteNamespaceResponse.t()} | {:error, GRPC.RPCError.t()}
  def delete_namespace(channel, name) do
    request = %DeleteNamespaceRequest{namespace: name}
    OperatorService.Stub.delete_namespace(channel, request)
  end
end
