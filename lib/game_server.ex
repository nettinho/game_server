defmodule GameServer do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def push(element) do
    GenServer.cast({__MODULE__, :"minodo@nettos-MacBook-Pro"}, {:push, element})
  end

  def pop() do
    GenServer.call({__MODULE__, :"minodo@nettos-MacBook-Pro"}, :pop)
  end

  def view() do
    GenServer.call({__MODULE__, :"minodo@nettos-MacBook-Pro"}, :view)
  end

  # Server (callbacks)

  @impl true
  def init(stack) do
    {:ok, stack}
  end

  @impl true
  def handle_call(:pop, _from, [head | tail]) do
    {:reply, head, tail}
  end

  @impl true
  def handle_call(:view, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:push, element}, state) do
    ## config :livebook, LivebookWeb.Endpoint,
    ## url: [host: "localhost", path: "/"],
    ## pubsub_server: Livebook.PubSub,
    # Application.fetch_env!(:livebook, LivebookWeb.Endpoint)[:pubsub_server]

    Phoenix.PubSub.broadcast!(
      Livebook.PubSub,
      "game",
      {:msg, "new element: #{inspect(element)}"}
    )

    {:noreply, [element | state]}
  end
end

# GenServer.cast(Game.GameServer, {:push, "AQUI!"})
