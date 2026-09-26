// Generates the front garden art (background, light layer, furniture). The SVG files are the editable source;
// re-running this overwrites them:  node tools/art/front_garden.mjs
// The front garden is "where it began" (docs/STORY.md): Rose's roses, the letterbox, the old pine with
// the swing, the chalk hopscotch, and the gate at the end of the path. The street runs down to the beach,
// and the sun comes up right above the gate.
import { save, svg, roomSvg, lightLayer, rng, number } from "./room_kit.mjs";

const FENCE_TOP = 470;
const FENCE_BOTTOM = 610;
const GATE = [860, 450, 200, 160];

const houses = () => {
  const specs = [
    [-240, 300, 200, "#f9b98a", "#c8674a"], [-40, 330, 180, "#fcd9b8", "#a8554a"], [140, 290, 170, "#c9bde3", "#7c6ab0"],
    [310, 340, 160, "#fff4e2", "#c8674a"], [470, 360, 140, "#b7cfc8", "#5e7f5e"], [610, 390, 120, "#f3ddb3", "#a8554a"],
    [1190, 390, 120, "#fcd9b8", "#7c6ab0"], [1310, 360, 140, "#fff4e2", "#c8674a"], [1450, 330, 170, "#b7cfc8", "#2e8c8c"],
    [1620, 300, 190, "#f9b98a", "#a8554a"], [1810, 320, 200, "#c9bde3", "#5e7f5e"], [2010, 290, 200, "#fcd9b8", "#c8674a"],
  ];
  const r = rng(8);
  return specs.map(([x, top, w, wall, roof]) => {
    const h = 520 - top;
    let s = `<rect x="${x}" y="${top}" width="${w}" height="${h}" fill="${wall}"/><path d="M${x - 8} ${top} L${x + w / 2} ${top - 40 - w * 0.12} L${x + w + 8} ${top} Z" fill="${roof}"/>`;
    for (let wy = top + 20; wy < 500; wy += 50) for (let wx = x + 16; wx < x + w - 24; wx += 42) {
      s += `<rect x="${wx}" y="${wy}" width="20" height="26" rx="3" fill="${r() < 0.3 ? "#fbe3a0" : "#3e3570"}" opacity="0.8"/>`;
    }
    return s;
  }).join("");
};

const pickets = () => {
  const out = [];
  for (let x = -240; x < 2160; x += 46) {
    if (x > GATE[0] - 40 && x < GATE[0] + GATE[2]) continue;
    out.push(`<path d="M${x} ${FENCE_BOTTOM} V${FENCE_TOP + 16} L${x + 16} ${FENCE_TOP} L${x + 32} ${FENCE_TOP + 16} V${FENCE_BOTTOM} Z" fill="#fffbf5"/><rect x="${x + 24}" y="${FENCE_TOP + 16}" width="8" height="${FENCE_BOTTOM - FENCE_TOP - 16}" fill="#e9dcc2"/>`);
  }
  return out.join("");
};

