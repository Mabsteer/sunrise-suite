// Generates the hall art (background, light layer, furniture). The SVG files are the editable source;
// re-running this overwrites them:  node tools/art/hall.mjs
// The hall is "the summers with Juliette" (docs/STORY.md): coat rack with straw hats and the beach bag,
// height marks on the door frame, the grandfather clock, the stairs with the little cupboard underneath.
import { save, svg, roomSvg, checkerFloor, frame, glassReflections, lightLayer, number } from "./room_kit.mjs";

const FLOOR_Y = 770;
const FRONT_DOOR = [120, 250, 250, 520];
const FANLIGHT = { cx: 245, cy: 250, r: 118 };
const STAIR_WINDOW = [1520, 110, 180, 250];
const EXIT = [880, 190, 240, 580];

// Wall with a half-round fanlight hole and a rectangular stair window hole (evenodd).
const [sx, sy, sw, sh] = STAIR_WINDOW;
const fan = `M${FANLIGHT.cx - FANLIGHT.r} ${FANLIGHT.cy} A${FANLIGHT.r} ${FANLIGHT.r} 0 0 1 ${FANLIGHT.cx + FANLIGHT.r} ${FANLIGHT.cy} Z`;
const wall = `<path fill="url(#wall)" fill-rule="evenodd" d="M-240 60 H2160 V${FLOOR_Y} H-240 Z ${fan} M${sx} ${sy} H${sx + sw} V${sy + sh} H${sx} Z"/>`;

const wainscot = () => {
  const out = [`<rect x="-240" y="480" width="2400" height="${FLOOR_Y - 480}" fill="#b7cfc8"/>`, `<rect x="-240" y="472" width="2400" height="14" fill="#fffbf5"/>`];
  for (let x = -220; x < 2160; x += 150) out.push(`<rect x="${x}" y="510" width="120" height="${FLOOR_Y - 550}" rx="6" fill="#a6c2ba"/><rect x="${x}" y="510" width="120" height="6" fill="#fffbf5" opacity="0.4"/>`);
  return out.join("\n  ");
};

