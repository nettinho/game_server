
export function init(ctx, assigns) {
  ctx.importCSS("main.css");
  
  fetch("main.html")
    .then(r => r.text())
    .then(html => mount(ctx, html, assigns))
    .catch(console.error)
}

function mount(ctx, html, attrs) {
  ctx.root.innerHTML = html



  ctx.handleEvent("board_tick", ({fruits, players, settings: {width, height}}) => {
    let newHtml = ""

    newHtml += `
            <div style="
            width: 100%;
            background: black;
            color: white;
                padding: 30px;
        ">

            <div style="
                width: ${width}px;
                height: ${height}px;
                border: 1px solid #333;
                background: black;
                position: relative;
            ">

    `

    newHtml += players
    .map(({
      color, name, pid, pos_x, pos_y, powered, size, status_timer, status
    }) => `
      <div id="${pid}" style="

      position: absolute;
      top: ${pos_y - size / 2}px;
      left: ${pos_x - size / 2}px;
      width: ${size}px;
      height: ${size}px;
      border: ${size / 5}px solid ${color};
      border-radius: 50%;
      display: flex;
      align-items: center;
      color: white;
      justify-content: center;
      font-size: ${2 * (size / 3)}px;

      ${
        status == ":digesting" && status_timer % 2 == 0 ? 
        `
        box-shadow:
        0 0 ${size / 2}px ${size / 3}px #fff,
        0 0 ${size / 1.5}px ${size / 2}px #ff0,
        0 0 ${size}px ${size}px #f0f;
        `
        : ""
      }
      ${
        status == ":fleeing" ? 
        `
        border: 2px solid grey;
        `
        : ""
      }
      ${
        powered > 0 ? 
        `
        box-shadow:
        0 0 ${size / 5}px ${size / 6}px #fff,
        0 0 ${size / 3}px ${size / 5}px #f0f,
        0 0 ${size / 2.15}px ${size / 3.5}px #0ff;
        `
        : ""
      }
      ">
        <span style="position: relative; bottom: -${size}px">${name}</span>
      </div>
    `).join("")

    newHtml += fruits
    .map(({size, pos_x: x, pos_y: y, type}) => `

    <div
      id={"fruit-${x}-${y}"}
      style="
      position: absolute;
      top: ${y - size / 2}px;
      left: ${x - size / 2}px;
      width: ${size}px;
      height: ${size}px;
      border: 4px solid gold;
      border-radius: 50%;
      ${
        type == ":power_up" ? 
        `
        box-shadow:
        inset 0 0 ${size / 6}px #fff,
        inset ${size / 15}px 0 ${size / 3.75}px #f0f,
        inset -${size / 15}px 0 ${size / 3.75}px #0ff,
        inset ${size / 15}px 0 ${size}px #f0f,
        inset -${size / 15}px 0 ${size}px #0ff,
        0 0 ${size / 6}px #fff,
        -${size / 30}px 0 ${size / 3.75}px #f0f,
        ${size / 30}px 0 ${size / 3.75}px #0ff;
        `
        : ""
      }


      "
    >
    </div>

    `).join("")

    newHtml += `
    </div>
</div>
    `


  ctx.root.innerHTML = newHtml
  });
}