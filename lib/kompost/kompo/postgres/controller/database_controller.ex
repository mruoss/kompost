defmodule Kompost.Kompo.Postgres.Controller.DatabaseController do
  use Bonny.ControllerV2

  require Logger

  alias Kompost.Kompo.Postgres.Database
  alias Kompost.Kompo.Postgres.Database.Params
  alias Kompost.Kompo.Postgres.Instance
  alias Kompost.Kompo.Postgres.Privileges
  alias Kompost.Kompo.Postgres.User

  alias Kompost.Tools.NamespaceAccess
  alias Kompost.Tools.Password

  import YamlElixir.Sigil

  step Bonny.Pluggable.SkipObservedGenerations

  step Kompost.Pluggable.InitConditions, conditions: ["Connection", "AppUser", "InspectorUser"]

  step Bonny.Pluggable.Finalizer,
    id: "kompost.chuge.li/delete-resources",
    impl: &__MODULE__.delete_resources/1,
    add_to_resource: &__MODULE__.add_finalizer?/1,
    log_level: :debug

  step :handle_event

  @impl true
  def rbac_rules() do
    [to_rbac_rule({"", "secrets", ["*"]})]
  end

  @spec handle_event(Bonny.Axn.t(), Keyword.t()) :: Bonny.Axn.t()
  def handle_event(%Bonny.Axn{action: action} = axn, _opts)
      when action in [:add, :modify, :reconcile] do
    resource = axn.resource
    namespace = resource["metadata"]["namespace"]

    db_name =
      Database.name(resource,
        strategy: resource["spec"]["databaseNamingStrategy"] || "prefix_namespace"
      )

    db_params = Params.new!(resource["spec"]["params"] || %{})
    instance = resource |> instance_id() |> Instance.lookup()

    with {:instance, [{conn, conn_args, allowed_namespaces}]} <- {:instance, instance},
         axn <-
           set_condition(
             axn,
             "Connection",
             true,
             "Connected to the referenced PostgreSQL instance."
           ),
         {:can_access, axn, true} <-
           {:can_access, axn, NamespaceAccess.can_access?(namespace, allowed_namespaces)},
         {:database, axn, :ok} <- {:database, axn, Database.apply(db_name, db_params, conn)},
         axn <-
           set_condition(
             axn,
             "Database",
             true,
             ~s(The database "#{db_name}" was created on the PostgreSQL instance)
           ),
         axn <- Bonny.Axn.update_status(axn, &Map.put(&1, "sql_db_name", db_name)),
         {:app_user, {:ok, axn}} <-
           {:app_user, apply_user("app", :read_write, axn, conn, conn_args, db_name)},
         axn <-
           set_condition(
             axn,
             "AppUser",
             true,
             "Application user was created successfully."
           ),
         {:inspector_user, {:ok, axn}} <-
           {:inspector_user, apply_user("inspector", :read_only, axn, conn, conn_args, db_name)},
         axn <-
           set_condition(
             axn,
             "InspectorUser",
             true,
             "Inspector user was created successfully."
           ) do
      success_event(axn)
    else
      {:instance, []} ->
        message = "The referenced PostgreSQL instance was not found."
        Logger.warning("#{axn.action} failed. #{message}")

        axn
        |> failure_event(message: message)
        |> set_condition("Connection", false, message)

      {:database, axn, {:error, message}} ->
        Logger.warning("#{axn.action} failed. #{message}")

        axn
        |> failure_event(message: message)
        |> set_condition("Database", false, message)

      {:can_access, axn, false} ->
        message =
          ~s(The referenced PostgresClusterInstance cannot be accesed. Check the annotation "kompost.chuge.li/allowed-namespaces" on the PostgresClusterInstance.)

        Logger.warning("#{axn.action} failed. #{message}")

        axn
        |> failure_event(message: message)
        |> set_condition("ClusterInstanceAccess", false, message)

      {:app_user, {:error, axn, message}} ->
        Logger.warning("#{axn.action} failed. #{message}")

        axn
        |> failure_event(message: message)
        |> set_condition("AppUser", false, message)

      {:inspector_user, {:error, axn, message}} ->
        Logger.warning("#{axn.action} failed. #{message}")

        axn
        |> failure_event(message: message)
        |> set_condition("InspectorUser", false, message)
    end
  end

  # See `delete_resources/1`
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

    db_name =
      Database.name(resource,
        strategy: resource["spec"]["databaseNamingStrategy"] || "prefix_namespace"
      )

    users = resource["status"]["users"]
    instance = resource |> instance_id() |> Instance.lookup()

    with {:instance, [{conn, _conn_args, _allowed_namespaces}]} <- {:instance, instance},
         {:users, axn, :ok} <- {:users, axn, drop_users(users, db_name, conn)},
         {:database, axn, :ok} <- {:database, axn, Database.drop(db_name, conn)} do
      {:ok, axn}
    else
      {:instance, []} ->
        Logger.warning(
          "The referenced PostgreSQL instance was not found. But we consider the Database removed."
        )

        {:ok, axn}

      {:users, axn, {:error, message}} ->
        Logger.warning("Failed to finalize. #{message}")
        failure_event(axn, message: message)
        {:error, axn}

      {:database, axn, {:error, message}} ->
        Logger.warning("Failed to finalize. #{message}")
        failure_event(axn, message: message)
        {:error, axn}
    end
  end

  @spec apply_user_secret(
          axn :: Bonny.Axn.t(),
          secret_name :: binary(),
          user_env :: map(),
          conn_args :: Keyword.t()
        ) :: {:ok, Bonny.Axn.t()}
  defp apply_user_secret(axn, secret_name, user_env, conn_args) do
    data =
      Map.merge(user_env, %{
        DB_HOST: Keyword.fetch!(conn_args, :hostname),
        DB_PORT: "#{Keyword.fetch!(conn_args, :port)}",
        DB_SSL: "#{conn_args[:ssl]}",
        DB_SSL_VERIFY: "#{conn_args[:ssl_opts][:verify] == :verify_peer}"
      })

    user_secret =
      ~y"""
      apiVersion: v1
      kind: Secret
      metadata:
          namespace: #{K8s.Resource.FieldAccessors.namespace(axn.resource)}
          name: #{secret_name}
      """
      |> Map.put("stringData", data)

    username = user_env[:DB_USER]
    status_entry = %{"username" => username, "secret" => secret_name}

    axn =
      axn
      |> Bonny.Axn.register_descendant(user_secret)
      |> Bonny.Axn.update_status(fn status ->
        Map.update(status, "users", [status_entry], &Enum.uniq([status_entry | &1]))
      end)

    {:ok, axn}
  end

  @spec apply_user(
          username :: binary(),
          user_access :: Privileges.access(),
          Bonny.Axn.t(),
          Postgrex.conn(),
          conn_args :: Keyword.t(),
          db_name :: binary()
        ) :: {:ok, Bonny.Axn.t()} | {:error, binary()}
  defp apply_user(username, user_access, axn, conn, conn_args, db_name) do
    resource_name = K8s.Resource.FieldAccessors.name(axn.resource)
    resource_namespace = K8s.Resource.FieldAccessors.namespace(axn.resource)
    secret_name = Slugger.slugify_downcase("psql-#{resource_name}-#{username}", ?-)
    password = get_user_password(axn.conn, resource_namespace, secret_name)
    %{"session_authorization" => superuser} = Postgrex.parameters(conn)

    with {:ok, user_env} <- User.apply(username, conn, db_name, password),
         :ok <- Privileges.grant(user_env[:DB_USER], superuser, conn),
         :ok <- Privileges.grant(user_env[:DB_USER], user_access, db_name, conn) do
      apply_user_secret(axn, secret_name, user_env, conn_args)
    else
      {:error, error} ->
        {:error, axn, error}
    end
  end

  @spec drop_users(users :: list(map()), db_name :: binary(), Postgrex.conn()) ::
          :ok | {:error, binary()}
  defp drop_users(users, db_name, conn) do
    %{"session_authorization" => superuser} = Postgrex.parameters(conn)

    users
    |> List.wrap()
    |> Enum.uniq()
    |> Enum.find_value(:ok, fn
      %{"username" => username} ->
        with :ok <- Privileges.revoke(username, :all, db_name, conn),
             :ok <- User.drop(username, superuser, conn) do
          false
        end
    end)
  end

  @spec get_user_password(K8s.Conn.t(), namespace :: binary(), name :: binary()) :: binary()
  defp get_user_password(conn, namespace, name) do
    case K8s.Client.get("v1", "Secret", namespace: namespace, name: name)
         |> K8s.Client.put_conn(conn)
         |> K8s.Client.run() do
      {:ok, secret} -> secret["data"]["DB_PASS"] |> Base.decode64!()
      {:error, _} -> Password.random_string()
    end
  end

  @spec add_finalizer?(Bonny.Axn.t()) :: boolean()
  def add_finalizer?(%Bonny.Axn{resource: resource}) do
    conditions =
      resource
      |> get_in([Access.key("status", %{}), Access.key("conditions", [])])
      |> Map.new(&{&1["type"], &1})

    resource["metadata"]["annotations"]["kompost.chuge.li/deletion-policy"] != "abandon" and
      conditions["Connection"]["status"] == "True"
  end

  @spec instance_id(resource :: map()) :: Instance.id()
  defp instance_id(%{"spec" => %{"instanceRef" => %{}}} = resource) do
    {resource["metadata"]["namespace"], resource["spec"]["instanceRef"]["name"]}
  end

  defp instance_id(%{"spec" => %{"clusterInstanceRef" => %{}}} = resource) do
    {:cluster, resource["spec"]["clusterInstanceRef"]["name"]}
  end
end
