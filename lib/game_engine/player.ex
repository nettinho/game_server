defmodule GameEngine.Player do

  alias GameEngine.Board

  @board_width Board.width()
  @board_height Board.height()

  @powered_velocity_bonus 0.02

  @player_colors [
    "#a5d5ff", #blue
    "#a5ffaa", #green
    "#ffa5a5", #pink
    "#a8a5ff", #purple
    "#ffa5a5", #red
  ]

  def new(name, pid), do: %{
    name: name,
    pid: pid,
    pos: {250, 250},
    status: :idle,
    target: nil,
    score: 0,
    velocity: 2,
    size: 16,
    color: random_color(),
    powered: 0
  }

  def random_color, do: Enum.random(@player_colors)

  def move_player(%{target: nil} = player), do: player

  def move_player(%{target: {tx, ty}, pos: {px, py}, velocity: cur_velocity, powered: powered} = player) do
    velocity = cur_velocity + powered * @powered_velocity_bonus

    x = tx - px
    y = ty - py
    if x * x + y * y <= velocity * velocity do
      %{player | pos: {tx, ty}, status: :moving}
    else
      a = ElixirMath.atan2(y, x)

      dx = ElixirMath.cos(a) * velocity
      dy = ElixirMath.sin(a) * velocity

      %{player | pos: {px + dx, py + dy}, status: :moving}
    end
  end


  def check_target(%{target: pos, pos: pos, status: :moving} = player), do: %{player | target: nil, status: :idle}
  def check_target(player), do: player

  def check_x_borders(%{pos: {x, y}} = player) when x > @board_width, do: %{player | target: nil, status: :idle, pos: {@board_width, y}}
  def check_x_borders(%{pos: {x, y}} = player) when x < 0, do: %{player | target: nil, status: :idle, pos: {0, y}}
  def check_x_borders(player), do: player

  def check_y_borders(%{pos: {x, y}} = player) when y > @board_height, do: %{player | target: nil, status: :idle, pos: {x, @board_height}}
  def check_y_borders(%{pos: {x, y}} = player) when y < 0, do: %{player | target: nil, status: :idle, pos: {x, 0}}
  def check_y_borders(player), do: player

  def decrease_power_up(%{powered: powered} = player) when powered > 0, do: %{player | powered: powered - 1}
  def decrease_power_up(player), do: %{player | powered: 0}
end
