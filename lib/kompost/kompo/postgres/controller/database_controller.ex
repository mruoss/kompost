defmodule Kompost.Kompo.Postgres.Controller.DatabaseController do
  use Bonny.ControllerV2

  require Logger

  alias Kompost.Kompo.Postgres.Database
  alias Kompost.Kompo.Postgres.Instance
  alias Kompost.Kompo.Postgres.User
  alias Kompost.Tools.Password

  import YamlElixir.Sigil

  step(Bonny.Pluggable.SkipObservedGenerations)
  step(:handle_event)

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
         {:app_user, {:ok, app_user_env}} <-
           {:app_user, User.apply(conn, db_name, :app, Password.random_string())},
         axn <-
           set_condition(
             axn,
             "AppUser",
             true,
             "Application user was created successfully."
           ),
         {:ok, axn} <- create_user_secret(axn, :app, app_user_env, db_name, conn_args),
         {:inspector_user, {:ok, inspector_user_env}} <-
           {:inspector_user, User.apply(conn, db_name, :inspector, Password.random_string())},
         axn <-
           set_condition(
             axn,
             "InspectorUser",
             true,
             "Inspector user was created successfully."
           ),
         {:ok, axn} <-
           create_user_secret(axn, :inspector, inspector_user_env, db_name, conn_args) do
      success_event(axn)
    else
      {:instance, []} ->
        message = "The referenced PostgreSQL instance was not found."

        axn
        |> failure_event(message: message)
        |> set_condition("Connection", false, message)

      {:app_user, {:error, message}} ->
        axn
        |> failure_event(message: message)
        |> set_condition("AppUser", false, message)

      {:inspector_user, {:error, message}} ->
        axn
        |> failure_event(message: message)
        |> set_condition("InspectorUser", false, message)
    end
  end

  def handle_event(%Bonny.Axn{action: :delete} = axn, _opts) do
    success_event(axn)
  end

  @spec create_user_secret(
          Bonny.Axn.t(),
          user_type :: User.user_type(),
          app_user_env :: map(),
          db_name :: binary(),
          conn_args :: Keyword.t()
        ) :: {:ok, Bonny.Axn.t()}
  defp create_user_secret(axn, user_type, app_user_env, db_name, conn_args) do
    resource_name = K8s.Resource.FieldAccessors.name(axn.resource)
    secret_name = Slugger.slugify_downcase("psql-#{resource_name}-#{user_type}", ?-)

    data =
      Map.merge(app_user_env, %{
        DB_HOST: Keyword.fetch!(conn_args, :hostname),
        DB_PORT: Keyword.fetch!(conn_args, :port),
        DB_NAME: db_name
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

    axn =
      axn
      |> Bonny.Axn.register_descendant(user_secret)
      |> Bonny.Axn.update_status(fn status ->
        status
        |> Map.put("#{user_type}_user_secret", secret_name)
      end)

    {:ok, axn}
  end
end
