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
      {:ok, pid} =
        LocalGameServer.start_link(%{
          initial_fruit: {600, 125, 20},
          fruit_generated_probability: 0
        })

      # unquote(quoted_var("attrs["pid"]")) = unquote(Macro.escape(data))
      SmartCells.KinoGame.new(pid)
    end
    |> Kino.SmartCell.quoted_to_string()
  end

  asset "main.js" do
    """

    export function init(ctx, payload) {
      ctx.importCSS("https://unpkg.com/tailwindcss@2.2.19/dist/tailwind.min.css");

      root.innerHTML = `
        <h1>LEVEL 1</h1>
      `;
    }
    """
  end
end

Kino.SmartCell.register(SmartCells.Game1)

"""
const textEl = document.getElementById("text");
textEl.value = payload.text;

ctx.handleEvent("update_text", (text) => {
  textEl.value = text;
});

textEl.addEventListener("change", (event) => {
  ctx.pushEvent("update_text", event.target.value);
});

ctx.handleSync(() => {
  // Synchronously invokes change listeners
  document.activeElement &&
    document.activeElement.dispatchEvent(new Event("change"));
});
"""
