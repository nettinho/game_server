defmodule GameEngine.Board do

  alias GameEngine.Player

  @velocity_gain_per_fruit 0.001
  @size_gain_per_fruit 0.2
  @width 750
  @height 750
  @fruit_min_size 5
  @fruit_max_size 25
  @powered_ticks_per_fruit_size 5

  @fruit_type_distribution  [
    {:default, 4},
    {:power_up, 1}
  ]

  @fruit_generated_probability 10

  @max_powered 450


  def new(), do: %{
    players: %{},
    fruits: Map.new(for _ <- 1..10, do: random_fruit())
  }

  def width, do: @width
  def height, do: @height

  def random_pos, do: {:rand.uniform(@width), :rand.uniform(@height)}
  def random_fruit_size, do: :rand.uniform(@fruit_max_size - @fruit_min_size) + @fruit_min_size
  def random_fruit_type, do: @fruit_type_distribution
      |> Enum.flat_map(fn {type, qty} ->
        for _ <- 1..qty, do: type
      end)
      |> Enum.random()

  def random_fruit, do: {random_pos(), {random_fruit_size(), random_fruit_type()}}

  def register(%{players: players} = board, node, player) do
    case Map.get(players, node) do
      %{} = current_player -> %{board | players: Map.put(players, node, %{current_player | name: player.name, pid: player.pid})}
      _ -> %{board | players: Map.put(players, node, player)}
    end
  end

  def unregister(%{players: players} = board, node), do: %{board | players: Map.drop(players, [node])}

  def move(%{players: players} = board, node, target) do
    case Map.get(board.players, node) do
      nil -> board
      player -> %{board | players: %{players | node => %{player | target: target}}}
    end
  end

  def change_color(%{players: players} = board, node) do
    case Map.get(board.players, node) do
      nil -> board
      player -> %{board | players: %{players | node => %{player | color: Player.random_color()}}}
    end
  end

  def stop(%{players: players} = board, node) do
    case Map.get(board.players, node) do
      nil -> board
      player -> %{board | players: %{players | node => %{player | target: nil, status: :idle}}}
    end
  end

  def add_fruits(%{fruits: fruits} = board, count) do
    new_fruits = Map.new(for _ <- 1..count, do: random_fruit())
    %{board | fruits: Map.merge(fruits, new_fruits)}
  end

  def move_players(board) do
    players = board
    |> Map.get(:players)
    |> Enum.map(fn {node, player} -> {node, Player.move_player(player)} end)
    |> Map.new

    %{board | players: players}
  end

  def eat_fruits(board) do
    {players, fruits} = board
    |> Map.get(:players)
    |> Enum.reduce(
        {%{}, board.fruits},
        fn {node, %{pos: {px, py}, size: psize, score: score, velocity: velocity, powered: powered} = player}, {players, fruits} ->
          touching_fruits = Enum.filter(fruits, fn {{fx, fy}, {fsize, _}} ->
            x = abs(fx - px)
            y = abs(fy - py)
            ElixirMath.sqrt(x * x + y * y) <= fsize / 2 + psize / 2
          end)

          score_gain = touching_fruits
          |> Enum.map(fn {_, {size, _}} -> size end)
          |> Enum.sum

          velocity_gain = @velocity_gain_per_fruit * Enum.count(touching_fruits)
          size_gain = @size_gain_per_fruit * Enum.count(touching_fruits)

          powered_gain = touching_fruits
          |> Enum.filter(fn {_, {_, type}} -> type == :power_up end)
          |> Enum.map(fn {_, {size, _}} -> size * @powered_ticks_per_fruit_size end)
          |> Enum.sum()

          fruits_to_drop = Enum.map(touching_fruits, fn {pos, _} -> pos end)

          new_player = %{player |
            score: score + score_gain,
            velocity: velocity + velocity_gain,
            size: psize + size_gain,
            powered: Enum.min([powered + powered_gain, @max_powered])
          }

          {
            Map.put(players, node, new_player),
            Map.drop(fruits, fruits_to_drop)
          }
        end
      )


    %{board | fruits: fruits, players: players}
  end

  def maybe_generate_fruit(board), do: try_fruit_generation(board, :rand.uniform(100))

  defp try_fruit_generation(board, num) when num < @fruit_generated_probability, do:
    add_fruits(board, 1)

  defp try_fruit_generation(board, _), do: board

  def check_state(board) do
    checks = [
      &Player.check_target/1,
      &Player.check_x_borders/1,
      &Player.check_y_borders/1,
      &Player.decrease_power_up/1,
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
