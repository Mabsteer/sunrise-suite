// Generates the shed art (background, light layer, furniture). The SVG files are the editable source;
// re-running this overwrites them:  node tools/art/shed.mjs
// The shed is "the girl at the flower stall" (docs/STORY.md): Rose's old flower cart, the scales,
// Céline's delivery bicycle, her father's tools on the pegboard.
import { save, svg, roomSvg, woodFloor, wallWithHoles, frame, lightLayer, rng } from "./room_kit.mjs";

const FLOOR_Y = 780;
const WINDOW = [300, 160, 220, 190];
const EXIT = [1660, 200, 220, 580];

// Vertical planks, cut around the window hole (no clipping allowed in the SVGs).
const planks = () => {
  const r = rng(17);
  const out = [];
  const [wx, wy, ww, wh] = WINDOW;
  const col = (x, w, fill, op = 1) => {
    const overlaps = x + w > wx && x < wx + ww;
    const o = op < 1 ? ` opacity="${op}"` : "";
    if (!overlaps) return `<rect x="${x}" y="60" width="${w}" height="${FLOOR_Y - 60}" fill="${fill}"${o}/>`;
    let s = `<rect x="${x}" y="60" width="${w}" height="${wy - 60}" fill="${fill}"${o}/><rect x="${x}" y="${wy + wh}" width="${w}" height="${FLOOR_Y - wy - wh}" fill="${fill}"${o}/>`;
    if (x < wx) s += `<rect x="${x}" y="${wy}" width="${wx - x}" height="${wh}" fill="${fill}"${o}/>`;
    if (x + w > wx + ww) s += `<rect x="${wx + ww}" y="${wy}" width="${x + w - wx - ww}" height="${wh}" fill="${fill}"${o}/>`;
    return s;
  };
  for (let x = -240; x < 2160; x += 64) {
    const c = ["#a8744a", "#9c6a42", "#b07b50", "#a06f46"][Math.floor(r() * 4)];
    out.push(col(x, 62, c), col(x + 62, 2, "#5e3e28", 0.5));
    const kx = x + 20 + r() * 20, ky = 150 + r() * 500;
    if (r() < 0.5 && !(kx > wx - 10 && kx < wx + ww + 10 && ky > wy - 10 && ky < wy + wh + 10)) out.push(`<circle cx="${kx.toFixed(0)}" cy="${ky.toFixed(0)}" r="4" fill="#7a5134" opacity="0.6"/>`);
  }
  return out.join("");
};

