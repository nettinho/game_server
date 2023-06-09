defmodule SmartCells.Game1 do
  use Kino.JS
  use Kino.JS.Live
  use Kino.SmartCell, name: "Game1"

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
          initial_fruit: {600, 125, 20},
          fruit_generated_probability: 0,
          success_func: fn %{fruits: fruits} -> Enum.empty?(fruits) end
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

Kino.SmartCell.register(SmartCells.Game1)
