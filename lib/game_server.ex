defmodule GameServer do
  use GenServer

  alias GameEngine.{Board, Player}

  @local_board_settings %{
    broadcast_pub_sub: false,
    width: 835,
    height: 250,
    player_inital_x: 400,
    player_inital_y: 125
  }

  def start_link(_) do
    GenServer.start_link(__MODULE__, Board.new(), name: __MODULE__)
  end

  def start_link(:local, settings) do
    settings = Map.merge(@local_board_settings, settings)
    GenServer.start_link(__MODULE__, Board.new(settings))
  end

  defp compose_server(server) when is_atom(server), do: {__MODULE__, server}
  defp compose_server(server), do: server

  def register(server, name) do
    GenServer.call(compose_server(server), {:register, name, self(), Node.self()})
  end

  def unregister(server) do
    GenServer.call(compose_server(server), {:unregister, Node.self()})
  end

  def move(server, target) do
    GenServer.call(compose_server(server), {:move, target, Node.self()})
  end

  def change_color(server) do
    GenServer.call(compose_server(server), {:change_color, Node.self()})
  end

  def reset(server) do
    GenServer.call(compose_server(server), :reset)
  end

  def stop(server) do
    GenServer.call(compose_server(server), {:stop, Node.self()})
  end

  def add_fruits(server, count) do
    GenServer.call(compose_server(server), {:add_fruits, count})
  end

  def view(server) do
    GenServer.call(compose_server(server), :view)
  end

  def set_local_receiver(server, pid) do
    GenServer.call(compose_server(server), {:set_setting, :local_receiver, pid})
  end

  def set_setting(server, setting, value) do
    GenServer.call(compose_server(server), {:set_setting, setting, value})
  end

  # Server (callbacks)

  @impl true
  def init(board) do
    # :timer.send_interval(50, self(), :tick)
    Process.send_after(self(), :tick, 50)
    {:ok, board}
  end

  defp cut_name(name) when is_number(name), do: cut_name(Integer.to_string(name))
  defp cut_name(name) when is_atom(name), do: cut_name(Atom.to_string(name))
  defp cut_name(name), do: String.slice(name, 0..2)

  @impl true
  def handle_call(:view, _from, board) do
    {:reply, board, board}
  end

  @impl true
  def handle_call({:register, name, pid, node}, _, %{settings: settings} = board) do
    {:reply, :ok, Board.register(board, node, Player.new(cut_name(name), pid, settings))}
  end

  @impl true
  def handle_call({:unregister, node}, _, board) do
    {:reply, :ok, Board.unregister(board, node)}
  end

  @impl true
  def handle_call({:move, target, node}, _, board) do
    {:reply, :ok, Board.move(board, node, target)}
  end

  @impl true
  def handle_call({:change_color, node}, _, board) do
    {:reply, :ok, Board.change_color(board, node)}
  end

  @impl true
  def handle_call({:stop, node}, _, board) do
    {:reply, :ok, Board.stop(board, node)}
  end

  @impl true
  def handle_call({:add_fruits, count}, _, board) do
    {:reply, :ok, Board.add_fruits(board, count)}
  end

  @impl true
  def handle_call(:reset, _, _board) do
    {:reply, :ok, Board.new()}
  end

  @impl true
  def handle_call({:set_setting, setting, value}, _, %{settings: settings} = board) do
    {:reply, :ok, %{board | settings: Map.put(settings, setting, value)}}
  end

  @impl true
  def handle_info(:tick, board) do
    response =
      board
      |> Board.move_players()
      |> Board.eat_fruits()
      |> Board.check_state()
      |> Board.players_fight()
      |> Board.maybe_generate_fruit()
      |> send_player_messages()
      |> broadcast_pub_sub()
      |> tick_local_receiver()
      |> handle_success_func()
      |> handle_failure_func()
      |> reply()

    Process.send_after(self(), :tick, 50)

    response
  end

  defp send_player_messages(%{players: players, fruits: fruits} = board) do
    Enum.each(players, fn
      {_node, %{pid: nil}} ->
        nil

      {node, player} ->
        send(player.pid, {:board_tick, player, Map.drop(players, [node]), fruits})
    end)

    board
  end

  defp broadcast_pub_sub(%{settings: %{broadcast_pub_sub: true}} = board) do
    Phoenix.PubSub.broadcast!(
      Livebook.PubSub,
      "board_tick",
      {:board_tick, board}
    )

    board
  end

  defp broadcast_pub_sub(board), do: board

  defp tick_local_receiver(%{settings: %{local_receiver: pid}} = board) when is_pid(pid) do
    send(pid, {:board_tick, board})
    board
  end

  defp tick_local_receiver(board), do: board

  defp handle_success_func(%{settings: %{success_func: fun, local_receiver: pid}} = board)
       when is_function(fun) and is_pid(pid) do
    if fun.(board) do
      send(pid, {:success, board})
      halt_board(board)
    else
      board
    end
  end

  defp handle_success_func(board), do: board

  defp handle_failure_func(%{settings: %{failure_func: fun, local_receiver: pid}} = board)
       when is_function(fun) and is_pid(pid) do
    if fun.(board) do
      send(pid, {:failure, board})
      halt_board(board)
    else
      board
    end
  end

  defp handle_failure_func(board), do: board

  defp halt_board(board), do: Map.put(board, :halt, true)

  defp reply(%{halt: true}), do: {:stop, :normal, nil}
  defp reply(board), do: {:noreply, board}
end
