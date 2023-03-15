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
    GenServer.start_link(__MODULE__, {nil, Board.new(settings)})
  end

  def register(server, name) do
    GenServer.call(server, {:register, name, self(), Node.self()})
  end

  def unregister(server) do
    GenServer.call(server, {:unregister, Node.self()})
  end

  def move(server, target) do
    GenServer.call(server, {:move, target, Node.self()})
  end

  def change_color(server) do
    GenServer.call(server, {:change_color, Node.self()})
  end

  def reset(server) do
    GenServer.call(server, :reset)
  end

  def stop(server) do
    GenServer.call(server, {:stop, Node.self()})
  end

  def add_fruits(server, count) do
    GenServer.call(server, {:add_fruits, count})
  end

  def view(server) do
    GenServer.call(server, :view)
  end

  def set_pid(server, pid) do
    GenServer.call(server, {:set_pid, pid})
  end

  def set_setting(server, setting, value) do
    GenServer.call(server, {:set_setting, setting, value})
  end

  # Server (callbacks)

  @impl true
  def init(board) do
    :timer.send_interval(50, self(), :tick)
    {:ok, board}
  end

  @impl true
  def handle_call(:view, _from, {pid, board}) do
    {:reply, board, {pid, board}}
  end

  @impl true
  def handle_call({:register, name, pid, node}, _, {lpid, %{settings: settings} = board}) do
    {:reply, :ok, {lpid, Board.register(board, node, Player.new(cut_name(name), pid, settings))}}
  end

  @impl true
  def handle_call({:unregister, node}, _, {pid, board}) do
    {:reply, :ok, {pid, Board.unregister(board, node)}}
  end

  @impl true
  def handle_call({:move, target, node}, _, {pid, board}) do
    {:reply, :ok, {pid, Board.move(board, node, target)}}
  end

  @impl true
  def handle_call({:change_color, node}, _, {pid, board}) do
    {:reply, :ok, {pid, Board.change_color(board, node)}}
  end

  @impl true
  def handle_call({:stop, node}, _, {pid, board}) do
    {:reply, :ok, {pid, Board.stop(board, node)}}
  end

  @impl true
  def handle_call({:add_fruits, count}, _, {pid, board}) do
    {:reply, :ok, {pid, Board.add_fruits(board, count)}}
  end

  @impl true
  def handle_call(:reset, _, {pid, _board}) do
    {:reply, :ok, {pid, Board.new()}}
  end

  @impl true
  def handle_call({:set_pid, pid}, _, {_, state}) do
    {:reply, :ok, {pid, state}}
  end

  @impl true
  def handle_call({:set_setting, setting, value}, _, {pid, %{settings: settings} = board}) do
    {:reply, :ok, {pid, %{board | settings: Map.put(settings, setting, value)}}}
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

    case board.settings do
      %{success_func: nil} ->
        nil

      %{success_func: success_func} ->
        if success_func.(board) do
          send(pid, {:success, board})
        end
    end

    case board.settings do
      %{failure_func: nil} ->
        nil

      %{failure_func: failure_func} ->
        if failure_func.(board) do
          send(pid, {:failure, board})
        end
    end

    send(pid, {:board_tick, board})

    {:noreply, {pid, board}}
  end

  defp send_player_messages(%{players: players, fruits: fruits}) do
    Enum.each(players, fn
      {_node, %{pid: nil}} ->
        nil

      {node, player} ->
        send(player.pid, {:board_tick, player, Map.drop(players, [node]), fruits})
    end)
  end

  defp cut_name(name) when is_number(name), do: cut_name(Integer.to_string(name))
  defp cut_name(name) when is_atom(name), do: cut_name(Atom.to_string(name))
  defp cut_name(name), do: String.slice(name, 0..2)
end

# GenServer.cast(Game.GameServer, {:push, "AQUI!"})
