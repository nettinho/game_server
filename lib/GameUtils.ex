defmodule GameUtils do
  def distance({x1, y1}, {x2, y2}), do: ElixirMath.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)

  def closest_fruit(_player, fruits) when fruits == %{}, do: nil

  def closest_fruit(%{pos: ppos} = player, fruits) do
    IO.inspect(player, label: "closest_fruit")

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
