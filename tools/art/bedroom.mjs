// Generates the bedroom art (background, light layer, furniture). The SVG files are the editable source;
// re-running this overwrites them:  node tools/art/bedroom.mjs
// The bedroom is "Henri" (docs/STORY.md): the quilt from their old shirts, the wedding photo, the jewellery
// box they danced to, the suitcase with stickers from their trips, Henri's side of the bed.
import { save, svg, roomSvg, woodFloor, wallWithHoles, frame, glassReflections, lightLayer, number } from "./room_kit.mjs";

const FLOOR_Y = 770;
const WINDOW = [700, 120, 380, 300];
const EXIT = [1640, 190, 230, 580];

const stripes = () => {
  const out = [];
  for (let x = -230; x < 2160; x += 60) out.push(`<rect x="${x}" y="70" width="22" height="${FLOOR_Y - 70}" fill="#fffbf5" opacity="0.18"/>`);
  for (let x = -200; x < 2160; x += 120) for (let y = 110; y < FLOOR_Y - 40; y += 90) out.push(`<circle cx="${x}" cy="${y + ((x / 120) % 2) * 45}" r="4" fill="#9c8ac4" opacity="0.25"/>`);
  return out.join("");
};

const bg = roomSvg(`  <defs>
    <linearGradient id="ceiling" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e5d9e6"/><stop offset="1" stop-color="#f3eaf1"/></linearGradient>
    <linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e8def0"/><stop offset="1" stop-color="#d9cbe6"/></linearGradient>
    <linearGradient id="floorShade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3b2e3a" stop-opacity="0.22"/><stop offset="0.35" stop-color="#3b2e3a" stop-opacity="0"/><stop offset="1" stop-color="#3b2e3a" stop-opacity="0.2"/></linearGradient>
    <linearGradient id="curtain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6cc2be"/><stop offset="0.5" stop-color="#2e8c8c"/><stop offset="1" stop-color="#6cc2be"/></linearGradient>
    <linearGradient id="wood" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#c99a6b"/><stop offset="1" stop-color="#a8744a"/></linearGradient>
  </defs>
  <rect x="-240" y="-180" width="2400" height="250" fill="url(#ceiling)"/>
  <rect x="-240" y="50" width="2400" height="16" fill="#fffbf5"/>
  <g>
  ${woodFloor(FLOOR_Y, 1260, ["#b98a5e", "#c99a6b", "#b3845a", "#c4966a"], "#7a5134", 21)}
  </g>
  <rect x="-240" y="${FLOOR_Y}" width="2400" height="490" fill="url(#floorShade)"/>
  <!-- round rug in front of the bed -->
  <ellipse cx="910" cy="1010" rx="560" ry="150" fill="#9c8ac4"/>
  <ellipse cx="910" cy="1010" rx="500" ry="126" fill="#c9bde3"/>
  <ellipse cx="910" cy="1010" rx="380" ry="92" fill="none" stroke="#fffbf5" stroke-width="8" opacity="0.6"/>
  ${wallWithHoles(-240, 66, 2160, FLOOR_Y, [WINDOW], "url(#wall)")}
  ${stripes()}
  <!-- window with curtains -->
  ${frame(WINDOW, 18, "#fffbf5")}
  <rect x="${WINDOW[0] + WINDOW[2] / 2 - 8}" y="${WINDOW[1]}" width="16" height="${WINDOW[3]}" fill="#fffbf5"/>
  <rect x="${WINDOW[0]}" y="${WINDOW[1] + 150}" width="${WINDOW[2]}" height="12" fill="#fffbf5"/>
  ${glassReflections(WINDOW)}
  <rect x="${WINDOW[0] - 30}" y="${WINDOW[1] + WINDOW[3]}" width="${WINDOW[2] + 60}" height="22" rx="4" fill="#fffbf5"/>
  <rect x="${WINDOW[0] - 30}" y="${WINDOW[1] + WINDOW[3] + 20}" width="${WINDOW[2] + 60}" height="8" fill="#3b2e3a" opacity="0.08"/>
  <rect x="${WINDOW[0] - 90}" y="84" width="${WINDOW[2] + 180}" height="14" rx="7" fill="#a87a2e"/>
  <circle cx="${WINDOW[0] - 90}" cy="91" r="12" fill="#d4a24c"/><circle cx="${WINDOW[0] + WINDOW[2] + 90}" cy="91" r="12" fill="#d4a24c"/>
  <path d="M${WINDOW[0] - 80} 94 C${WINDOW[0] - 60} 300 ${WINDOW[0] - 90} 460 ${WINDOW[0] - 40} 600 L${WINDOW[0] + 20} 600 C${WINDOW[0] + 10} 440 ${WINDOW[0] + 40} 260 ${WINDOW[0] + 30} 94 Z" fill="url(#curtain)"/>
  <path d="M${WINDOW[0] + WINDOW[2] + 80} 94 C${WINDOW[0] + WINDOW[2] + 60} 300 ${WINDOW[0] + WINDOW[2] + 90} 460 ${WINDOW[0] + WINDOW[2] + 40} 600 L${WINDOW[0] + WINDOW[2] - 20} 600 C${WINDOW[0] + WINDOW[2] - 10} 440 ${WINDOW[0] + WINDOW[2] - 40} 260 ${WINDOW[0] + WINDOW[2] - 30} 94 Z" fill="url(#curtain)"/>
  <rect x="${WINDOW[0] - 64}" y="330" width="92" height="16" rx="8" fill="#d4a24c"/><rect x="${WINDOW[0] + WINDOW[2] - 28}" y="330" width="92" height="16" rx="8" fill="#d4a24c"/>
  <!-- the door to the living room -->
  ${frame(EXIT, 22, "#fffbf5")}
  <rect x="${EXIT[0]}" y="${EXIT[1]}" width="${EXIT[2]}" height="${EXIT[3]}" fill="url(#wood)"/>
  <rect x="${EXIT[0] + 24}" y="${EXIT[1] + 24}" width="${EXIT[2] - 48}" height="220" rx="8" fill="#b88558"/>
  <rect x="${EXIT[0] + 24}" y="${EXIT[1] + 280}" width="${EXIT[2] - 48}" height="270" rx="8" fill="#b88558"/>
  <circle cx="${EXIT[0] + EXIT[2] - 30}" cy="${EXIT[1] + 290}" r="12" fill="#d4a24c"/><circle cx="${EXIT[0] + EXIT[2] - 33}" cy="${EXIT[1] + 287}" r="4" fill="#fbe3a0"/>
  <!-- Henri's dressing gown on the door -->
  <path d="M${EXIT[0] + 60} ${EXIT[1] + 60} C${EXIT[0] + 40} ${EXIT[1] + 160} ${EXIT[0] + 50} ${EXIT[1] + 300} ${EXIT[0] + 70} ${EXIT[1] + 360} L${EXIT[0] + 150} ${EXIT[1] + 360} C${EXIT[0] + 160} ${EXIT[1] + 300} ${EXIT[0] + 160} ${EXIT[1] + 160} ${EXIT[0] + 140} ${EXIT[1] + 60} Z" fill="#3e3570" opacity="0.85"/>
  <circle cx="${EXIT[0] + 100}" cy="${EXIT[1] + 58}" r="8" fill="#d4a24c"/>
  <!-- ceiling lamp -->
  <rect x="1497" y="-180" width="6" height="200" fill="#7a5134"/>
  <ellipse cx="1500" cy="40" rx="70" ry="22" fill="#fcd9b8"/><ellipse cx="1500" cy="52" rx="60" ry="10" fill="#fbe3a0"/>
  <!-- baseboards -->
  <rect x="-240" y="${FLOOR_Y - 22}" width="2400" height="22" fill="#fffbf5"/>
  <rect x="-240" y="${FLOOR_Y}" width="2400" height="10" fill="#3b2e3a" opacity="0.12"/>`, "Bedroom background: lavender striped walls, the window between curtains is a transparent hole.");