const bg = roomSvg(`  <defs>
    <linearGradient id="ceiling" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e9d6bd"/><stop offset="1" stop-color="#f6e9d5"/></linearGradient>
    <linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff4e2"/><stop offset="1" stop-color="#f6e4c8"/></linearGradient>
    <linearGradient id="floorShade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3b2e3a" stop-opacity="0.22"/><stop offset="0.35" stop-color="#3b2e3a" stop-opacity="0"/><stop offset="1" stop-color="#3b2e3a" stop-opacity="0.18"/></linearGradient>
    <linearGradient id="door" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#2e8c8c"/><stop offset="1" stop-color="#1f5f6b"/></linearGradient>
    <linearGradient id="wood" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#c99a6b"/><stop offset="1" stop-color="#a8744a"/></linearGradient>
  </defs>
  <rect x="-240" y="-180" width="2400" height="250" fill="url(#ceiling)"/>
  <rect x="-240" y="48" width="2400" height="16" fill="#fffbf5"/>
  <rect x="-240" y="64" width="2400" height="10" fill="#3b2e3a" opacity="0.06"/>
  <g>
  ${checkerFloor(FLOOR_Y, 1260, "#ecdcbf", "#9fb9b2", "#6b8f88")}
  </g>
  <rect x="-240" y="${FLOOR_Y}" width="2400" height="490" fill="url(#floorShade)"/>
  <!-- runner rug -->
  <path d="M160 ${FLOOR_Y + 40} L1340 ${FLOOR_Y + 40} L1500 1250 L0 1250 Z" fill="#c8674a"/>
  <path d="M190 ${FLOOR_Y + 58} L1312 ${FLOOR_Y + 58} L1452 1230 L48 1230 Z" fill="#e08e6d"/>
  <path d="M230 ${FLOOR_Y + 80} L1270 ${FLOOR_Y + 80} M200 ${FLOOR_Y + 180} L1330 ${FLOOR_Y + 180} M150 ${FLOOR_Y + 320} L1390 ${FLOOR_Y + 320}" stroke="#f6c453" stroke-width="6" opacity="0.7"/>
  ${wall}
  ${wainscot()}
  <!-- fanlight above the front door -->
  <path d="M${FANLIGHT.cx - FANLIGHT.r - 18} ${FANLIGHT.cy} A${FANLIGHT.r + 18} ${FANLIGHT.r + 18} 0 0 1 ${FANLIGHT.cx + FANLIGHT.r + 18} ${FANLIGHT.cy} L${FANLIGHT.cx + FANLIGHT.r} ${FANLIGHT.cy} A${FANLIGHT.r} ${FANLIGHT.r} 0 0 0 ${FANLIGHT.cx - FANLIGHT.r} ${FANLIGHT.cy} Z" fill="#fffbf5"/>
  ${[-60, -30, 0, 30, 60].map((a) => { const rad = ((a - 90) * Math.PI) / 180; return `<line x1="${FANLIGHT.cx}" y1="${FANLIGHT.cy}" x2="${(FANLIGHT.cx + Math.cos(rad) * FANLIGHT.r).toFixed(1)}" y2="${(FANLIGHT.cy + Math.sin(rad) * FANLIGHT.r).toFixed(1)}" stroke="#fffbf5" stroke-width="8"/>`; }).join("")}
  <circle cx="${FANLIGHT.cx}" cy="${FANLIGHT.cy}" r="26" fill="#fffbf5"/>
  <!-- front door (closed; not part of the hunt) -->
  ${frame(FRONT_DOOR, 20, "#fffbf5")}
  <rect x="${FRONT_DOOR[0]}" y="${FRONT_DOOR[1]}" width="${FRONT_DOOR[2]}" height="${FRONT_DOOR[3]}" fill="url(#door)"/>
  <rect x="${FRONT_DOOR[0] + 26}" y="${FRONT_DOOR[1] + 30}" width="${FRONT_DOOR[2] - 52}" height="170" rx="10" fill="#2e8c8c"/>
  ${[[0, "#f6c453"], [1, "#ee7b6b"], [2, "#6cc2be"]].map(([i, c]) => `<rect x="${FRONT_DOOR[0] + 40 + i * 58}" y="${FRONT_DOOR[1] + 44}" width="50" height="140" rx="6" fill="${c}" opacity="0.75"/>`).join("")}
  <rect x="${FRONT_DOOR[0] + 26}" y="${FRONT_DOOR[1] + 230}" width="${FRONT_DOOR[2] - 52}" height="260" rx="10" fill="#2a7d7d"/>
  <circle cx="${FRONT_DOOR[0] + FRONT_DOOR[2] - 36}" cy="${FRONT_DOOR[1] + 280}" r="11" fill="#d4a24c"/>
  <rect x="${FRONT_DOOR[0] + FRONT_DOOR[2] / 2 - 30}" y="${FRONT_DOOR[1] + 206}" width="60" height="14" rx="5" fill="#d4a24c"/>
  <rect x="${FRONT_DOOR[0] - 10}" y="${FLOOR_Y - 8}" width="${FRONT_DOOR[2] + 20}" height="12" rx="3" fill="#a87a2e"/>
  <!-- stair window -->
  ${frame(STAIR_WINDOW, 16, "#fffbf5")}
  <rect x="${sx + sw / 2 - 7}" y="${sy}" width="14" height="${sh}" fill="#fffbf5"/>
  <rect x="${sx}" y="${sy + sh / 2 - 7}" width="${sw}" height="14" fill="#fffbf5"/>
  ${glassReflections(STAIR_WINDOW)}
  <!-- bedroom door (the way on) -->
  ${frame(EXIT, 26, "#fffbf5")}
  <rect x="${EXIT[0]}" y="${EXIT[1]}" width="${EXIT[2]}" height="${EXIT[3]}" fill="url(#wood)"/>
  <rect x="${EXIT[0] + 26}" y="${EXIT[1] + 26}" width="${EXIT[2] - 52}" height="230" rx="8" fill="#b88558"/>
  <rect x="${EXIT[0] + 26}" y="${EXIT[1] + 290}" width="${EXIT[2] - 52}" height="260" rx="8" fill="#b88558"/>
  <rect x="${EXIT[0] + 32}" y="${EXIT[1] + 32}" width="12" height="218" rx="5" fill="#fffbf5" opacity="0.2"/>
  <circle cx="${EXIT[0] + EXIT[2] - 32}" cy="${EXIT[1] + 290}" r="12" fill="#d4a24c"/><circle cx="${EXIT[0] + EXIT[2] - 35}" cy="${EXIT[1] + 287}" r="4" fill="#fbe3a0"/>
  <rect x="${EXIT[0] + EXIT[2] - 40}" y="${EXIT[1] + 310}" width="16" height="30" rx="4" fill="#a87a2e"/>
  <!-- light switch by the door -->
  <rect x="1162" y="420" width="30" height="46" rx="5" fill="#fffbf5"/><rect x="1172" y="430" width="10" height="16" rx="3" fill="#d9c6a6"/>
  <!-- ceiling lamp -->
  <rect x="757" y="-180" width="6" height="210" fill="#7a5134"/>
  <path d="M722 70 C722 38 740 24 760 24 C780 24 798 38 798 70 Z" fill="#f6c453"/>
  <ellipse cx="760" cy="72" rx="38" ry="6" fill="#fbe3a0"/>
  <!-- baseboards -->
  <rect x="-240" y="${FLOOR_Y - 22}" width="2400" height="22" fill="#fffbf5"/>
  <rect x="-240" y="${FLOOR_Y}" width="2400" height="10" fill="#3b2e3a" opacity="0.12"/>`, "Hall background. The fanlight above the front door and the stair window are transparent holes.");
