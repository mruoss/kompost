defmodule Kompost.Kompo.Temporal.Controller.NamespaceController do
  use Bonny.ControllerV2

  require Logger

  alias Kompost.Kompo.Temporal.APIClient
  alias Kompost.Kompo.Temporal.Conn

  step Bonny.Pluggable.SkipObservedGenerations

  step Kompost.Pluggable.InitConditions, conditions: ["Connected", "Created"]

  step Bonny.Pluggable.Finalizer,
    id: "kompost.chuge.li/delete-resources",
    impl: &__MODULE__.delete_resources/1,
    add_to_resource: &__MODULE__.add_finalizer?/1,
    log_level: :debug

  step :handle_event

  @spec handle_event(Bonny.Axn.t(), Keyword.t()) :: Bonny.Axn.t()
  def handle_event(%Bonny.Axn{action: action} = axn, _opts)
      when action in [:add, :modify, :reconcile] do
    {api_server_ref, namespace_spec} = Map.pop!(axn.resource["spec"], "apiServerRef")
    id = Conn.get_id(api_server_ref)
    namespace = axn.resource["metadata"]["namespace"] <> "-" <> axn.resource["metadata"]["name"]

    with {:channel, %GRPC.Channel{} = channel} <- {:channel, Conn.lookup(id)},
         axn <-
           set_condition(
             axn,
             "Connected",
             true,
             "Connected to the referenced Temporal API Server."
           ),
         {:namespace, axn, {:ok, _namespace}} <-
           {:namespace, axn, APIClient.apply_namespace(channel, namespace, namespace_spec)} do
      axn
      |> success_event(message: "The namespace was created successfully.")
      |> set_condition(
        "Created",
        true,
        "The namespace was created successfully."
      )
    else
      {:channel, nil} ->
        message = "Could not connect to Temporal cluster: No active connection was found"
        Logger.warning("#{axn.action} failed. #{message}")

        axn
        |> failure_event(message: message)
        |> set_condition("Connected", false, message)

      {:namespace, axn, {:error, exception}} when is_exception(exception) ->
        message = Exception.message(exception)
        Logger.warning("#{axn.action} failed. #{message}")

        axn
        |> failure_event(message: message)
        |> set_condition("Created", false, message)
    end
  end

  def handle_event(%Bonny.Axn{action: :delete} = axn, _opts) do
    success_event(axn)
  end

  @doc """
  Finalizer preventing the deletion of the database resource until underlying
  resources on the postgres instance are cleaned up.
  """
  @spec delete_resources(Bonny.Axn.t()) :: {:ok, Bonny.Axn.t()} | {:error, Bonny.Axn.t()}
  def delete_resources(axn) do
    resource = axn.resource
    namespace = resource["metadata"]["namespace"] <> "-" <> resource["metadata"]["name"]
    id = Conn.get_id(resource["spec"]["apiServerRef"])

    with {:channel, %GRPC.Channel{} = channel} <- {:channel, Conn.lookup(id)},
         {:namespace, axn, {:ok, _namespace}} <-
           {:namespace, axn, APIClient.delete_namespace(channel, namespace)} do
      {:ok, axn}
    else
      {:channel, nil} ->
        message =
          "The referenced Temporal API Server was not found. We consider the resource gone."

        Logger.warning("Failed to finalize. #{message}")

        {:ok, axn}

      {:namespace, axn, {:error, exception}} when is_exception(exception) ->
        message = Exception.message(exception)
        Logger.warning("#{axn.action} failed. #{message}")

        axn
        |> failure_event(message: message)
        |> set_condition("Deleted", false, message)

        {:error, axn}
    end
  end

  @spec add_finalizer?(Bonny.Axn.t()) :: boolean()
  def add_finalizer?(%Bonny.Axn{resource: resource}) do
    conditions =
      resource
      |> get_in([Access.key("status", %{}), Access.key("conditions", [])])
      |> Map.new(&{&1["type"], &1})

    resource["metadata"]["annotations"]["kompost.chuge.li/deletion-policy"] != "abandon" and
      conditions["Connected"]["status"] == "True"
  end
end
