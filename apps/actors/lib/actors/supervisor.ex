defmodule Actors.Supervisor do
  use Supervisor
  require Logger

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  def child_spec(config) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [config]}
    }
  end

  @impl true
  def init(config) do
    Protobuf.load_extensions()

    children = [
      cluster_supervisor(config),
      {Registry, keys: :unique, name: Actors.NodeRegistry},
      Actors.Registry.ActorRegistry.Supervisor,
      Actors.Node.NodeManager.Supervisor,
      Actors.Actor.Registry.child_spec(),
      Actors.Actor.Entity.Supervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp cluster_supervisor(config) do
    cluster_strategy = config.proxy_cluster_strategy

    topologies =
      case cluster_strategy do
        "gossip" ->
          get_gossip_strategy()

        "kubernetes-dns" ->
          get_dns_strategy(config)

        _ ->
          Logger.warn("Invalid Topology")
      end

    if topologies && Code.ensure_compiled(Cluster.Supervisor) do
      Logger.info("Cluster Strategy #{cluster_strategy}")

      Logger.debug("Cluster topology #{inspect(topologies)}")
      {Cluster.Supervisor, [topologies, [name: Actors.ClusterSupervisor]]}
    end
  end

  defp get_gossip_strategy(),
    do: [
      proxy: [
        strategy: Cluster.Strategy.Gossip
      ]
    ]

  defp get_dns_strategy(config),
    do: [
      proxy: [
        strategy: Elixir.Cluster.Strategy.Kubernetes.DNS,
        config: [
          service: config.proxy_headless_service,
          application_name: config.proxy_app_name,
          polling_interval: config.proxy_cluster_poling_interval
        ]
      ]
    ]
end