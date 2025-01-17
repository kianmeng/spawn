defmodule Actors.FactoryTest do
  alias Eigr.Functions.Protocol.{
    RegistrationRequest,
    InvocationRequest,
    ActorInvocationResponse,
    ServiceInfo
  }

  alias Eigr.Functions.Protocol.Actors.{
    Registry,
    ActorSystem,
    Actor,
    ActorId,
    ActorSettings,
    TimeoutStrategy,
    ActorSnapshotStrategy,
    ActorDeactivationStrategy,
    ActorState
  }

  alias Eigr.Functions.Protocol.Actors.Registry.ActorsEntry
  alias Google.Protobuf.Any

  def encode_decode(record) do
    encoded = apply(record.__struct__, :encode, [record])

    apply(record.__struct__, :decode, [encoded])
  end

  def build_system(attrs \\ []) do
    ActorSystem.new(
      name: attrs[:name] || "test_system",
      registry: attrs[:registry] || nil
    )
  end

  def build_system_with_actors(attrs \\ []) do
    ActorSystem.new(
      name: attrs[:name] || "test_system",
      registry: attrs[:registry] || build_registry_with_actors()
    )
  end

  def build_registry_with_actors(attrs \\ []) do
    Registry.new(
      actors:
        attrs[:actors] ||
          Enum.reduce(
            1..(attrs[:count] || 5),
            %{},
            &Map.merge(build_actor_entry(name: "test_actor_#{&1}"), &2)
          )
    )
  end

  def build_registration_request(attrs \\ []) do
    RegistrationRequest.new(
      service_info: attrs[:service_info] || build_service_info(),
      actor_system: attrs[:actor_system] || build_system()
    )
  end

  def build_invocation_request(attrs \\ []) do
    value =
      Any.new(
        type_url: get_type_url(Actors.Protos.ChangeNameTest),
        value:
          Actors.Protos.ChangeNameTest.new(new_name: "new_name")
          |> Actors.Protos.ChangeNameTest.encode()
      )

    InvocationRequest.new(
      system: attrs[:system] || build_system(),
      actor: attrs[:actor] || build_actor(),
      async: attrs[:async] || false,
      command_name: attrs[:command_name] || "ChangeNameTest",
      value: attrs[:value] || value
    )
  end

  def build_actor_entry(attrs \\ []) do
    default_name = Faker.Superhero.name()

    %{
      (attrs[:name] || default_name) =>
        attrs[:actor] || build_actor(name: attrs[:name] || default_name)
    }
  end

  def build_actor(attrs \\ []) do
    actor_name = attrs[:name] || "#{Faker.Superhero.name()} #{Faker.StarWars.character()}"

    Actor.new(
      id: %ActorId{name: actor_name},
      settings: %ActorSettings{
        persistent: Keyword.get(attrs, :persistent, true),
        snapshot_strategy: attrs[:snapshot_strategy] || build_actor_snapshot_strategy(),
        deactivation_strategy:
          attrs[:deactivation_strategy] || build_actor_deactivation_strategy()
      },
      state: attrs[:state] || build_actor_state()
    )
  end

  def build_actor_state(attrs \\ []) do
    state =
      any_pack!(Actors.Protos.StateTest.new(name: "example_state_name_#{Faker.Superhero.name()}"))

    ActorState.new(state: Any.new(attrs[:state] || state))
  end

  def build_actor_deactivation_strategy(attrs \\ []) do
    timeout = TimeoutStrategy.new(timeout: attrs[:timeout] || 60_000)

    ActorDeactivationStrategy.new(
      strategy: {attrs[:strategy] || :timeout, attrs[:value] || timeout}
    )
  end

  def build_actor_snapshot_strategy(attrs \\ []) do
    timeout = TimeoutStrategy.new(timeout: attrs[:timeout] || 60_000)

    ActorSnapshotStrategy.new(strategy: {attrs[:strategy] || :timeout, attrs[:value] || timeout})
  end

  def build_service_info(attrs \\ []) do
    ServiceInfo.new(
      service_name: attrs[:service_name] || "test_service",
      service_version: attrs[:service_version] || "1.0.0",
      service_runtime: attrs[:service_runtime] || "test_runtime",
      support_library_name: attrs[:support_library_name] || "",
      support_library_version: attrs[:support_library_version] || "",
      protocol_major_version: attrs[:protocol_major_version] || 1,
      protocol_minor_version: attrs[:protocol_minor_version] || 1
    )
  end

  def build_host_invoke_response(attrs \\ []) do
    state =
      Actors.Protos.ChangeNameResponseTest.new(status: :OK, new_name: "new_name") |> any_pack!

    context = Eigr.Functions.Protocol.Context.new(state: attrs[:state] || state)

    ActorInvocationResponse.new(
      actor_name: attrs[:actor_name],
      system_name: attrs[:system_name],
      updated_context: attrs[:context] || context,
      value: attrs[:value] || state
    )
  end

  def any_pack!(record) do
    Any.new(
      type_url: get_type_url(record.__struct__),
      value: apply(record.__struct__, :encode, [record])
    )
  end

  def any_unpack!(any_record, builder) do
    builder.decode(any_record.value)
  end

  defp get_type_url(type) do
    parts =
      type
      |> to_string
      |> String.replace("Elixir.", "")
      |> String.split(".")

    package_name =
      with {_, list} <- parts |> List.pop_at(-1),
           do: list |> Enum.map(&String.downcase(&1)) |> Enum.join(".")

    type_name = parts |> List.last()

    "type.googleapis.com/#{package_name}.#{type_name}"
  end
end
