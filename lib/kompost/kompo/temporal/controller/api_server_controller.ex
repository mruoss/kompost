defmodule Kompost.Kompo.Temporal.Controller.APIServerController do
  use Bonny.ControllerV2

  require Logger

  alias Kompost.Kompo.Temporal.Conn

  step Bonny.Pluggable.SkipObservedGenerations

  step Kompost.Pluggable.InitConditions, conditions: ["Connected"]
  step :handle_event

  @spec handle_event(Bonny.Axn.t(), Keyword.t()) :: Bonny.Axn.t()
  def handle_event(%Bonny.Axn{action: action} = axn, _opts)
      when action in [:add, :modify, :reconcile] do
    id = Conn.get_id(axn.resource)
    addr = "#{axn.resource["spec"]["host"]}:#{axn.resource["spec"]["port"]}"

    case Conn.connect(id, addr) do
      {:ok, _} ->
        axn
        |> success_event(message: "gRPC connection to Temporal established successfully.")
        |> set_condition(
          "Connected",
          true,
          "gRPC connection to Temporal established successfully."
        )

      {:error, reason} ->
        message = "Could not connect to Temporal cluster: #{reason}"
        Logger.warn("#{axn.action} failed. #{message}")

        axn
        |> failure_event(message: message)
        |> set_condition("Connected", false, message)
    end
  end

  def handle_event(%Bonny.Axn{action: :delete} = axn, _opts) do
    success_event(axn)
  end
end
