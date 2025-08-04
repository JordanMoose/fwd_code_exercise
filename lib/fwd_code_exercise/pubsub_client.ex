defmodule FwdCodeExercise.PubSubClient do
  @moduledoc """
  Behaviour for the Phoenix PubSub client.
  """

  @callback subscribe(term(), binary()) :: :ok | {:error, any()}
  @callback broadcast(term(), binary(), term()) :: :ok | {:error, any()}

  @spec impl() :: module()
  def impl() do
    Application.get_env(:fwd_code_exercise, :pubsub_client, Phoenix.PubSub)
  end

  @doc """
  Subscribes to a topic in the PubSub module.

  ## Parameters
  - `pubsub_module`: The PubSub module to use for subscription.
  - `topic`: The topic to subscribe to.

  ## Returns
  - `:ok`: If the subscription is successful.
  - `{:error, reason}`: If the subscription fails.
  """
  @spec subscribe(term(), binary()) :: :ok | {:error, any()}
  def subscribe(pubsub_module, topic) do
    impl().subscribe(pubsub_module, topic)
  end

  @doc """
  Broadcasts a message to a topic in the PubSub module.

  ## Parameters
  - `pubsub_module`: The PubSub module to use for broadcasting.
  - `topic`: The topic to broadcast to.
  - `message`: The message to broadcast.

  ## Returns
  - `:ok`: If the broadcast is successful.
  - `{:error, reason}`: If the broadcast fails.
  """
  @spec broadcast(term(), binary(), term()) :: :ok | {:error, any()}
  def broadcast(pubsub_module, topic, message) do
    impl().broadcast(pubsub_module, topic, message)
  end
end
