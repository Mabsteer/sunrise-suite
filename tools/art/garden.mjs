// Generates the back garden art (background, light layer, furniture). The SVG files are the editable source;
// re-running this overwrites them:  node tools/art/garden.mjs
// The garden is "the first years" (docs/STORY.md): the lemon tree Henri planted for the wedding, the
// vegetable beds, the sundial, the bird bath, and the blue shed at the end (the way on).
import { save, svg, roomSvg, lightLayer, rng } from "./room_kit.mjs";

const GROUND_Y = 580;
const WALL_TOP = 500;
const SHED_DOOR = [1600, 380, 200, 320];

const tufts = () => {
  const r = rng(31);
  const out = [];
  for (let i = 0; i < 90; i++) {
    const x = -240 + r() * 2400, y = GROUND_Y + 40 + r() * 640;
    const s = 0.6 + (y - GROUND_Y) / 600;
    out.push(`<path d="M${x.toFixed(0)} ${y.toFixed(0)} l${(-6 * s).toFixed(1)} ${(-16 * s).toFixed(1)} M${x.toFixed(0)} ${y.toFixed(0)} l0 ${(-20 * s).toFixed(1)} M${x.toFixed(0)} ${y.toFixed(0)} l${(6 * s).toFixed(1)} ${(-15 * s).toFixed(1)}" stroke="#5e7f5e" stroke-width="${(2 * s).toFixed(1)}" stroke-linecap="round" opacity="0.55"/>`);
  }
  return out.join("");
};

const stones = () => {
  const out = [];
  for (let x = -240; x < 2160; x += 90) out.push(`<rect x="${x + 2}" y="${WALL_TOP + 2}" width="86" height="36" rx="8" fill="#d9c6a6"/><rect x="${x + 47}" y="${WALL_TOP + 42}" width="86" height="36" rx="8" fill="#cdb996"/>`);
  return out.join("");
};

const flagstones = () => {
  const r = rng(5);
  const out = [];
  let y = 900;
  for (let row = 0; row < 4; row++) {
    const h = 70 + row * 30;
    let x = -240 - r() * 120;
    while (x < 2160) {
      const w = 200 + r() * 120 + row * 40;
      out.push(`<rect x="${x.toFixed(0)}" y="${y}" width="${(w - 14).toFixed(0)}" height="${h - 12}" rx="14" fill="${["#e9dcc2", "#dccbab", "#e3d3b5"][Math.floor(r() * 3)]}"/>`);
      x += w;
    }
    y += h;
  }
  return out.join("");
};

