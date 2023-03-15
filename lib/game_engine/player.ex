defmodule GameEngine.Player do
  def new(
        name,
        pid,
        %{
          player_inital_x: player_inital_x,
          player_inital_y: player_inital_y,
          base_player_velocity: base_player_velocity,
          base_player_size: base_player_size
        } = settings,
        overrides \\ %{}
      ),
      do: %{
        name: name,
        pid: pid,
        pos: {
          Map.get(overrides, :pos_x, player_inital_x),
          Map.get(overrides, :pos_y, player_inital_y)
        },
        status: :idle,
        status_timer: 0,
        target: nil,
        score: Map.get(overrides, :score, 0),
        velocity: Map.get(overrides, :velocity, base_player_velocity),
        size: Map.get(overrides, :size, base_player_size),
        color: Map.get(overrides, :color, random_color(settings)),
        powered: 0
      }

  def random_color(%{player_colors: player_colors}), do: Enum.random(player_colors)

  def move_player(%{target: nil} = player, _), do: player
  def move_player(%{status: :digesting} = player, _), do: player

  def move_player(%{status: :fleeing, velocity: velocity} = player, _),
    do: do_move_player(player, velocity * 3, :fleeing)

  def move_player(%{velocity: velocity, powered: powered} = player, %{
        powered_velocity_bonus: powered_velocity_bonus
      }),
      do: do_move_player(player, velocity + powered * powered_velocity_bonus, :moving)

  def do_move_player(%{target: {tx, ty}, pos: {px, py}} = player, velocity, status) do
    x = tx - px
    y = ty - py

    if x * x + y * y <= velocity * velocity do
      %{player | pos: {tx, ty}, status: status}
    else
      a = ElixirMath.atan2(y, x)

      dx = ElixirMath.cos(a) * velocity
      dy = ElixirMath.sin(a) * velocity

      %{player | pos: {px + dx, py + dy}, status: status}
    end
  end

  def check_target(%{target: pos, pos: pos, status: :moving} = player, _),
    do: %{player | target: nil, status: :idle}

  def check_target(player, _), do: player

  def check_x_borders(%{pos: {x, y}} = player, %{width: width}) when x > width,
    do: %{player | target: nil, status: :idle, pos: {width, y}}

  def check_x_borders(%{pos: {x, y}} = player, _) when x < 0,
    do: %{player | target: nil, status: :idle, pos: {0, y}}

  def check_x_borders(player, _), do: player

  def check_y_borders(%{pos: {x, y}} = player, %{height: height}) when y > height,
    do: %{player | target: nil, status: :idle, pos: {x, height}}

  def check_y_borders(%{pos: {x, y}} = player, _) when y < 0,
    do: %{player | target: nil, status: :idle, pos: {x, 0}}

  def check_y_borders(player, _), do: player

  def decrease_power_up(%{powered: powered} = player, _) when powered > 0,
    do: %{player | powered: powered - 1}

  def decrease_power_up(player, _), do: %{player | powered: 0}

  def decrease_status_timer(%{status_timer: 1} = player, _),
    do: %{player | status_timer: 0, status: :idle, target: nil}

  def decrease_status_timer(%{status_timer: status_timer} = player, _) when status_timer > 1,
    do: %{player | status_timer: status_timer - 1}

  def decrease_status_timer(player, _), do: %{player | status_timer: 0}
end
