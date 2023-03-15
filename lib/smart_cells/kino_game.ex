defmodule SmartCells.KinoGame do
  use Kino.JS, assets_path: "assets/game"
  use Kino.JS.Live

  def new(pid) do
    Kino.JS.Live.new(__MODULE__, pid)
  end

  @impl true
  def init(pid, ctx) do
    GameServer.set_local_receiver(pid, self())
    {:ok, assign(ctx, %{})}
  end

  @impl true
  def handle_connect(ctx) do
    {:ok, ctx.assigns, ctx}
  end

  @impl true
  def handle_info(
        {:board_tick,
         %{fruits: fruits, players: players, settings: %{width: width, height: heigth}}},
        ctx
      ) do
    fruits =
      Enum.map(fruits, fn {{px, py}, {size, type}} ->
        %{pos_x: px, pos_y: py, size: size, type: inspect(type)}
      end)

    players =
      Enum.map(players, fn {_,
                            %{
                              color: color,
                              name: name,
                              pid: pid,
                              pos: {px, py},
                              powered: powered,
                              size: size,
                              status_timer: status_timer,
                              status: status
                            }} ->
        %{
          pos_x: px,
          pos_y: py,
          size: size,
          name: name,
          pid: inspect(pid),
          powered: powered,
          color: color,
          status_timer: status_timer,
          status: status
        }
      end)

    broadcast_event(ctx, "board_tick", %{
      fruits: fruits,
      players: players,
      settings: %{width: width, height: heigth}
    })

    {:noreply, ctx}
  end

  @impl true
  def handle_info(
        {:success, %{settings: %{width: width, height: heigth}}},
        ctx
      ) do
    broadcast_event(ctx, "success", %{
      settings: %{width: width, height: heigth}
    })

    {:noreply, ctx}
  end

  @impl true
  def handle_info(
        {:failure, %{settings: %{width: width, height: heigth}}},
        ctx
      ) do
    broadcast_event(ctx, "failure", %{
      settings: %{width: width, height: heigth}
    })

    {:noreply, ctx}
  end
end
