defmodule GameEngine.Player do
  alias GameEngine.Board

  @board_width Board.width()
  @board_height Board.height()

  @powered_velocity_bonus 0.02

  @player_colors [
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
  ]

  def new(name, pid),
    do: %{
      name: name,
      pid: pid,
      pos: {250, 250},
      status: :idle,
      status_timer: 0,
      target: nil,
      score: 0,
      velocity: 2,
      size: 16,
      color: random_color(),
      powered: 0
    }

  def random_color, do: Enum.random(@player_colors)

  def move_player(%{target: nil} = player), do: player
  def move_player(%{status: :digesting} = player), do: player

  def move_player(%{status: :fleeing, velocity: velocity} = player),
    do: do_move_player(player, velocity * 3, :fleeing)

  def move_player(%{velocity: velocity, powered: powered} = player),
    do: do_move_player(player, velocity + powered * @powered_velocity_bonus, :moving)

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

  def check_target(%{target: pos, pos: pos, status: :moving} = player),
    do: %{player | target: nil, status: :idle}

  def check_target(player), do: player

  def check_x_borders(%{pos: {x, y}} = player) when x > @board_width,
    do: %{player | target: nil, status: :idle, pos: {@board_width, y}}

  def check_x_borders(%{pos: {x, y}} = player) when x < 0,
    do: %{player | target: nil, status: :idle, pos: {0, y}}

  def check_x_borders(player), do: player

  def check_y_borders(%{pos: {x, y}} = player) when y > @board_height,
    do: %{player | target: nil, status: :idle, pos: {x, @board_height}}

  def check_y_borders(%{pos: {x, y}} = player) when y < 0,
    do: %{player | target: nil, status: :idle, pos: {x, 0}}

  def check_y_borders(player), do: player

  def decrease_power_up(%{powered: powered} = player) when powered > 0,
    do: %{player | powered: powered - 1}

  def decrease_power_up(player), do: %{player | powered: 0}

  def decrease_status_timer(%{status_timer: 1} = player),
    do: %{player | status_timer: 0, status: :idle, target: nil}

  def decrease_status_timer(%{status_timer: status_timer} = player) when status_timer > 1,
    do: %{player | status_timer: status_timer - 1}

  def decrease_status_timer(player), do: %{player | status_timer: 0}
end
