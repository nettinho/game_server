defmodule LocalGameServer do
  use GenServer

  alias GameEngine.{Board, Player}

  @board_settings %{
    width: 835,
    height: 250,
    player_inital_x: 400,
    player_inital_y: 125
  }

  def start_link(settings) do
    settings = Map.merge(@board_settings, settings)
    GenServer.start_link(__MODULE__, {nil, Board.new(settings)}, name: __MODULE__)
  end

  def register(server, name) do
    GenServer.cast(server, {:register, name, self(), Node.self()})
  end

  def unregister(server) do
    GenServer.cast(server, {:unregister, Node.self()})
  end

  def move(server, target) do
    GenServer.cast(server, {:move, target, Node.self()})
  end

  def change_color(server) do
    GenServer.cast(server, {:change_color, Node.self()})
  end

  def reset(server) do
    GenServer.cast(server, :reset)
  end

  def stop(server) do
    GenServer.cast(server, {:stop, Node.self()})
  end

  def add_fruits(server, count) do
    GenServer.cast(server, {:add_fruits, count})
  end

  def view(server) do
    GenServer.call(server, :view)
  end

  def set_pid(server, pid) do
    GenServer.cast(server, {:set_pid, pid})
  end

  def set_setting(server, setting, value) do
    GenServer.cast(server, {:set_setting, setting, value})
  end

  # Server (callbacks)

  @impl true
  def init(board) do
    :timer.send_interval(50, self(), :tick)
    {:ok, board}
  end

  @impl true
  def handle_call(:view, _from, board) do
    {:reply, board, board}
  end

  @impl true
  def handle_cast({:register, name, pid, node}, {lpid, %{settings: settings} = board}) do
    {:noreply, {lpid, Board.register(board, node, Player.new(cut_name(name), pid, settings))}}
  end

  @impl true
  def handle_cast({:unregister, node}, {pid, board}) do
    {:noreply, {pid, Board.unregister(board, node)}}
  end

  @impl true
  def handle_cast({:move, target, node}, {pid, board}) do
    {:noreply, {pid, Board.move(board, node, target)}}
  end

  @impl true
  def handle_cast({:change_color, node}, {pid, board}) do
    {:noreply, {pid, Board.change_color(board, node)}}
  end

  @impl true
  def handle_cast({:stop, node}, {pid, board}) do
    {:noreply, {pid, Board.stop(board, node)}}
  end

  @impl true
  def handle_cast({:add_fruits, count}, {pid, board}) do
    {:noreply, {pid, Board.add_fruits(board, count)}}
  end

  @impl true
  def handle_cast(:reset, {pid, _board}) do
    {:noreply, {pid, Board.new()}}
  end

  @impl true
  def handle_cast({:set_pid, pid}, {_, state}) do
    {:noreply, {pid, state}}
  end

  @impl true
  def handle_cast({:set_setting, setting, value}, {pid, %{settings: settings} = board}) do
    {:noreply, {pid, %{board | settings: Map.put(settings, setting, value)}}}
  end

  @impl true
  def handle_info(:tick, {pid, board}) do
    board =
      board
      |> Board.move_players()
      |> Board.eat_fruits()
      |> Board.check_state()
      |> Board.players_fight()
      |> Board.maybe_generate_fruit()

    send_player_messages(board)

    send(pid, {:board_tick, board})

    {:noreply, {pid, board}}
  end

  defp send_player_messages(%{players: players, fruits: fruits}) do
    Enum.each(players, fn {node, player} ->
      send(player.pid, {:board_tick, player, Map.drop(players, [node]), fruits})
    end)
  end

  defp cut_name(name) when is_number(name), do: cut_name(Integer.to_string(name))
  defp cut_name(name) when is_atom(name), do: cut_name(Atom.to_string(name))
  defp cut_name(name), do: String.slice(name, 0..2)
end

# GenServer.cast(Game.GameServer, {:push, "AQUI!"})
