defmodule GameServer do
  use GenServer

  alias GameEngine.Board

  @server :"minodo@bt"

  def start_link() do
    GenServer.start_link(__MODULE__, Board.new(), name: __MODULE__)
  end

  def push(coordinate) do
    GenServer.cast({__MODULE__, @server}, {:push, coordinate})
  end

  # def pop() do
  #   GenServer.call({__MODULE__, @server}, :pop)
  # end

  def view() do
    GenServer.call({__MODULE__, @server}, :view)
  end

  # Server (callbacks)

  @impl true
  def init(board) do
    {:ok, board}
  end

  # @impl true
  # def handle_call(:pop, _from, [head | tail]) do
  #   {:reply, head, tail}
  # end

  @impl true
  def handle_call(:view, _from, board) do
    {:reply, board, board}
  end

  @impl true
  def handle_cast({:push, coordinate}, board) do
    ## config :livebook, LivebookWeb.Endpoint,
    ## url: [host: "localhost", path: "/"],
    ## pubsub_server: Livebook.PubSub,
    # Application.fetch_env!(:livebook, LivebookWeb.Endpoint)[:pubsub_server]

    Phoenix.PubSub.broadcast!(
      Livebook.PubSub,
      "game",
      {:msg, "new element: #{inspect(coordinate)}"}
    )

    {:noreply, Board.position_player(board, coordinate, "some_player")}
  end
end

# GenServer.cast(Game.GameServer, {:push, "AQUI!"})