save("rooms/bedroom_bg.svg", bg);

save("rooms/bedroom_light.svg", lightLayer(
  [`${WINDOW[0]},${WINDOW[1] + WINDOW[3]} ${WINDOW[0] + WINDOW[2]},${WINDOW[1] + WINDOW[3]} 1400,1100 760,1100`],
  [[890, 980, 420, 110, 1]],
  "Sunbeam through the bedroom window onto the rug and the quilt."));

// ---------------------------------------------------------------- furniture
const shadow = (cx, cy, rx, ry, op = 0.18) => `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="#3b2e3a" opacity="${op}"/>`;

// Wardrobe with a suitcase and a hat box on top.
save("props/bedroom/wardrobe.svg", svg(300, 620, `  ${shadow(150, 612, 146, 8)}
  <!-- suitcase with stickers -->
  <rect x="40" y="20" width="200" height="90" rx="12" fill="#c8674a"/>
  <rect x="40" y="20" width="200" height="12" rx="6" fill="#e08e6d"/>
  <rect x="120" y="4" width="40" height="20" rx="8" fill="none" stroke="#7a5134" stroke-width="7"/>
  <rect x="128" y="58" width="24" height="18" rx="4" fill="#d4a24c"/>
  <circle cx="80" cy="66" r="16" fill="#f6c453"/><rect x="172" y="46" width="44" height="30" rx="4" fill="#6cc2be" transform="rotate(-8 194 61)"/>
  <circle cx="200" cy="88" r="10" fill="#fffbf5"/>
  <!-- hat box -->
  <ellipse cx="258" cy="84" rx="38" ry="10" fill="#e59a7c"/><rect x="220" y="84" width="76" height="26" fill="#f9b98a"/>
  <!-- wardrobe body -->
  <rect x="6" y="110" width="288" height="500" rx="10" fill="#a8744a"/>
  <rect x="0" y="108" width="300" height="20" rx="6" fill="#7a5134"/>
  <rect x="20" y="140" width="124" height="440" rx="8" fill="#c99a6b"/><rect x="156" y="140" width="124" height="440" rx="8" fill="#c99a6b"/>
  <rect x="36" y="160" width="92" height="180" rx="6" fill="#b88558"/><rect x="172" y="160" width="92" height="180" rx="6" fill="#b88558"/>
  <rect x="36" y="370" width="92" height="190" rx="6" fill="#b88558"/><rect x="172" y="370" width="92" height="190" rx="6" fill="#b88558"/>
  <rect x="134" y="330" width="8" height="46" rx="4" fill="#d4a24c"/><rect x="158" y="330" width="8" height="46" rx="4" fill="#d4a24c"/>
  <rect x="24" y="146" width="10" height="420" rx="5" fill="#fffbf5" opacity="0.18"/>
  <rect x="20" y="596" width="30" height="16" rx="4" fill="#7a5134"/><rect x="250" y="596" width="30" height="16" rx="4" fill="#7a5134"/>`, "Wooden wardrobe with a coral suitcase full of travel stickers and a hat box on top."));

