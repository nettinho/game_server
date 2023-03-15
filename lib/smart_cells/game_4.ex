defmodule SmartCells.Game4 do
  use Kino.JS
  use Kino.JS.Live
  use Kino.SmartCell, name: "Game4"

  @impl true
  def init(_attrs, ctx) do
    {:ok, ctx}
  end

  @impl true
  def handle_connect(ctx) do
    {:ok, %{}, ctx}
  end

  @impl true
  def to_attrs(_ctx) do
    %{}
  end

  @impl true
  def to_source(_attrs) do
    quote do
      {:ok, server} =
        GameServer.start_link(:local, %{
          initial_fruits: [
            {500, 125, 20},
            {300, 125, 20, :power_up}
          ],
          initial_enemies: [
            {"enemy", %{pos_x: 600, pos_y: 200, size: 20, score: 5000}}
          ],
          powered_ticks_per_fruit_size: 50,
          max_powered: 10000,
          powered_velocity_bonus: 0,
          fruit_generated_probability: 0,
          success_func: fn %{players: players} ->
            {_, %{score: score, status: status}} =
              players
              |> Enum.find(fn {_, %{pid: pid}} -> is_nil(pid) end)

            score < 5000 and status == :idle
          end
        })

      SmartCells.KinoGame.new(server)
    end
    |> Kino.SmartCell.quoted_to_string()
  end

  asset "main.js" do
    """

    export function init(ctx, payload) {
      ctx.importCSS("https://unpkg.com/tailwindcss@2.2.19/dist/tailwind.min.css");

      root.innerHTML = `
      <div style="
      width: 100%;
      background: black;
      color: white;
          padding: 10px;
    ">

      <div style="
          width: 100%;
          height: 30px;
          border: 1px solid #333;
          background: white;
          color: #11b51f;
          font-weight: bolder;
          position: relative;
      "
      class="flex items-center justify-center"
      >
      <span class="text-lg font-mono">Evalúa la celda para activar el mapa</span>
    </div>
    </div>
      `;
    }
    """
  end
end

Kino.SmartCell.register(SmartCells.Game4)