const bg = roomSvg(`  <defs>
    <linearGradient id="floorShade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3b2e3a" stop-opacity="0.3"/><stop offset="0.35" stop-color="#3b2e3a" stop-opacity="0.05"/><stop offset="1" stop-color="#3b2e3a" stop-opacity="0.25"/></linearGradient>
    <linearGradient id="wallShade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3b2e3a" stop-opacity="0.35"/><stop offset="0.4" stop-color="#3b2e3a" stop-opacity="0"/></linearGradient>
  </defs>
  <rect x="-240" y="-180" width="2400" height="250" fill="#6f4f38"/>
  ${[-240, 160, 560, 960, 1360, 1760].map((x) => `<rect x="${x}" y="-180" width="40" height="250" fill="#5e3e28"/>`).join("")}
  <rect x="-240" y="40" width="2400" height="26" fill="#7a5134"/>
  <g>
  ${woodFloor(FLOOR_Y, 1260, ["#8a6446", "#7f5b3f", "#94694a", "#86603f"], "#4a3426", 13)}
  </g>
  <rect x="-240" y="${FLOOR_Y}" width="2400" height="480" fill="url(#floorShade)"/>
  ${planks()}
  ${wallWithHoles(-240, 60, 2160, FLOOR_Y, [WINDOW], "url(#wallShade)").replace("<path ", '<path opacity="0.6" ')}
  <!-- small dusty window with a cobweb -->
  ${frame(WINDOW, 16, "#c99a6b", "#a8744a")}
  <rect x="${WINDOW[0] + WINDOW[2] / 2 - 6}" y="${WINDOW[1]}" width="12" height="${WINDOW[3]}" fill="#c99a6b"/>
  <rect x="${WINDOW[0]}" y="${WINDOW[1] + WINDOW[3] / 2 - 6}" width="${WINDOW[2]}" height="12" fill="#c99a6b"/>
  <path d="M${WINDOW[0]} ${WINDOW[1]} L${WINDOW[0] + 60} ${WINDOW[1] + 50} M${WINDOW[0]} ${WINDOW[1] + 30} Q${WINDOW[0] + 26} ${WINDOW[1] + 26} ${WINDOW[0] + 30} ${WINDOW[1]} M${WINDOW[0]} ${WINDOW[1] + 50} Q${WINDOW[0] + 44} ${WINDOW[1] + 44} ${WINDOW[0] + 50} ${WINDOW[1]}" stroke="#fffbf5" stroke-width="1.5" opacity="0.6" fill="none"/>
  <rect x="${WINDOW[0] - 26}" y="${WINDOW[1] + WINDOW[3] + 14}" width="${WINDOW[2] + 52}" height="16" rx="4" fill="#c99a6b"/>
  <!-- the side door to the front garden -->
  <rect x="${EXIT[0] - 16}" y="${EXIT[1] - 16}" width="${EXIT[2] + 32}" height="${EXIT[3] + 16}" fill="#6f4f38"/>
  <rect x="${EXIT[0]}" y="${EXIT[1]}" width="${EXIT[2]}" height="${EXIT[3]}" fill="#2e8c8c"/>
  ${[0, 1, 2, 3].map((i) => `<rect x="${EXIT[0] + 8 + i * 52}" y="${EXIT[1] + 8}" width="46" height="${EXIT[3] - 16}" rx="3" fill="#35999a"/>`).join("")}
  <path d="M${EXIT[0] + 10} ${EXIT[1] + 60} L${EXIT[0] + EXIT[2] - 10} ${EXIT[1] + EXIT[3] - 60}" stroke="#1f5f6b" stroke-width="12" opacity="0.6"/>
  <rect x="${EXIT[0] + 16}" y="${EXIT[1] + 260}" width="30" height="16" rx="5" fill="#d4a24c"/>
  <rect x="${EXIT[0] + 60}" y="${EXIT[1] + 250}" width="70" height="12" rx="5" fill="#6b5a66"/>
  <!-- hanging watering cans and a coil of rope -->
  <path d="M1180 120 L1180 160" stroke="#6b5a66" stroke-width="4"/><path d="M1150 170 H1210 L1204 230 H1156 Z" fill="#8faf8a"/><path d="M1210 180 L1250 150" stroke="#8faf8a" stroke-width="8" stroke-linecap="round"/>
  <circle cx="1290" cy="160" r="30" fill="none" stroke="#e3ad3a" stroke-width="10"/><circle cx="1290" cy="160" r="16" fill="none" stroke="#e3ad3a" stroke-width="8"/>
  <!-- light bulb -->
  <rect x="957" y="-180" width="4" height="200" fill="#3b2e3a"/><circle cx="959" cy="36" r="16" fill="#fbe3a0"/><rect x="950" y="14" width="18" height="12" fill="#6b5a66"/>
  <rect x="-240" y="${FLOOR_Y}" width="2400" height="10" fill="#3b2e3a" opacity="0.2"/>`, "Shed background: warm wooden planks, the small dusty window is a transparent hole, the blue side door on the right.");
save("rooms/shed_bg.svg", bg);

save("rooms/shed_light.svg", lightLayer(
  [`${WINDOW[0]},${WINDOW[1] + WINDOW[3]} ${WINDOW[0] + WINDOW[2]},${WINDOW[1] + WINDOW[3]} 900,1100 420,1100`],
  [[640, 940, 320, 90, 0.9], [960, 60, 120, 60, 0.4]],
  "A dusty sunbeam through the little shed window."));

// ---------------------------------------------------------------- furniture
const shadow = (cx, cy, rx, ry, op = 0.2) => `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="#3b2e3a" opacity="${op}"/>`;