// Big bed with the patchwork quilt Céline sewed from their old shirts.
const patches = () => {
  const cols = ["#f9b98a", "#9c8ac4", "#6cc2be", "#f6c453", "#ee7b6b", "#8faf8a", "#fcd9b8", "#c9bde3"];
  let s = "";
  let k = 0;
  for (let r = 0; r < 4; r++) for (let c = 0; c < 7; c++) {
    const y = 250 + r * 50, x0 = 36 - r * 6, w = (548 + r * 12) / 7;
    s += `<rect x="${(x0 + c * w).toFixed(1)}" y="${y}" width="${(w - 3).toFixed(1)}" height="47" fill="${cols[(k++ * 3) % cols.length]}"/>`;
  }
  return s;
};
save("props/bedroom/bed.svg", svg(620, 500, `  ${shadow(310, 490, 300, 12, 0.22)}
  <!-- headboard -->
  <rect x="40" y="0" width="540" height="240" rx="60" fill="#7c6ab0"/>
  <rect x="60" y="20" width="500" height="210" rx="50" fill="#9c8ac4"/>
  ${[0, 1, 2, 3, 4].map((i) => `<circle cx="${130 + i * 90}" cy="90" r="6" fill="#7c6ab0"/><circle cx="${175 + i * 90}" cy="150" r="6" fill="#7c6ab0"/>`).join("")}
  <!-- pillows -->
  <rect x="90" y="150" width="200" height="80" rx="30" fill="#fffbf5"/><rect x="330" y="150" width="200" height="80" rx="30" fill="#fff4e2"/>
  <rect x="104" y="160" width="60" height="12" rx="6" fill="#ffffff" opacity="0.7"/>
  <!-- quilt -->
  <path d="M30 240 H590 L610 450 H10 Z" fill="#fff4e2"/>
  ${patches()}
  <path d="M10 450 H610 L612 470 H8 Z" fill="#e9d6b8"/>
  <!-- frame and the dark gap under the bed -->
  <rect x="0" y="466" width="620" height="18" rx="6" fill="#7a5134"/>
  <rect x="20" y="484" width="580" height="12" fill="#3b2e3a" opacity="0.55"/>
  <rect x="6" y="470" width="20" height="30" rx="4" fill="#5e3e28"/><rect x="594" y="470" width="20" height="30" rx="4" fill="#5e3e28"/>`, "Big bed with a buttoned lavender headboard and a patchwork quilt; a dark gap under the frame."));

