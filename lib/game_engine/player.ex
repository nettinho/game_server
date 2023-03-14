defmodule GameEngine.Player do

  @velocity 5

  def new(name, pid), do: %{
    name: name,
    pid: pid,
    pos: {250, 250},
    status: :idle,
    target: nil,
    points: 0
  }


  def move_player(%{target: nil} = player), do: player

  def move_player(%{target: {tx, ty}, pos: {px, py}} = player) do
    x = tx - px
    y = ty - py
    if x * x + y * y <= @velocity * @velocity do
      %{player | pos: {tx, ty}}
    else
      a = ElixirMath.atan2(y, x)

      dx = ElixirMath.cos(a) * @velocity
      dy = ElixirMath.sin(a) * @velocity

      %{player | pos: {px + dx, py + dy}}
    end
  end
end