save("rooms/hall_bg.svg", bg);

save("rooms/hall_light.svg", lightLayer(
  ["127,250 363,250 560,1000 40,1000", `${sx},${sy + sh} ${sx + sw},${sy + sh} 1500,1000 1180,1000`],
  [[300, 900, 260, 70, 0.8], [1350, 900, 220, 60, 0.6]],
  "Sunbeams through the fanlight and the stair window (additive, strength follows the sunrise)."));

// ---------------------------------------------------------------- furniture
const shadow = (cx, cy, rx, ry, op = 0.18) => `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="#3b2e3a" opacity="${op}"/>`;

// Height marks on the left side of the bedroom door frame: pencil lines with Juliette's ages.
// Heights (px above the floor): 5 → 290, 7 → 330, 9 → 368, 11 → 404, 13 → 442, 15 → 478 (she first came at five).
export const HEIGHTS = [[5, 290], [7, 330], [9, 368], [11, 404], [13, 442], [15, 478]];
const marks = HEIGHTS.map(([age, h]) => {
  const y = 520 - h;
  return `<path d="M4 ${y} L40 ${y + 1}" stroke="#6b5a66" stroke-width="3" stroke-linecap="round"/>${number(age, age >= 10 ? 8 : 16, y - 27, 21, "#3e3570", 3)}`;
}).join("\n  ");
save("props/hall/height_marks.svg", svg(56, 520, `  <rect x="0" y="0" width="56" height="520" fill="#fffbf5"/>
  <rect x="50" y="0" width="6" height="520" fill="#e9d6b8"/>
  ${marks}`, "Height marks in pencil on the bedroom door frame, with Juliette's ages 5, 7, 9, 11, 13 and 15."));