save("props/bedroom/nightstand.svg", svg(160, 330, `  ${shadow(80, 322, 72, 6)}
  <!-- lamp -->
  <rect x="74" y="60" width="10" height="70" fill="#d4a24c"/>
  <path d="M34 70 L124 70 L106 6 L52 6 Z" fill="#fcd9b8"/><path d="M34 70 L124 70 L121 60 L37 60 Z" fill="#f9b98a"/>
  <ellipse cx="80" cy="132" rx="30" ry="8" fill="#a87a2e"/>
  <!-- Henri's glasses -->
  <circle cx="34" cy="126" r="10" fill="none" stroke="#3b2e3a" stroke-width="3"/><circle cx="58" cy="128" r="10" fill="none" stroke="#3b2e3a" stroke-width="3"/><path d="M44 126 L48 126" stroke="#3b2e3a" stroke-width="3"/>
  <!-- table -->
  <rect x="6" y="140" width="148" height="20" rx="5" fill="#c99a6b"/>
  <rect x="16" y="160" width="128" height="150" rx="6" fill="#a8744a"/>
  <rect x="26" y="172" width="108" height="56" rx="5" fill="#c99a6b"/><rect x="62" y="194" width="36" height="9" rx="4" fill="#d4a24c"/>
  <rect x="26" y="238" width="108" height="60" rx="5" fill="#b88558"/>
  <rect x="20" y="306" width="14" height="18" fill="#7a5134"/><rect x="126" y="306" width="14" height="18" fill="#7a5134"/>`, "Nightstand with a lamp, Henri's reading glasses and a drawer."));

