defmodule GameEngine.Board do

  alias GameEngine.Player

  def new(), do: %{
    players: %{},
    fruits: []
  }

  def register(%{players: players} = board, player) do
    %{board | players: Map.put(players, player.pid, player)}
  end

  def move(%{players: players} = board, pid, target) do
    case Map.get(board.players, pid) do
      nil -> board
      player -> %{board | players: %{players | player.pid => %{player | target: target}}}
    end
  end

  def move_players(board) do
    players = board
    |> Map.get(:players)
    |> Enum.map(fn {pid, player} -> {pid, Player.move_player(player)} end)
    |> Map.new

    %{board | players: players}
  end
  def eat_fruits(board) do
    board
  end
  def check_idles(board) do
    board
  end

  def position_player(board, coordinate, player) do
    players_at_position = Map.get(board, coordinate, MapSet.new())
    Map.put(board, coordinate, MapSet.put(players_at_position, player))
  end
end
