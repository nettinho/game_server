defmodule GameUtils do
  def distance({x1, y1}, {x2, y2}) do
    x = x1 - x2
    y = y1 - y2
    ElixirMath.sqrt(x * x + y * y)
  end

  def closest_fruit(_player, fruits) when fruits == %{}, do: nil

  def closest_fruit(%{pos: ppos} = _player, fruits) do
    fruits
    |> Enum.map(fn {fpos, _} -> {fpos, distance(ppos, fpos)} end)
    |> Enum.min_by(fn {_pos, dist} -> dist end)
    |> then(fn {pos, _} -> pos end)
  end

  def closest_power_up(player, fruits) do
    power_ups =
      fruits
      |> Enum.filter(fn {_, {_, type}} -> type == :power_up end)
      |> Map.new()

    closest_fruit(player, power_ups)
  end
end
