defmodule ElixirConf2024.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ElixirConf2024Web.Telemetry,
      # ElixirConf2024.Repo,
      {DNSCluster, query: Application.get_env(:elixir_conf_2024, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ElixirConf2024.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: ElixirConf2024.Finch},
      # Start a worker by calling: ElixirConf2024.Worker.start_link(arg)
      # {ElixirConf2024.Worker, arg},
      # Start to serve requests, typically the last entry
      ElixirConf2024Web.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirConf2024.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ElixirConf2024Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