save("props/bedroom/dressing_table.svg", svg(230, 360, `  ${shadow(115, 352, 108, 7)}
  <!-- round mirror -->
  <circle cx="115" cy="80" r="74" fill="#d4a24c"/><circle cx="115" cy="80" r="64" fill="#cfe3e6"/>
  <path d="M80 40 L120 20 L70 90 Z" fill="#fffbf5" opacity="0.5"/>
  <rect x="108" y="150" width="14" height="50" fill="#d4a24c"/>
  <!-- perfume bottles and the jewellery box -->
  <rect x="22" y="170" width="20" height="30" rx="5" fill="#c9bde3"/><circle cx="32" cy="164" r="7" fill="#d4a24c"/>
  <rect x="48" y="178" width="16" height="22" rx="4" fill="#fcd9b8"/><circle cx="56" cy="173" r="5" fill="#d4a24c"/>
  <rect x="140" y="164" width="76" height="36" rx="6" fill="#ee7b6b"/><rect x="136" y="156" width="84" height="14" rx="6" fill="#c95b52"/>
  <circle cx="178" cy="182" r="6" fill="#f6c453"/><path d="M204 160 L214 146" stroke="#d4a24c" stroke-width="4" stroke-linecap="round"/>
  <!-- table -->
  <rect x="4" y="200" width="222" height="20" rx="6" fill="#fffbf5"/>
  <rect x="14" y="220" width="202" height="60" rx="6" fill="#e9dff0"/>
  <rect x="24" y="230" width="84" height="40" rx="5" fill="#fff4e2"/><rect x="122" y="230" width="84" height="40" rx="5" fill="#fff4e2"/>
  <circle cx="66" cy="250" r="5" fill="#d4a24c"/><circle cx="164" cy="250" r="5" fill="#d4a24c"/>
  <path d="M24 280 C20 310 18 330 16 350 M206 280 C210 310 212 330 214 350" stroke="#e9dff0" stroke-width="12" stroke-linecap="round"/>`, "White dressing table with a round mirror, perfume bottles and a coral jewellery box that plays a tune."));

// The wedding photo above the bed: Céline and Henri under the little lemon tree, June 1960.
save("props/bedroom/wedding_photo.svg", svg(190, 170, `  <rect x="8" y="10" width="180" height="158" rx="6" fill="#3b2e3a" opacity="0.18"/>
  <rect x="2" y="2" width="180" height="158" rx="6" fill="#d4a24c"/>
  <rect x="14" y="14" width="156" height="110" fill="#f3e6cf"/>
  <rect x="14" y="94" width="156" height="30" fill="#c9d6bd"/>
  <!-- the little lemon tree with its stick -->
  <path d="M132 118 L132 70" stroke="#7a5134" stroke-width="4"/><path d="M140 118 L140 60" stroke="#a8744a" stroke-width="2"/>
  <circle cx="132" cy="62" r="16" fill="#8faf8a"/><circle cx="126" cy="60" r="3" fill="#f6c453"/><circle cx="138" cy="66" r="3" fill="#f6c453"/>
  <!-- Henri and Céline -->
  <rect x="58" y="60" width="26" height="58" rx="8" fill="#3e3570"/><circle cx="71" cy="48" r="11" fill="#e0b48c"/><path d="M60 42 C62 32 80 32 82 42 Z" fill="#3b2e3a"/>
  <path d="M88 118 L96 64 L112 64 L120 118 Z" fill="#fffbf5"/><circle cx="104" cy="52" r="11" fill="#e0b48c"/><path d="M92 50 C92 36 116 36 116 50 C116 44 110 40 104 40 C98 40 94 44 92 50 Z" fill="#7a5134"/>
  <path d="M94 44 C100 30 112 34 116 44" stroke="#fffbf5" stroke-width="6" fill="none" opacity="0.8"/>
  <circle cx="90" cy="84" r="6" fill="#ee7b6b"/><circle cx="96" cy="88" r="5" fill="#f6c453"/>
  <!-- the date written under the photo -->
  <rect x="14" y="128" width="156" height="24" fill="#fff4e2"/>
  ${number(1960, 60, 130, 18, "#3e3570", 2.6)}`, "Wedding photo: Henri and Céline under the little lemon tree, with 1960 written underneath."));

console.log("bedroom art written");
