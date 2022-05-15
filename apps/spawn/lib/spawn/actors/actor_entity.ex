defmodule Eigr.Functions.Protocol.Actors.ActorEntity do
  use GenServer, restart: :transient
  require Logger

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorState,
    ActorDeactivateStrategy,
    ActorSnapshotStrategy,
    StateManager,
    TimeoutStrategy
  }

  @default_timeout 90_000

  @impl true
  @spec init(Eigr.Functions.Protocol.Actors.Actor.t()) ::
          {:ok, Eigr.Functions.Protocol.Actors.Actor.t(), {:continue, :load_state}}
  def init(
        %Actor{
          name: name,
          snapshot_strategy: %ActorSnapshotStrategy{strategy: snapshot_strategy},
          deactivate_strategy: %ActorDeactivateStrategy{strategy: deactivate_strategy}
        } = state
      ) do
    Logger.debug("Activating actor #{name}")
    Process.flag(:trap_exit, true)
    snapshot(snapshot_strategy)
    Process.send_after(self(), :deactivate, get_deactivate_interval(deactivate_strategy))

    {:ok, state, {:continue, :load_state}}
  end

  @impl true
  @spec handle_continue(:load_state, Eigr.Functions.Protocol.Actors.Actor.t()) ::
          {:noreply, Eigr.Functions.Protocol.Actors.Actor.t()}
  def handle_continue(:load_state, %Actor{actor_state: nil} = state) do
    Logger.debug("Initial state is empty... Getting state from state manager.")

    {:ok, current_state} = StateManager.load(state.name)
    {:noreply, %Actor{state | actor_state: current_state}}
  end

  def handle_continue(:load_state, %Actor{actor_state: %ActorState{} = actor_state} = state) do
    Logger.debug(
      "Initial state is not empty... Trying to reconcile the state with state manager."
    )

    {:ok, _current_state} = StateManager.load(state.name)

    # TODO: Check if the state is empty in the state manager. If so, then set state from initial state.
    updated_state = actor_state
    {:noreply, %Actor{state | actor_state: updated_state}}
  end

  @impl true
  def handle_info(
        :snapshot,
        %Actor{
          name: _name,
          snapshot_strategy: %ActorSnapshotStrategy{strategy: snapshot_strategy},
          actor_state: nil
        } = state
      ) do
    snapshot(snapshot_strategy)
    {:noreply, state}
  end

  def handle_info(
        :snapshot,
        %Actor{
          name: name,
          snapshot_strategy: %ActorSnapshotStrategy{strategy: snapshot_strategy},
          actor_state: %ActorState{} = actor_state
        } = state
      ) do
    Logger.debug("Snapshotting actor #{name}")
    StateManager.save(name, actor_state)
    snapshot(snapshot_strategy)
    {:noreply, state}
  end

  @impl true
  def handle_info(:deactivate, %Actor{name: name} = state) do
    case Process.info(self(), :message_queue_len) do
      {:message_queue_len, 0} ->
        Logger.debug("Deactivating actor #{name} for timeout")
        {:stop, :normal, state}

      _ ->
        {:noreply, state}
    end
  end

  def handle_info(
        {:EXIT, _ref, {:shutdown, :process_redistribution}},
        %Actor{name: name, actor_state: %ActorState{} = actor_state} = state
      ) do
    Logger.debug("Rebalancing actor #{name} from Node #{inspect(Node.self())}")
    StateManager.save(name, actor_state)
    {:noreply, state}
  end

  @impl true
  def terminate(reason, %Actor{name: name, actor_state: %ActorState{} = actor_state} = _state) do
    StateManager.save(name, actor_state)
    Logger.debug("Terminating actor #{name} with reason #{inspect(reason)}")
  end

  def start_link(%Actor{name: name} = actor) do
    GenServer.start(__MODULE__, actor, name: via(name))
  end

  defp snapshot(snapshot_strategy),
    do: Process.send_after(self(), :snapshot, get_snapshot_interval(snapshot_strategy))

  defp get_snapshot_interval(%TimeoutStrategy{timeout: timeout} = _timeout_strategy)
       when is_nil(timeout),
       do: @default_timeout

  defp get_snapshot_interval(%TimeoutStrategy{timeout: timeout} = _timeout_strategy),
    do: timeout

  defp get_deactivate_interval(%TimeoutStrategy{timeout: timeout} = _timeout_strategy)
       when is_nil(timeout),
       do: @default_timeout

  defp get_deactivate_interval(%TimeoutStrategy{timeout: timeout} = _timeout_strategy),
    do: timeout

  defp via(name) do
    {:via, Horde.Registry, {Spawn.Actor.Registry, {__MODULE__, name}}}
  end
end