const bg = roomSvg(`  <defs>
    <linearGradient id="lawn" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9fbf8f"/><stop offset="1" stop-color="#7fa472"/></linearGradient>
    <linearGradient id="shed" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6cc2be"/><stop offset="1" stop-color="#4fa6a6"/></linearGradient>
    <linearGradient id="groundShade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3b2e3a" stop-opacity="0.15"/><stop offset="0.3" stop-color="#3b2e3a" stop-opacity="0"/><stop offset="1" stop-color="#3b2e3a" stop-opacity="0.12"/></linearGradient>
  </defs>
  <!-- the back garden wall (sea beyond it) -->
  <rect x="-240" y="${WALL_TOP}" width="2400" height="${GROUND_Y - WALL_TOP + 10}" fill="#c9b48f"/>
  ${stones()}
  <rect x="-240" y="${WALL_TOP - 10}" width="2400" height="16" rx="6" fill="#e9dcc2"/>
  <!-- lawn -->
  <rect x="-240" y="${GROUND_Y}" width="2400" height="${1260 - GROUND_Y}" fill="url(#lawn)"/>
  ${tufts()}
  <!-- terrace near the house -->
  <rect x="-240" y="890" width="2400" height="370" fill="#cdb996"/>
  ${flagstones()}
  <rect x="-240" y="${GROUND_Y}" width="2400" height="680" fill="url(#groundShade)"/>
  <!-- trellis panel on the left -->
  <rect x="20" y="300" width="200" height="300" fill="#fff4e2" opacity="0.9"/>
  ${[0, 1, 2, 3, 4, 5].map((i) => `<path d="M${20 + i * 40} 300 L${20 + i * 40} 600 M20 ${300 + i * 60} L220 ${300 + i * 60}" stroke="#c99a6b" stroke-width="6"/>`).join("")}
  <path d="M40 600 C60 520 30 450 70 380 C90 340 120 330 140 320" stroke="#5e7f5e" stroke-width="6" fill="none"/>
  ${[[70, 380], [110, 440], [60, 500], [150, 340], [170, 420]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="12" fill="#ee7b6b"/><circle cx="${x}" cy="${y}" r="5" fill="#f6c453"/>`).join("")}
  <!-- the blue shed (its door is the way on) -->
  <path d="M1440 250 L1700 120 L1960 250 Z" fill="#c8674a"/>
  <path d="M1440 250 L1700 120 L1960 250 L1940 262 L1700 142 L1460 262 Z" fill="#a8554a"/>
  <rect x="1470" y="250" width="460" height="460" fill="url(#shed)"/>
  ${[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map((i) => `<rect x="${1470 + i * 42}" y="250" width="3" height="460" fill="#2e8c8c" opacity="0.35"/>`).join("")}
  <rect x="1470" y="700" width="460" height="14" fill="#2e8c8c"/>
  <!-- shed door -->
  <rect x="${SHED_DOOR[0] - 12}" y="${SHED_DOOR[1] - 12}" width="${SHED_DOOR[2] + 24}" height="${SHED_DOOR[3] + 12}" fill="#fffbf5"/>
  <rect x="${SHED_DOOR[0]}" y="${SHED_DOOR[1]}" width="${SHED_DOOR[2]}" height="${SHED_DOOR[3]}" fill="#2e8c8c"/>
  ${[0, 1, 2, 3].map((i) => `<rect x="${SHED_DOOR[0] + 8 + i * 48}" y="${SHED_DOOR[1] + 8}" width="42" height="${SHED_DOOR[3] - 16}" rx="3" fill="#35999a"/>`).join("")}
  <path d="M${SHED_DOOR[0] + 10} ${SHED_DOOR[1] + 40} L${SHED_DOOR[0] + SHED_DOOR[2] - 10} ${SHED_DOOR[1] + SHED_DOOR[3] - 40}" stroke="#1f5f6b" stroke-width="12" opacity="0.6"/>
  <rect x="${SHED_DOOR[0] + SHED_DOOR[2] - 44}" y="${SHED_DOOR[1] + 150}" width="30" height="16" rx="5" fill="#d4a24c"/>
  <!-- shed window (dusty, dark inside) -->
  <rect x="1830" y="330" width="80" height="100" rx="6" fill="#fffbf5"/><rect x="1840" y="340" width="60" height="80" fill="#3e3570" opacity="0.7"/>
  <path d="M1870 340 V420 M1840 380 H1900" stroke="#fffbf5" stroke-width="5"/>
  <!-- washing line from the tree to the shed -->
  <path d="M640 250 Q1060 330 1470 270" stroke="#fffbf5" stroke-width="3" fill="none"/>
  <path d="M760 270 L760 290 L820 292 L822 350 L752 350 Z" fill="#fffbf5"/>
  <path d="M900 290 L960 294 L958 390 L902 386 Z" fill="#f9b98a"/>
  <path d="M1040 300 L1110 300 L1100 350 L1120 400 L1060 402 L1050 350 Z" fill="#6cc2be"/>
  <path d="M1200 298 L1280 294 L1284 340 L1204 344 Z" fill="#f6c453"/>
  ${[760, 822, 900, 958, 1040, 1110, 1200, 1280].map((x) => `<rect x="${x - 3}" y="${278 + (x - 640) * 0.06}" width="6" height="16" rx="2" fill="#a8744a"/>`).join("")}`, "Back garden background: the stone wall with the sea above it (transparent sky), lawn, terrace, trellis with roses and the blue shed.");
save("rooms/garden_bg.svg", bg);

save("rooms/garden_light.svg", lightLayer(
  ["700,-180 1260,-180 1560,1260 300,1260"],
  [[960, 780, 700, 160, 0.9], [700, 1000, 500, 90, 0.6]],
  "Soft morning light over the garden (additive, strength follows the sunrise)."));

// ---------------------------------------------------------------- furniture
const shadow = (cx, cy, rx, ry, op = 0.18) => `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="#3b2e3a" opacity="${op}"/>`;

// The lemon tree, big now; the wedding was under it when it was tiny.
const lemons = [[140, 170], [230, 120], [330, 180], [180, 260], [290, 280], [390, 250], [250, 210], [110, 230], [360, 130]];
save("props/garden/lemon_tree.svg", svg(500, 640, `  ${shadow(250, 628, 150, 14, 0.22)}
  <path d="M232 630 C226 540 220 470 196 400 L236 396 C252 460 262 540 270 630 Z" fill="#7a5134"/>
  <path d="M240 420 C270 380 310 360 350 356" stroke="#7a5134" stroke-width="18" fill="none" stroke-linecap="round"/>
  <path d="M220 440 C190 410 150 400 120 404" stroke="#7a5134" stroke-width="14" fill="none" stroke-linecap="round"/>
  <path d="M242 600 C246 560 244 520 238 480" stroke="#a8744a" stroke-width="6" fill="none" opacity="0.6"/>
  <circle cx="250" cy="200" r="190" fill="#5e7f5e"/>
  <circle cx="150" cy="220" r="120" fill="#6f9468"/>
  <circle cx="350" cy="210" r="130" fill="#6f9468"/>
  <circle cx="250" cy="130" r="130" fill="#8faf8a"/>
  <circle cx="200" cy="100" r="60" fill="#a9c7a3" opacity="0.6"/>
  ${lemons.map(([x, y]) => `<ellipse cx="${x}" cy="${y}" rx="17" ry="13" fill="#f6c453"/><ellipse cx="${x - 5}" cy="${y - 4}" rx="5" ry="3" fill="#fbe3a0"/>`).join("\n  ")}
  <!-- the old stick it needed in 1960, still tied on -->
  <path d="M262 630 L276 470" stroke="#c99a6b" stroke-width="7" stroke-linecap="round"/>
  <path d="M254 520 L282 514" stroke="#ee7b6b" stroke-width="5" stroke-linecap="round"/>`, "The lemon tree, full of lemons, with the old stick from 1960 still tied to its trunk."));

// Raised vegetable bed with rows of plants.
const row = (y, kind, n, x0, dx) => Array.from({ length: n }, (_, i) => {
  const x = x0 + i * dx;
  if (kind === 0) return `<circle cx="${x}" cy="${y}" r="18" fill="#8faf8a"/><circle cx="${x - 5}" cy="${y - 5}" r="9" fill="#a9c7a3"/>`;
  if (kind === 1) return `<path d="M${x} ${y + 12} L${x - 10} ${y - 16} M${x} ${y + 12} L${x} ${y - 20} M${x} ${y + 12} L${x + 10} ${y - 16}" stroke="#5e7f5e" stroke-width="4" stroke-linecap="round"/><path d="M${x - 5} ${y + 10} L${x + 5} ${y + 10} L${x} ${y + 26} Z" fill="#e08e6d"/>`;
  return `<circle cx="${x}" cy="${y - 6}" r="14" fill="#5e7f5e"/><circle cx="${x + 6}" cy="${y}" r="7" fill="#ee7b6b"/><circle cx="${x - 8}" cy="${y + 2}" r="6" fill="#ee7b6b"/>`;
}).join("");
save("props/garden/veg_bed.svg", svg(540, 220, `  ${shadow(270, 212, 262, 10)}
  <path d="M40 40 L500 40 L530 190 L10 190 Z" fill="#7a5134"/>
  <path d="M52 52 L488 52 L512 180 L28 180 Z" fill="#5e4230"/>
  ${row(78, 0, 8, 90, 52)}
  ${row(118, 1, 9, 70, 50)}
  ${row(158, 2, 9, 55, 54)}
  <rect x="6" y="186" width="528" height="26" rx="6" fill="#a8744a"/><rect x="6" y="186" width="528" height="6" rx="3" fill="#c99a6b"/>`, "Raised vegetable bed with rows of lettuce, carrots and tomatoes."));

save("props/garden/sundial.svg", svg(170, 230, `  ${shadow(85, 222, 70, 8)}
  <rect x="50" y="90" width="70" height="120" rx="8" fill="#e3d3b5"/>
  <rect x="42" y="200" width="86" height="20" rx="6" fill="#cdb996"/>
  <rect x="38" y="80" width="94" height="18" rx="6" fill="#cdb996"/>
  <ellipse cx="85" cy="62" rx="80" ry="28" fill="#d4a24c"/>
  <ellipse cx="85" cy="58" rx="72" ry="23" fill="#f0c877"/>
  ${Array.from({ length: 12 }, (_, i) => { const a = (i / 12) * Math.PI * 2; return `<path d="M${(85 + Math.cos(a) * 58).toFixed(1)} ${(58 + Math.sin(a) * 18).toFixed(1)} L${(85 + Math.cos(a) * 66).toFixed(1)} ${(58 + Math.sin(a) * 20.5).toFixed(1)}" stroke="#a87a2e" stroke-width="3"/>`; }).join("")}
  <path d="M85 58 L85 22 L120 58 Z" fill="#a87a2e"/>
  <path d="M85 58 L40 70" stroke="#7a5134" stroke-width="5" opacity="0.4"/>`, "Stone sundial that Henri set 'to our time'."));

save("props/garden/bird_bath.svg", svg(150, 220, `  ${shadow(75, 212, 60, 7)}
  <path d="M60 80 L90 80 L96 200 L54 200 Z" fill="#e3d3b5"/>
  <rect x="40" y="196" width="70" height="18" rx="6" fill="#cdb996"/>
  <ellipse cx="75" cy="70" rx="70" ry="22" fill="#e9dcc2"/>
  <ellipse cx="75" cy="64" rx="60" ry="15" fill="#6cc2be"/>
  <ellipse cx="60" cy="60" rx="18" ry="4" fill="#fffbf5" opacity="0.6"/>
  <g transform="translate(112 44)"><ellipse cx="0" cy="0" rx="12" ry="9" fill="#9c8ac4"/><circle cx="9" cy="-8" r="6" fill="#9c8ac4"/><path d="M14 -9 L20 -8 L14 -6 Z" fill="#f6c453"/></g>`, "Stone bird bath with a lavender bird on the rim."));

save("props/garden/garden_table.svg", svg(340, 250, `  ${shadow(170, 242, 160, 9)}
  <!-- two chairs -->
  <path d="M10 70 L60 70 L66 240 L58 240 L52 150 L18 150 L14 240 L6 240 Z" fill="#f6c453"/>
  <rect x="4" y="140" width="66" height="14" rx="5" fill="#e3ad3a"/>
  <path d="M330 70 L280 70 L274 240 L282 240 L288 150 L322 150 L326 240 L334 240 Z" fill="#f6c453"/>
  <rect x="270" y="140" width="66" height="14" rx="5" fill="#e3ad3a"/>
  <!-- table -->
  <ellipse cx="170" cy="96" rx="130" ry="30" fill="#fffbf5"/>
  <ellipse cx="170" cy="92" rx="124" ry="25" fill="#fff4e2"/>
  <path d="M166 120 L174 120 L180 236 L160 236 Z" fill="#6b5a66"/>
  <path d="M120 240 Q170 214 220 240" stroke="#6b5a66" stroke-width="8" fill="none"/>
  <!-- the drawer under the tabletop -->
  <rect x="120" y="116" width="100" height="24" rx="5" fill="#e9dcc2"/><rect x="156" y="124" width="28" height="7" rx="3" fill="#d4a24c"/>`, "White round garden table with a little drawer and two yellow chairs."));

save("props/garden/flower_bed.svg", svg(380, 160, `  ${shadow(190, 150, 180, 8, 0.14)}
  <path d="M0 60 C60 40 320 40 380 60 L380 150 L0 150 Z" fill="#6b4a36"/>
  <path d="M0 60 C60 44 320 44 380 60 L380 72 C320 58 60 58 0 72 Z" fill="#8a6446"/>
  ${[[40, 50], [100, 30], [160, 44], [220, 26], [280, 46], [340, 34]].map(([x, y]) => `<path d="M${x} 90 L${x} ${y + 20}" stroke="#5e7f5e" stroke-width="5"/><circle cx="${x}" cy="${y + 12}" r="18" fill="#ee7b6b"/><circle cx="${x}" cy="${y + 12}" r="8" fill="#c95b52"/><path d="M${x} 80 L${x + 16} 70" stroke="#5e7f5e" stroke-width="5" stroke-linecap="round"/>`).join("")}
  <path d="M60 120 C90 112 110 124 140 116 M220 128 C250 120 280 132 310 124" stroke="#4a3426" stroke-width="4" fill="none" opacity="0.6"/>`, "Flower bed of red roses along the garden wall; the soil looks soft."));

console.log("garden art written");
