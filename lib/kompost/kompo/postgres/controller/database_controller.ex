defmodule Kompost.Kompo.Postgres.Controller.DatabaseController do
  use Bonny.ControllerV2

  require Logger

  alias Kompost.Kompo.Postgres.Database
  alias Kompost.Kompo.Postgres.Instance
  alias Kompost.Kompo.Postgres.Privileges
  alias Kompost.Kompo.Postgres.User
  alias Kompost.Tools.Password

  import YamlElixir.Sigil

  step Bonny.Pluggable.SkipObservedGenerations
  step Kompost.Pluggable.InitConditions, conditions: ["Connection", "AppUser", "InspectorUser"]
  step :handle_event

  @impl true
  def rbac_rules() do
    [to_rbac_rule({"v1", "Secret", ["*"]})]
  end

  @spec handle_event(Bonny.Axn.t(), Keyword.t()) :: Bonny.Axn.t()
  def handle_event(%Bonny.Axn{action: action} = axn, _opts)
      when action in [:add, :modify, :reconcile] do
    resource = axn.resource
    instance_id = Instance.get_id(resource)
    db_name = Database.name(resource)

    with {:instance, [{conn, conn_args}]} <- {:instance, Instance.lookup(instance_id)},
         axn <-
           set_condition(
             axn,
             "Connection",
             true,
             "Connected to the referenced PostgreSQL instance."
           ),
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

        axn
        |> failure_event(message: message)
        |> set_condition("Connection", false, message)

      {:app_user, {:error, axn, message}} ->
        axn
        |> failure_event(message: message)
        |> set_condition("AppUser", false, message)

      {:inspector_user, {:error, axn, message}} ->
        axn
        |> failure_event(message: message)
        |> set_condition("InspectorUser", false, message)
    end
  end

  def handle_event(%Bonny.Axn{action: :delete} = axn, _opts) do
    success_event(axn)
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
        DB_PORT: Keyword.fetch!(conn_args, :port)
      })

    user_secret =
      ~y"""
      apiVersion: v1
      kind: secret
      metadata:
          namespace: #{K8s.Resource.FieldAccessors.namespace(axn.resource)}
          name: #{secret_name}
      """
      |> Map.put("stringData", data)

    status_entry = %{"username" => user_env["DB_USER"], "secret" => secret_name}

    axn =
      axn
      |> Bonny.Axn.register_descendant(user_secret)
      |> Bonny.Axn.update_status(fn status ->
        Map.update(status, "secrets", [status_entry], &[status_entry | &1])
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

    with {:ok, user_env} <- User.apply(username, conn, db_name, password),
         :ok <- Privileges.grant(user_env["DB_USER"], "CURRENT_USER", conn),
         :ok <- Privileges.grant(user_env["DB_USER"], user_access, db_name, conn) do
      apply_user_secret(axn, secret_name, user_env, conn_args)
    else
      {:error, error} ->
        {:error, axn, error}
    end
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
end