save("props/hall/coat_rack.svg", svg(200, 530, `  ${shadow(100, 522, 70, 7)}
  <rect x="94" y="30" width="12" height="490" rx="5" fill="#7a5134"/>
  <rect x="96" y="30" width="4" height="480" fill="#c99a6b" opacity="0.6"/>
  <path d="M60 518 L100 470 L140 518" stroke="#7a5134" stroke-width="10" fill="none" stroke-linecap="round"/>
  <circle cx="100" cy="28" r="12" fill="#a8744a"/>
  ${[[-1, 60], [1, 60], [-1, 110], [1, 110]].map(([side, y]) => `<path d="M100 ${y} Q${100 + side * 36} ${y - 4} ${100 + side * 44} ${y - 20}" stroke="#d4a24c" stroke-width="6" fill="none" stroke-linecap="round"/>`).join("")}
  <!-- straw hats -->
  <ellipse cx="46" cy="48" rx="44" ry="12" fill="#e9c98a"/><path d="M22 46 C22 16 70 16 70 46 Z" fill="#f3ddb3"/><rect x="24" y="36" width="44" height="7" fill="#ee7b6b"/>
  <ellipse cx="156" cy="100" rx="40" ry="11" fill="#e9c98a"/><path d="M134 98 C134 72 178 72 178 98 Z" fill="#f3ddb3"/><rect x="136" y="88" width="40" height="6" fill="#2e8c8c"/>
  <!-- the beach bag, always packed -->
  <path d="M28 104 C30 80 70 80 72 104" stroke="#c8674a" stroke-width="6" fill="none"/>
  <path d="M8 130 L92 130 L84 250 L16 250 Z" fill="#f9b98a"/>
  ${[0, 1, 2, 3].map((i) => `<rect x="${10 + i * 2}" y="${148 + i * 28}" width="${80 - i * 4}" height="10" fill="#fffbf5" opacity="0.8"/>`).join("")}
  <path d="M8 130 L92 130 L90 150 L10 150 Z" fill="#e08e6d"/>
  <rect x="40" y="112" width="30" height="26" rx="4" fill="#6cc2be" transform="rotate(12 55 125)"/>
  <!-- scarf -->
  <path d="M112 118 C130 150 118 210 128 260 L140 258 C132 210 144 150 124 116 Z" fill="#9c8ac4"/>`, "Coat rack with two straw hats, the always-packed beach bag and a scarf."));

save("props/hall/console.svg", svg(260, 240, `  ${shadow(130, 234, 124, 7)}
  <rect x="24" y="40" width="10" height="190" rx="4" fill="#7a5134"/><rect x="226" y="40" width="10" height="190" rx="4" fill="#7a5134"/>
  <rect x="44" y="150" width="172" height="10" rx="4" fill="#a8744a"/>
  <rect x="8" y="20" width="244" height="26" rx="6" fill="#c99a6b"/><rect x="8" y="20" width="244" height="6" rx="3" fill="#fffbf5" opacity="0.4"/>
  <rect x="30" y="46" width="200" height="54" rx="6" fill="#b88558"/><rect x="104" y="66" width="52" height="10" rx="5" fill="#d4a24c"/>
  <!-- bowl of shells and keys -->
  <path d="M150 20 C150 4 214 4 214 20 Z" fill="#6cc2be"/><circle cx="170" cy="8" r="7" fill="#f9b98a"/><circle cx="188" cy="6" r="6" fill="#fffbf5"/><circle cx="200" cy="10" r="5" fill="#ee7b6b"/>
  <!-- basket of flip-flops underneath -->
  <rect x="60" y="176" width="140" height="54" rx="10" fill="#e9c98a"/><path d="M60 190 H200 M60 204 H200 M60 218 H200" stroke="#c99a6b" stroke-width="3"/>
  <ellipse cx="96" cy="176" rx="24" ry="8" fill="#ee7b6b"/><ellipse cx="160" cy="176" rx="24" ry="8" fill="#2e8c8c"/>`, "Console table with a drawer, a bowl of shells and a basket of flip-flops."));

