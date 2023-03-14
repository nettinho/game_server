defmodule GameServer do
  use GenServer

  alias GameEngine.{Board, Coordinates, Player}

  @server :"minodo@bt"

  def start_link(_) do
    GenServer.start_link(__MODULE__, Board.new(), name: __MODULE__)
  end

  def register(name) do
    GenServer.cast({__MODULE__, @server}, {:register, name, self(), Node.self()})
  end

  def unregister() do
    GenServer.cast({__MODULE__, @server}, {:unregister, Node.self()})
  end

  def move(target) do
    GenServer.cast({__MODULE__, @server}, {:move, target, Node.self()})
  end

  def change_color do
    GenServer.cast({__MODULE__, @server}, {:change_color, Node.self()})
  end

  def reset do
    GenServer.cast({__MODULE__, @server}, :reset)
  end

  def stop do
    GenServer.cast({__MODULE__, @server}, {:stop, Node.self()})
  end

  def add_fruits(count) do
    GenServer.cast({__MODULE__, @server}, {:add_fruits, count})
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
  def handle_cast({:register, name, pid, node}, board) do
    {:noreply, Board.register(board, node, Player.new(cut_name(name), pid))}
  end

  @impl true
  def handle_cast({:unregister, node}, board) do
    {:noreply, Board.unregister(board, node)}
  end

  @impl true
  def handle_cast({:move, target, node}, board) do
    {:noreply, Board.move(board, node, target)}
  end

  @impl true
  def handle_cast({:change_color, node}, board) do
    {:noreply, Board.change_color(board, node)}
  end

  @impl true
  def handle_cast({:stop, node}, board) do
    {:noreply, Board.stop(board, node)}
  end

  @impl true
  def handle_cast({:add_fruits, count}, board) do
    {:noreply, Board.add_fruits(board, count)}
  end

  @impl true
  def handle_cast(:reset, _board) do
    {:noreply, Board.new()}
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
    |> Board.check_state()

    send_player_messages(board)

    Phoenix.PubSub.broadcast!(
      Livebook.PubSub,
      "board_tick",
      {:board_tick, board}
    )
    {:noreply, board}
  end

  defp send_player_messages(%{players: players, fruits: fruits}) do
    Enum.each(players, fn {_node, player} ->
      send(player.pid, {:board_tick, player, fruits})
    end)
  end


  defp cut_name(name) when is_number(name), do: cut_name(Integer.to_string(name))
  defp cut_name(name) when is_atom(name), do: cut_name(Atom.to_string(name))
  defp cut_name(name), do: String.slice(name, 0..2)
end

# GenServer.cast(Game.GameServer, {:push, "AQUI!"})
