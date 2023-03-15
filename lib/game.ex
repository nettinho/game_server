defmodule Game do
  def register(server, name), do: GameServer.register(server, name)

  def unregister(server), do: GameServer.unregister(server)

  def move(server, target), do: GameServer.move(server, target)

  def change_color(server), do: GameServer.change_color(server)

  def stop(server), do: GameServer.stop(server)

  def view(server), do: GameServer.view(server)

  def state(server) do
    %{players: players, fruits: fruits} = GameServer.view(server)

    fruits = Enum.map(fruits, fn {pos, {size, type}} -> %{pos: pos, size: size, type: type} end)

    players =
      Enum.map(players, fn {_node, player} ->
        Map.take(player, [:name, :pos, :status, :status_timer, :score, :powered])
      end)

    %{players: players, fruits: fruits}
  end
end