save("props/hall/mirror.svg", svg(200, 260, `  <rect x="10" y="12" width="186" height="244" rx="93" fill="#3b2e3a" opacity="0.15"/>
  <rect x="2" y="2" width="186" height="244" rx="93" fill="#d4a24c"/>
  <rect x="14" y="14" width="162" height="220" rx="81" fill="#cfe3e6"/>
  <path d="M40 60 L90 20 L110 20 L40 110 Z" fill="#fffbf5" opacity="0.5"/>
  <path d="M120 200 L160 150 L166 170 L136 214 Z" fill="#fffbf5" opacity="0.3"/>`, "Round-topped brass mirror."));

save("props/hall/umbrella_stand.svg", svg(90, 220, `  ${shadow(45, 214, 40, 6)}
  <path d="M28 20 C26 60 32 90 40 110" stroke="#ee7b6b" stroke-width="8" fill="none" stroke-linecap="round"/><path d="M28 20 C20 20 18 30 24 34" stroke="#ee7b6b" stroke-width="7" fill="none" stroke-linecap="round"/>
  <path d="M62 36 C62 70 58 92 52 110" stroke="#2e8c8c" stroke-width="8" fill="none" stroke-linecap="round"/><path d="M62 36 C68 30 76 34 74 42" stroke="#2e8c8c" stroke-width="7" fill="none" stroke-linecap="round"/>
  <path d="M46 60 L46 110" stroke="#7a5134" stroke-width="6" stroke-linecap="round"/>
  <path d="M10 100 H80 L74 210 H16 Z" fill="#c8674a"/><path d="M10 100 H80 L79 118 H11 Z" fill="#e08e6d"/>
  <path d="M22 140 H68 M20 170 H70" stroke="#f6c453" stroke-width="5"/>`, "Terracotta umbrella stand with a coral and a teal umbrella and a walking stick."));

// Stairs rising to the right, with a banister and the little cupboard underneath.
const steps = 9, W = 820, H = 700;
let treads = "", balusters = "";
for (let i = 0; i < steps; i++) {
  const x = 30 + i * 60, y = H - 20 - (i + 1) * 62;
  treads += `<rect x="${x}" y="${y}" width="${W - x}" height="16" fill="#a8744a"/><rect x="${x}" y="${y}" width="${W - x}" height="5" fill="#dbb286"/><rect x="${x}" y="${y + 16}" width="${W - x}" height="46" fill="#fff4e2"/>`;
  balusters += `<rect x="${x + 24}" y="${y - 150}" width="7" height="150" rx="3" fill="#fffbf5"/>`;
}
save("props/hall/stairs.svg", svg(W, H, `  ${shadow(300, H - 6, 290, 8)}
  <path d="M0 ${H - 10} L${W} ${H - 10} L${W} 90 Z" fill="#b7cfc8"/>
  <path d="M40 ${H - 10} L${W} ${H - 10} L${W} 150 Z" fill="#a6c2ba"/>
  <!-- cupboard under the stairs -->
  <path d="M70 ${H - 12} V520 L230 400 V${H - 12} Z" fill="#8a6446"/>
  <path d="M84 ${H - 22} V527 L216 428 V${H - 22} Z" fill="#6f4f38"/>
  <circle cx="200" cy="${H - 110}" r="7" fill="#d4a24c"/>
  <path d="M112 ${H - 60} Q150 ${H - 80} 190 ${H - 60}" stroke="#3b2e3a" stroke-width="2" opacity="0.3" fill="none"/>
  ${treads}
  <path d="M0 ${H - 10} L${W} 40" stroke="#7a5134" stroke-width="28" stroke-linecap="round"/>
  ${balusters}
  <path d="M20 ${H - 190} L${W} 0" stroke="#a8744a" stroke-width="18" stroke-linecap="round"/>
  <path d="M20 ${H - 196} L${W} -6" stroke="#dbb286" stroke-width="5" stroke-linecap="round"/>
  <rect x="6" y="${H - 220}" width="30" height="210" rx="6" fill="#a8744a"/><circle cx="21" cy="${H - 226}" r="18" fill="#c99a6b"/>`, "Stairs going up to the right, with a white banister and a little cupboard underneath."));

console.log("hall art written");
