defmodule GameEngine.Board do
  alias GameEngine.Player

  @board_default_settings %{
    width: 1250,
    height: 750,
    fruit_min_size: 5,
    fruit_max_size: 25,
    fruit_type_distribution: [
      {:default, 4},
      {:power_up, 1}
    ],
    fruit_generated_probability: 10,
    powered_ticks_per_fruit_size: 5,
    max_powered: 250,
    powered_velocity_bonus: 0.02,
    base_player_velocity: 2,
    base_player_size: 16,
    fleeing_ticks: 25,
    digesting_ticks: 25,
    player_colors: [
      # blue
      "#a5d5ff",
      # green
      "#a5ffaa",
      # pink
      "#ffa5a5",
      # purple
      "#a8a5ff",
      # red
      "#ffa5a5"
    ],
    player_inital_x: 625,
    player_inital_y: 325,
    initial_fruits_count: 10,
    initial_fruit: nil,
    initial_fruits: nil,
    initial_enemies: nil,
    success_func: nil,
    failure_func: nil,
    broadcast_pub_sub: true,
    local_receiver: nil
  }

  def new(settings \\ %{}) do
    settings = Map.merge(@board_default_settings, settings)

    %{
      players: initial_enemies(settings),
      fruits: initial_fruits(settings),
      settings: settings
    }
  end

  defp initial_enemies(%{initial_enemies: [_ | _] = enemies} = settings),
    do:
      enemies
      |> Enum.map(fn
        {name, override} -> {name, Player.new(name, nil, settings, override)}
      end)
      |> Map.new()

  defp initial_enemies(_), do: %{}

  defp initial_fruits(%{initial_fruit: {x, y, size, type}}), do: %{{x, y} => {size, type}}
  defp initial_fruits(%{initial_fruit: {x, y, size}}), do: %{{x, y} => {size, :default}}

  defp initial_fruits(%{initial_fruits: [_ | _] = fruits}),
    do:
      fruits
      |> Enum.map(fn
        {x, y, size, type} -> {{x, y}, {size, type}}
        {x, y, size} -> {{x, y}, {size, :default}}
      end)
      |> Map.new()

  defp initial_fruits(%{initial_fruits_count: initial_fruits} = settings) when initial_fruits > 0,
    do: Map.new(for _ <- 1..initial_fruits, do: random_fruit(settings))

  defp initial_fruits(_), do: %{}

  def random_pos(%{width: width, height: height}),
    do: {:rand.uniform(width), :rand.uniform(height)}

  def random_fruit_size(%{fruit_max_size: fruit_max_size, fruit_min_size: fruit_min_size}),
    do: :rand.uniform(fruit_max_size - fruit_min_size) + fruit_min_size

  def random_fruit_type(%{fruit_type_distribution: fruit_type_distribution}),
    do:
      fruit_type_distribution
      |> Enum.flat_map(fn {type, qty} ->
        for _ <- 1..qty, do: type
      end)
      |> Enum.random()

  def random_fruit(settings),
    do: {random_pos(settings), {random_fruit_size(settings), random_fruit_type(settings)}}

  def register(%{players: players} = board, node, player) do
    case Map.get(players, node) do
      %{} = current_player ->
        %{
          board
          | players:
              Map.put(players, node, %{current_player | name: player.name, pid: player.pid})
        }

      _ ->
        %{board | players: Map.put(players, node, player)}
    end
  end

  def unregister(%{players: players} = board, node),
    do: %{board | players: Map.drop(players, [node])}

  def move(%{players: players} = board, node, target) do
    case Map.get(board.players, node) do
      nil -> board
      %{status: status} when status in [:digesting, :fleeing] -> board
      player -> %{board | players: %{players | node => %{player | target: target}}}
    end
  end

  def change_color(%{players: players, settings: settings} = board, node) do
    case Map.get(board.players, node) do
      nil ->
        board

      player ->
        %{board | players: %{players | node => %{player | color: Player.random_color(settings)}}}
    end
  end

  def stop(%{players: players} = board, node) do
    case Map.get(board.players, node) do
      nil -> board
      player -> %{board | players: %{players | node => %{player | target: nil, status: :idle}}}
    end
  end

  def add_fruits(%{fruits: fruits, settings: settings} = board, count) do
    new_fruits = Map.new(for _ <- 1..count, do: random_fruit(settings))
    %{board | fruits: Map.merge(fruits, new_fruits)}
  end

  def move_players(%{settings: settings} = board) do
    players =
      board
      |> Map.get(:players)
      |> Enum.map(fn {node, player} -> {node, Player.move_player(player, settings)} end)
      |> Map.new()

    %{board | players: players}
  end

  def eat_fruits(%{settings: settings} = board) do
    %{
      powered_ticks_per_fruit_size: powered_ticks_per_fruit_size,
      base_player_velocity: base_player_velocity,
      base_player_size: base_player_size,
      max_powered: max_powered
    } = settings

    {players, fruits} =
      board
      |> Map.get(:players)
      |> Enum.reduce(
        {%{}, board.fruits},
        fn {node, %{pos: {px, py}, size: psize, score: score, powered: powered} = player},
           {players, fruits} ->
          touching_fruits =
            Enum.filter(fruits, fn {{fx, fy}, {fsize, _}} ->
              x = abs(fx - px)
              y = abs(fy - py)
              ElixirMath.sqrt(x * x + y * y) <= fsize / 2 + psize / 2
            end)

          score_gain =
            touching_fruits
            |> Enum.map(fn {_, {size, _}} -> size end)
            |> Enum.sum()

          new_score = score + score_gain

          powered_gain =
            touching_fruits
            |> Enum.filter(fn {_, {_, type}} -> type == :power_up end)
            |> Enum.map(fn {_, {size, _}} -> size * powered_ticks_per_fruit_size end)
            |> Enum.sum()

          fruits_to_drop = Enum.map(touching_fruits, fn {pos, _} -> pos end)

          new_player = %{
            player
            | score: new_score,
              velocity: ElixirMath.log10(new_score + 10) * base_player_velocity,
              size: ElixirMath.log10(new_score + 10) * base_player_size,
              powered: Enum.min([powered + powered_gain, max_powered])
          }

          {
            Map.put(players, node, new_player),
            Map.drop(fruits, fruits_to_drop)
          }
        end
      )

    %{board | fruits: fruits, players: players}
  end

  def players_fight(%{players: players, settings: settings} = board) do
    new_players =
      players
      |> Enum.reduce(%{}, fn {node, %{pos: {px, py}, size: psize}} = player, calculated_players ->
        if Map.has_key?(calculated_players, node) do
          calculated_players
        else
          players
          |> Enum.reject(fn {t_node, _} ->
            Map.has_key?(calculated_players, t_node) or t_node == node
          end)
          |> Enum.find(fn {_, %{pos: {tx, ty}, size: tsize}} ->
            x = abs(tx - px)
            y = abs(ty - py)
            ElixirMath.sqrt(x * x + y * y) <= tsize / 2 + psize / 2
          end)
          |> try_battle(player, settings)
          |> Map.merge(calculated_players)
        end
      end)

    %{board | players: new_players}
  end

  defp try_battle(nil, {node, player}, _), do: %{node => player}

  defp try_battle(
         {_, %{powered: p_l_powered}} = p_l,
         {_, %{powered: p_w_powered}} = p_w,
         settings
       )
       when p_l_powered == 0 and p_w_powered > 0,
       do: do_battle(p_l, p_w, settings)

  defp try_battle(
         {_, %{powered: p_w_powered}} = p_w,
         {_, %{powered: p_l_powered}} = p_l,
         settings
       )
       when p_l_powered == 0 and p_w_powered > 0,
       do: do_battle(p_l, p_w, settings)

  defp try_battle({p1_node, p1}, {p2_node, p2}, _) do
    %{
      p1_node => p1,
      p2_node => p2
    }
  end

  defp do_battle(
         {p_l_node, %{pos: {plx, ply}, score: p_l_score} = p_l},
         {p_w_node, %{pos: {pwx, pwy}, score: p_w_score} = p_w},
         %{
           width: width,
           height: height,
           fleeing_ticks: fleeing_ticks,
           digesting_ticks: digesting_ticks
         }
       ) do
    steal_amount = round(p_l_score / 2)

    flee_x = if plx < pwx, do: 0, else: width
    flee_y = if ply < pwy, do: 0, else: height

    %{
      p_l_node => %{
        p_l
        | status: :fleeing,
          status_timer: fleeing_ticks,
          target: {flee_x, flee_y},
          score: p_l_score - steal_amount
      },
      p_w_node => %{
        p_w
        | status: :digesting,
          status_timer: digesting_ticks,
          score: p_w_score + steal_amount
      }
    }
  end

  def maybe_generate_fruit(board), do: try_fruit_generation(board, :rand.uniform(100))

  defp try_fruit_generation(
         %{settings: %{fruit_generated_probability: fruit_generated_probability}} = board,
         num
       )
       when num < fruit_generated_probability,
       do: add_fruits(board, 1)

  defp try_fruit_generation(board, _), do: board

  def check_state(%{settings: settings} = board) do
    checks = [
      &Player.check_target/2,
      &Player.check_x_borders/2,
      &Player.check_y_borders/2,
      &Player.decrease_power_up/2,
      &Player.decrease_status_timer/2
    ]

    players =
      board
      |> Map.get(:players)
      |> Enum.map(fn {pid, player} ->
        {pid, Enum.reduce(checks, player, fn fun, p -> fun.(p, settings) end)}
      end)
      |> Map.new()

    %{board | players: players}
  end

  def position_player(board, coordinate, player) do
    players_at_position = Map.get(board, coordinate, MapSet.new())
    Map.put(board, coordinate, MapSet.put(players_at_position, player))
  end
end
