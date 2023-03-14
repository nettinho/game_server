defmodule GameEngine.Board do

  alias GameEngine.Player

  @velocity_gain 0.2
  @width 500
  @height 500
  @fruit_min_size 5
  @fruit_max_size 25

  def new(), do: %{
    players: %{},
    fruits: Map.new(for _ <- 1..5, do: random_fruit())
  }

  def width, do: @width
  def height, do: @height

  def random_pos, do: {:rand.uniform(@width), :rand.uniform(@height)}
  def random_fruit, do: {random_pos(), :rand.uniform(@fruit_max_size - @fruit_min_size) + @fruit_min_size}

  def register(%{players: players} = board, player) do
    %{board | players: Map.put(players, player.pid, player)}
  end

  def move(%{players: players} = board, pid, target) do
    case Map.get(board.players, pid) do
      nil -> board
      player -> %{board | players: %{players | player.pid => %{player | target: target}}}
    end
  end

  def stop(%{players: players} = board, pid) do
    case Map.get(board.players, pid) do
      nil -> board
      player -> %{board | players: %{players | player.pid => %{player | target: nil, status: :idle}}}
    end
  end

  def add_fruits(%{fruits: fruits} = board, count) do
    new_fruits = Map.new(for _ <- 1..count, do: random_fruit())
    %{board | fruits: Map.merge(fruits, new_fruits)}
  end

  def move_players(board) do
    players = board
    |> Map.get(:players)
    |> Enum.map(fn {pid, player} -> {pid, Player.move_player(player)} end)
    |> Map.new

    %{board | players: players}
  end
  def eat_fruits(board) do
    {players, fruits} = board
    |> Map.get(:players)
    |> Enum.reduce(
        {%{}, board.fruits},
        fn {pid, %{pos: pos, score: score, velocity: velocity} = player}, {players, fruits} ->
          case Map.get(fruits, pos) do
            nil ->
              {Map.put(players, pid, player), fruits}
            size ->
              {
                Map.put(players, pid, %{player | score: score + size, velocity: velocity + @velocity_gain}),
                Map.drop(fruits, [pos])
              }
          end
        end
      )


    %{board | fruits: fruits, players: players}
  end
  def check_state(board) do
    checks = [
      &Player.check_target/1,
      &Player.check_x_borders/1,
      &Player.check_y_borders/1,
    ]

    players = board
    |> Map.get(:players)
    |> Enum.map(fn {pid, player} -> {pid, Enum.reduce(checks, player, fn fun, p -> fun.(p) end)} end)
    |> Map.new

    %{board | players: players}
  end

  def position_player(board, coordinate, player) do
    players_at_position = Map.get(board, coordinate, MapSet.new())
    Map.put(board, coordinate, MapSet.put(players_at_position, player))
  end
end