const bg = roomSvg(`  <defs>
    <linearGradient id="lawn" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#a9c79a"/><stop offset="1" stop-color="#86ab78"/></linearGradient>
    <linearGradient id="street" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#d9c6a6"/><stop offset="1" stop-color="#c2ab88"/></linearGradient>
    <linearGradient id="groundShade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3b2e3a" stop-opacity="0.1"/><stop offset="0.4" stop-color="#3b2e3a" stop-opacity="0"/><stop offset="1" stop-color="#3b2e3a" stop-opacity="0.14"/></linearGradient>
  </defs>
  <!-- the street along the fence (seen between the pickets) -->
  <rect x="-240" y="512" width="2400" height="100" fill="#d9c6a6"/>
  <rect x="-240" y="512" width="2400" height="14" fill="#e9dcc2"/>
  <!-- the beach at the end of the street, and the street going down to it -->
  <rect x="700" y="428" width="520" height="30" fill="#f3ddb3"/>
  <path d="M640 530 L1280 530 L1010 446 L910 446 Z" fill="url(#street)"/>
  <path d="M958 446 L962 446 L990 530 L930 530 Z" fill="#fffbf5" opacity="0.4"/>
  ${houses()}
  <!-- the market around the corner: striped awnings -->
  ${[0, 1, 2, 3].map((i) => `<path d="M${650 + i * 30} 452 L${680 + i * 30} 452 L${680 + i * 30} 468 L${650 + i * 30} 468 Z" fill="${i % 2 ? "#fffbf5" : "#ee7b6b"}"/>`).join("")}
  ${[0, 1, 2].map((i) => `<path d="M${1170 + i * 26} 456 L${1196 + i * 26} 456 L${1196 + i * 26} 470 L${1170 + i * 26} 470 Z" fill="${i % 2 ? "#fffbf5" : "#2e8c8c"}"/>`).join("")}
  <!-- street lamps -->
  <rect x="700" y="400" width="6" height="130" fill="#3e3570"/><circle cx="703" cy="398" r="9" fill="#fbe3a0"/>
  <rect x="1214" y="400" width="6" height="130" fill="#3e3570"/><circle cx="1217" cy="398" r="9" fill="#fbe3a0"/>
  <!-- front garden lawn and path -->
  <rect x="-240" y="${FENCE_BOTTOM - 20}" width="2400" height="${1260 - FENCE_BOTTOM + 20}" fill="url(#lawn)"/>
  <path d="M870 ${FENCE_BOTTOM} L1050 ${FENCE_BOTTOM} L1310 1260 L610 1260 Z" fill="#e9dcc2"/>
  ${[0, 1, 2, 3, 4, 5].map((i) => { const y = 640 + i * 105, t = (y - FENCE_BOTTOM) / (1260 - FENCE_BOTTOM), l = 870 - 260 * t, rr = 1050 + 260 * t; return `<path d="M${l.toFixed(0)} ${y} L${rr.toFixed(0)} ${y}" stroke="#cdb996" stroke-width="5"/>`; }).join("")}
  <rect x="-240" y="${FENCE_BOTTOM - 20}" width="2400" height="${1260 - FENCE_BOTTOM + 20}" fill="url(#groundShade)"/>
  <!-- the white picket fence and the garden gate -->
  <rect x="-240" y="${FENCE_TOP + 40}" width="2400" height="12" fill="#fffbf5"/><rect x="-240" y="${FENCE_BOTTOM - 40}" width="2400" height="12" fill="#fffbf5"/>
  ${pickets()}
  <rect x="${GATE[0] - 30}" y="${GATE[1] - 30}" width="26" height="${GATE[3] + 30}" rx="4" fill="#fffbf5"/><circle cx="${GATE[0] - 17}" cy="${GATE[1] - 34}" r="14" fill="#fffbf5"/>
  <rect x="${GATE[0] + GATE[2] + 4}" y="${GATE[1] - 30}" width="26" height="${GATE[3] + 30}" rx="4" fill="#fffbf5"/><circle cx="${GATE[0] + GATE[2] + 17}" cy="${GATE[1] - 34}" r="14" fill="#fffbf5"/>
  <path d="M${GATE[0]} ${GATE[1] + GATE[3]} V${GATE[1] + 30} Q${GATE[0] + GATE[2] / 2} ${GATE[1] - 10} ${GATE[0] + GATE[2]} ${GATE[1] + 30} V${GATE[1] + GATE[3]} Z" fill="none" stroke="#fffbf5" stroke-width="10"/>
  ${[1, 2, 3, 4, 5, 6].map((i) => `<rect x="${GATE[0] + i * 28 - 5}" y="${GATE[1] + 26 - Math.sin((i / 7) * Math.PI) * 30}" width="10" height="${GATE[3] - 26 + Math.sin((i / 7) * Math.PI) * 30}" rx="4" fill="#fffbf5"/>`).join("")}
  <rect x="${GATE[0]}" y="${GATE[1] + 80}" width="${GATE[2]}" height="10" fill="#fffbf5"/>
  <circle cx="${GATE[0] + GATE[2] - 20}" cy="${GATE[1] + 90}" r="8" fill="#d4a24c"/>`, "Front garden background: the street down to the beach (sea and sky are transparent), neighbours' houses, the market awnings, the picket fence with the gate.");
save("rooms/front_garden_bg.svg", bg);

save("rooms/front_garden_light.svg", lightLayer(
  ["760,-180 1160,-180 1400,1260 520,1260"],
  [[960, 900, 520, 150, 1], [960, 620, 300, 60, 0.7]],
  "Golden morning light pouring through the gate and down the path."));

// ---------------------------------------------------------------- furniture
const shadow = (cx, cy, rx, ry, op = 0.18) => `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="#3b2e3a" opacity="${op}"/>`;

const rose = (x, y, s, c) => `<circle cx="${x}" cy="${y}" r="${14 * s}" fill="${c}"/><path d="M${x - 6 * s} ${y} Q${x} ${y - 9 * s} ${x + 6 * s} ${y} Q${x} ${y + 7 * s} ${x - 6 * s} ${y} Z" fill="#c95b52" opacity="0.7"/>`;
save("props/front_garden/roses.svg", svg(430, 280, `  ${shadow(215, 268, 200, 10)}
  <ellipse cx="110" cy="160" rx="110" ry="100" fill="#5e7f5e"/><ellipse cx="300" cy="150" rx="130" ry="110" fill="#5e7f5e"/>
  <ellipse cx="120" cy="140" rx="90" ry="80" fill="#6f9468"/><ellipse cx="300" cy="130" rx="110" ry="90" fill="#6f9468"/>
  ${[[60, 110, "#ee7b6b"], [130, 80, "#f9b98a"], [170, 150, "#ee7b6b"], [90, 190, "#fcd9b8"], [250, 90, "#ee7b6b"], [320, 70, "#fcd9b8"], [380, 130, "#ee7b6b"], [290, 170, "#f9b98a"], [220, 200, "#ee7b6b"], [350, 200, "#ee7b6b"]].map(([x, y, c]) => rose(x, y, 1.1, c)).join("")}
  <path d="M0 250 C80 236 350 236 430 250 L430 280 L0 280 Z" fill="#6b4a36"/>`, "Rose's rose bushes by the front fence, coral and peach roses; soft soil at their feet."));

save("props/front_garden/letterbox.svg", svg(120, 270, `  ${shadow(60, 262, 40, 6)}
  <rect x="50" y="90" width="20" height="176" fill="#7a5134"/>
  <path d="M10 40 C10 10 110 10 110 40 L110 100 L10 100 Z" fill="#2e8c8c"/>
  <path d="M10 40 C10 16 110 16 110 40" stroke="#6cc2be" stroke-width="6" fill="none"/>
  <rect x="24" y="48" width="72" height="12" rx="6" fill="#1f5f6b"/>
  <rect x="44" y="70" width="32" height="20" rx="4" fill="#d4a24c"/>
  <path d="M110 52 L126 52 L126 22 L140 26 L126 34" stroke="#ee7b6b" stroke-width="6" fill="none" stroke-linejoin="round" transform="translate(-24 0)"/>
  <!-- the house number -->
  <rect x="34" y="112" width="52" height="30" rx="4" fill="#fffbf5"/>
  ${number(12, 44, 117, 20, "#3e3570", 3)}`, "Teal letterbox on a post, with the house number 12 and a little coral flag."));

// The old pine with Céline's swing.
save("props/front_garden/pine.svg", svg(460, 820, `  ${shadow(230, 806, 150, 14, 0.22)}
  <path d="M200 810 C196 600 190 400 206 180 L246 180 C252 400 250 600 262 810 Z" fill="#7a5134"/>
  <path d="M210 800 C208 600 206 420 214 220" stroke="#a8744a" stroke-width="8" fill="none" opacity="0.6"/>
  <path d="M230 330 C300 300 360 300 430 320" stroke="#7a5134" stroke-width="22" fill="none" stroke-linecap="round"/>
  <ellipse cx="230" cy="120" rx="210" ry="110" fill="#3f6a52"/><ellipse cx="160" cy="200" rx="150" ry="70" fill="#4f7a5e"/>
  <ellipse cx="330" cy="200" rx="130" ry="64" fill="#4f7a5e"/><ellipse cx="230" cy="70" rx="130" ry="60" fill="#5e8a68"/>
  <ellipse cx="400" cy="300" rx="70" ry="36" fill="#4f7a5e"/>
  <!-- hollow in the trunk -->
  <ellipse cx="226" cy="520" rx="18" ry="30" fill="#3b2e3a"/><ellipse cx="226" cy="520" rx="12" ry="24" fill="#5e3e28"/>
  <!-- the swing -->
  <path d="M330 318 L330 620 M410 322 L410 620" stroke="#e9dcc2" stroke-width="5"/>
  <rect x="316" y="614" width="110" height="18" rx="6" fill="#c8674a"/><rect x="316" y="614" width="110" height="5" rx="2" fill="#e08e6d"/>`, "The old pine with a hollow in its trunk and Céline's childhood swing hanging from a branch."));

save("props/front_garden/bench.svg", svg(300, 170, `  ${shadow(150, 162, 140, 8)}
  <rect x="20" y="20" width="260" height="16" rx="6" fill="#2e8c8c"/><rect x="20" y="46" width="260" height="16" rx="6" fill="#2e8c8c"/>
  <rect x="10" y="80" width="280" height="20" rx="6" fill="#35999a"/><rect x="10" y="80" width="280" height="6" rx="3" fill="#6cc2be"/>
  <path d="M30 20 L30 160 M270 20 L270 160" stroke="#1f5f6b" stroke-width="10" stroke-linecap="round"/>
  <path d="M60 100 L50 160 M240 100 L250 160" stroke="#1f5f6b" stroke-width="8" stroke-linecap="round"/>`, "A teal garden bench by the fence."));

// Chalk hopscotch on the path, numbered 1-8 like the one little Céline drew.
const hop = [];
const cells = [[1, 0, 0], [2, 0, 1], [3, -0.5, 2], [4, 0.5, 2], [5, 0, 3], [6, -0.5, 4], [7, 0.5, 4], [8, 0, 5]];
for (const [n, col, rowi] of cells) {
  const y = 250 - rowi * 44, s = 1 - rowi * 0.07, w = 90 * s, h = 42 * s;
  const cx = 200 + col * w;
  hop.push(`<rect x="${(cx - w / 2).toFixed(1)}" y="${(y - h).toFixed(1)}" width="${w.toFixed(1)}" height="${h.toFixed(1)}" fill="none" stroke="#fffbf5" stroke-width="4" opacity="0.9"/>${number(n, cx - 6 * s, y - h + 8 * s, 24 * s, "#fffbf5", 3)}`);
}
save("props/front_garden/hopscotch.svg", svg(400, 280, `  ${hop.join("\n  ")}
  <circle cx="200" cy="0" r="0" fill="none"/>
  <path d="M300 250 C310 240 330 244 330 256" stroke="#f9b98a" stroke-width="4" fill="none" opacity="0.8"/>
  <circle cx="310" cy="262" r="8" fill="#f6c453"/>`, "Chalk hopscotch on the path, squares numbered 1 to 8, with a stone and a bit of chalk."));

console.log("front garden art written");
