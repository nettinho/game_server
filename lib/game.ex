defmodule Game do
  def register(server, name), do: GameServer.register(server, name)

  def unregister(server), do: GameServer.unregister(server)

  def move(server, target), do: GameServer.move(server, target)

  def change_color(server), do: GameServer.change_color(server)

  def stop(server), do: GameServer.stop(server)

  def view(server), do: GameServer.view(server)
end