// Rose's old flower cart from the market: striped awning, a painted rose on the sign, zinc buckets.
save("props/shed/flower_cart.svg", svg(560, 430, `  ${shadow(280, 420, 270, 10)}
  <!-- awning -->
  <rect x="30" y="0" width="12" height="220" fill="#7a5134"/><rect x="518" y="0" width="12" height="220" fill="#7a5134"/>
  ${[0, 1, 2, 3, 4, 5, 6, 7].map((i) => `<path d="M${20 + i * 65} 20 L${85 + i * 65} 20 L${85 + i * 65} 80 Q${52 + i * 65} 98 ${20 + i * 65} 80 Z" fill="${i % 2 ? "#fffbf5" : "#ee7b6b"}"/>`).join("")}
  <rect x="14" y="8" width="532" height="18" rx="6" fill="#c95b52"/>
  <!-- the sign with a painted rose -->
  <rect x="150" y="100" width="260" height="70" rx="10" fill="#fff4e2"/><rect x="150" y="100" width="260" height="70" rx="10" fill="none" stroke="#2e8c8c" stroke-width="6"/>
  <circle cx="200" cy="135" r="20" fill="#ee7b6b"/><path d="M190 132 Q200 120 210 132 Q200 146 190 132 Z" fill="#c95b52"/><path d="M200 155 L200 168" stroke="#5e7f5e" stroke-width="4"/>
  <path d="M236 122 C260 116 290 128 318 120 C340 114 360 124 384 118 M236 148 C270 140 300 152 340 144" stroke="#2e8c8c" stroke-width="5" fill="none" stroke-linecap="round"/>
  <!-- buckets of flowers on the cart -->
  ${[[70, "#f6c453"], [150, "#ee7b6b"], [390, "#9c8ac4"], [470, "#fffbf5"]].map(([x, c]) => `<path d="M${x - 30} 230 L${x + 30} 230 L${x + 24} 290 L${x - 24} 290 Z" fill="#c9d0d6"/><rect x="${x - 32}" y="226" width="64" height="8" rx="3" fill="#e3e8ec"/>${[-14, 0, 14].map((d) => `<path d="M${x + d} 230 L${x + d * 1.4} 196" stroke="#5e7f5e" stroke-width="4"/><circle cx="${x + d * 1.5}" cy="${190}" r="12" fill="${c}"/><circle cx="${x + d * 1.5}" cy="190" r="4" fill="#c8674a"/>`).join("")}`).join("")}
  <!-- the cart -->
  <rect x="10" y="290" width="540" height="24" rx="6" fill="#c99a6b"/>
  <rect x="30" y="314" width="500" height="70" rx="6" fill="#a8744a"/>
  <rect x="190" y="326" width="180" height="46" rx="6" fill="#c99a6b"/><rect x="258" y="344" width="44" height="9" rx="4" fill="#d4a24c"/>
  <circle cx="110" cy="386" r="40" fill="#5e3e28"/><circle cx="110" cy="386" r="30" fill="none" stroke="#c99a6b" stroke-width="6"/><circle cx="110" cy="386" r="6" fill="#d4a24c"/>
  <circle cx="450" cy="386" r="40" fill="#5e3e28"/><circle cx="450" cy="386" r="30" fill="none" stroke="#c99a6b" stroke-width="6"/><circle cx="450" cy="386" r="6" fill="#d4a24c"/>`, "Rose's old market flower cart: striped awning, a sign with a painted rose, zinc buckets of flowers, a drawer."));

// Workbench with the old scales and a vice.
save("props/shed/workbench.svg", svg(620, 340, `  ${shadow(310, 332, 300, 9)}
  <g transform="translate(0 30)">
  <rect x="20" y="50" width="30" height="250" fill="#7a5134"/><rect x="570" y="50" width="30" height="250" fill="#7a5134"/>
  <rect x="40" y="210" width="540" height="16" fill="#8a6446"/>
  <rect x="0" y="30" width="620" height="40" rx="6" fill="#c99a6b"/><rect x="0" y="30" width="620" height="8" rx="4" fill="#e3c39a"/>
  <rect x="60" y="70" width="240" height="60" rx="6" fill="#a8744a"/><rect x="160" y="92" width="40" height="10" rx="5" fill="#d4a24c"/>
  <rect x="320" y="70" width="240" height="60" rx="6" fill="#a8744a"/><rect x="420" y="92" width="40" height="10" rx="5" fill="#d4a24c"/>
  <!-- the old scales -->
  <rect x="286" y="-6" width="8" height="36" fill="#a87a2e"/>
  <path d="M230 -2 L350 -2" stroke="#a87a2e" stroke-width="6" stroke-linecap="round"/>
  <path d="M210 10 Q232 26 254 10 Z" fill="#d4a24c"/><path d="M326 10 Q348 26 370 10 Z" fill="#d4a24c"/>
  <path d="M232 -2 L214 10 M232 -2 L250 10 M348 -2 L330 10 M348 -2 L366 10" stroke="#a87a2e" stroke-width="2"/>
  <rect x="266" y="26" width="48" height="8" rx="3" fill="#7a5134"/>
  <!-- weights -->
  ${[[410, 16], [440, 12], [464, 9]].map(([x, s]) => `<rect x="${x - s}" y="${30 - s * 1.6}" width="${s * 2}" height="${s * 1.6}" rx="3" fill="#6b5a66"/><rect x="${x - 3}" y="${30 - s * 1.6 - 5}" width="6" height="6" rx="2" fill="#6b5a66"/>`).join("")}
  <!-- vice -->
  <rect x="40" y="6" width="70" height="26" rx="4" fill="#6b5a66"/><rect x="60" y="-8" width="10" height="18" fill="#3b2e3a"/>
  <!-- seed tins underneath -->
  ${[90, 150, 210, 380, 440, 500].map((x, i) => `<rect x="${x}" y="${170 - (i % 2) * 6}" width="44" height="${40 + (i % 2) * 6}" rx="4" fill="${["#ee7b6b", "#6cc2be", "#f6c453"][i % 3]}"/>`).join("")}
  </g>`, "Workbench with two drawers, the old market scales and weights, a vice, and seed tins underneath."));

// Pegboard with Céline's father's tools, each hanging on its painted outline.
save("props/shed/pegboard.svg", svg(580, 290, `  <rect x="8" y="10" width="572" height="280" rx="6" fill="#3b2e3a" opacity="0.2"/>
  <rect x="0" y="0" width="572" height="280" rx="6" fill="#d9bd8c"/>
  ${Array.from({ length: 13 }, (_, i) => Array.from({ length: 6 }, (_, j) => `<circle cx="${22 + i * 44}" cy="${22 + j * 46}" r="3" fill="#a8744a"/>`).join("")).join("")}
  <!-- hammer, saw, pliers, screwdriver, wrench outline (empty!), scissors -->
  <rect x="50" y="40" width="14" height="150" rx="6" fill="#a8744a"/><rect x="20" y="30" width="74" height="30" rx="6" fill="#6b5a66"/>
  <path d="M140 40 L220 40 L220 60 L150 200 L130 190 Z" fill="#c9d0d6"/><rect x="200" y="30" width="40" height="46" rx="8" fill="#c8674a"/>
  <path d="M280 50 L300 160 M320 50 L300 160" stroke="#6b5a66" stroke-width="10" stroke-linecap="round"/><path d="M286 160 L300 240 L314 160" stroke="#ee7b6b" stroke-width="12" fill="none" stroke-linecap="round"/>
  <rect x="370" y="40" width="14" height="80" rx="6" fill="#c9d0d6"/><rect x="364" y="116" width="26" height="90" rx="10" fill="#2e8c8c"/>
  <path d="M440 40 C420 40 416 70 436 76 L446 220 L466 220 L456 76 C476 70 472 40 452 40 L452 62 L440 62 Z" fill="none" stroke="#7a5134" stroke-width="3" stroke-dasharray="6 5"/>
  <circle cx="518" cy="200" r="18" fill="none" stroke="#e3ad3a" stroke-width="7"/><circle cx="546" cy="200" r="18" fill="none" stroke="#e3ad3a" stroke-width="7"/><path d="M526 186 L560 60 M538 186 L504 60" stroke="#c9d0d6" stroke-width="8" stroke-linecap="round"/>`, "Pegboard with tools on painted outlines; the outline of a wrench is empty."));

save("props/shed/shelves.svg", svg(290, 310, `  <rect x="6" y="10" width="284" height="300" rx="4" fill="#3b2e3a" opacity="0.12"/>
  <rect x="0" y="120" width="290" height="14" rx="4" fill="#7a5134"/><rect x="0" y="250" width="290" height="14" rx="4" fill="#7a5134"/>
  <path d="M20 134 L40 180 M270 134 L250 180 M20 264 L40 310 M270 264 L250 310" stroke="#5e3e28" stroke-width="8"/>
  <!-- paint cans and jars -->
  <rect x="20" y="70" width="56" height="50" rx="6" fill="#6cc2be"/><rect x="18" y="64" width="60" height="10" rx="4" fill="#c9d0d6"/><path d="M26 90 L70 90" stroke="#2e8c8c" stroke-width="6"/>
  <rect x="200" y="84" width="40" height="36" rx="5" fill="#fff4e2" opacity="0.9"/><rect x="198" y="78" width="44" height="10" rx="4" fill="#a8744a"/>
  <rect x="230" y="200" width="44" height="50" rx="6" fill="#ee7b6b"/><rect x="228" y="194" width="48" height="10" rx="4" fill="#c9d0d6"/>
  <rect x="20" y="206" width="30" height="44" rx="5" fill="#f6c453"/><rect x="56" y="214" width="26" height="36" rx="5" fill="#8faf8a"/>`, "Two wooden shelves with paint cans, jars and seed packets."));

// Céline's delivery bicycle with its big front basket.
save("props/shed/bicycle.svg", svg(340, 290, `  ${shadow(170, 282, 160, 8)}
  <circle cx="70" cy="210" r="66" fill="none" stroke="#3b2e3a" stroke-width="9"/><circle cx="70" cy="210" r="8" fill="#6b5a66"/>
  <circle cx="270" cy="210" r="66" fill="none" stroke="#3b2e3a" stroke-width="9"/><circle cx="270" cy="210" r="8" fill="#6b5a66"/>
  ${[0, 1, 2, 3, 4, 5].map((i) => { const a = (i / 6) * Math.PI; return `<path d="M${(70 - Math.cos(a) * 60).toFixed(1)} ${(210 - Math.sin(a) * 60).toFixed(1)} L${(70 + Math.cos(a) * 60).toFixed(1)} ${(210 + Math.sin(a) * 60).toFixed(1)} M${(270 - Math.cos(a) * 60).toFixed(1)} ${(210 - Math.sin(a) * 60).toFixed(1)} L${(270 + Math.cos(a) * 60).toFixed(1)} ${(210 + Math.sin(a) * 60).toFixed(1)}" stroke="#c9d0d6" stroke-width="1.5"/>`; }).join("")}
  <path d="M70 210 L150 210 L210 120 L110 120 Z M150 210 L110 120 M210 120 L262 210" stroke="#2e8c8c" stroke-width="10" fill="none" stroke-linejoin="round"/>
  <path d="M106 120 L96 96" stroke="#3b2e3a" stroke-width="8"/><rect x="76" y="88" width="46" height="12" rx="6" fill="#7a5134"/>
  <path d="M210 120 L226 80 L250 76" stroke="#3b2e3a" stroke-width="8" fill="none" stroke-linecap="round"/>
  <!-- the basket -->
  <path d="M232 60 L322 60 L312 124 L242 124 Z" fill="#c99a6b"/>
  ${[0, 1, 2, 3].map((i) => `<path d="M234 ${72 + i * 14} L320 ${72 + i * 14}" stroke="#a8744a" stroke-width="4"/>`).join("")}
  ${[250, 270, 290, 310].map((x) => `<path d="M${x} 60 L${x - 4} 124" stroke="#a8744a" stroke-width="3"/>`).join("")}
  <circle cx="260" cy="54" r="11" fill="#f6c453"/><circle cx="286" cy="50" r="12" fill="#f6c453"/><circle cx="286" cy="50" r="5" fill="#7a5134"/>
  <!-- chain lock with little number wheels -->
  <path d="M146 200 C150 236 196 236 206 212" stroke="#6b5a66" stroke-width="7" fill="none"/>
  <rect x="160" y="226" width="40" height="18" rx="5" fill="#e3ad3a"/>`, "Céline's old delivery bicycle with a big basket (a sunflower in it) and a chain lock."));

save("props/shed/soil_sack.svg", svg(160, 180, `  ${shadow(80, 172, 70, 7)}
  <path d="M20 40 C30 20 130 20 140 40 L150 160 C120 176 40 176 10 160 Z" fill="#c9b48f"/>
  <path d="M20 40 C40 60 120 60 140 40 C130 30 30 30 20 40 Z" fill="#6b4a36"/>
  <path d="M40 100 C60 92 100 92 120 100" stroke="#8faf8a" stroke-width="10" stroke-linecap="round"/>
  <circle cx="80" cy="120" r="14" fill="#8faf8a"/>
  <path d="M110 30 L124 -2" stroke="#7a5134" stroke-width="8" stroke-linecap="round"/>`, "An open sack of potting soil with a little plant printed on it."));

console.log("shed art written");
