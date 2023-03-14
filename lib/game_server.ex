defmodule GameServer do
  use GenServer

  alias GameEngine.{Board, Coordinates, Player}

  @server :"minodo@bt"

  def start_link(_) do
    GenServer.start_link(__MODULE__, Board.new(), name: __MODULE__)
  end

  def register(name) do
    GenServer.cast({__MODULE__, @server}, {:register, name, self()})
  end

  def move(target) do
    GenServer.cast({__MODULE__, @server}, {:move, target, self()})
  end

  def push(coordinate) do
    with {:ok, validated_coordinate} <- Coordinates.validate_coordinate(coordinate) do
      GenServer.cast({__MODULE__, @server}, {:push, validated_coordinate})
    end
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
    :timer.send_interval(50, self(), :tick)
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
  def handle_cast({:register, name, pid}, board) do
    {:noreply, Board.register(board, Player.new(name, pid))}
  end

  @impl true
  def handle_cast({:move, target, pid}, board) do
    {:noreply, Board.move(board, pid, target)}
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

  @impl true
  def handle_info(:tick, board) do
    board = board
    |> Board.move_players()
    |> Board.eat_fruits()
    |> Board.check_idles()
    #send each player board




    Phoenix.PubSub.broadcast!(
      Livebook.PubSub,
      "board_tick",
      {:board_tick, board}
    )
    {:noreply, board}
  end
end

# GenServer.cast(Game.GameServer, {:push, "AQUI!"})
