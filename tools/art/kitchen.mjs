// Generates the Kitchen & Bar art (background, light layer, furniture). The SVG files are the editable source;
// re-running this overwrites them:  node tools/art/kitchen.mjs
import { save, svg, roomSvg, checkerFloor, wallWithHoles, frame, glassReflections, lightLayer, rng } from "./room_kit.mjs";

const WINDOW = [760, 160, 400, 360];
const DOOR = [170, 110, 260, 660];
const FLOOR_Y = 770;

// ---------------------------------------------------------------- zellige backsplash tiles
function tiles() {
  const r = rng(11);
  const cols = ["#6cc2be", "#7fcbc6", "#5fb6b2", "#8ad2cc"];
  const out = [];
  const size = 38;
  for (let y = 330; y < 548; y += size) {
    for (let x = 470; x < 1640; x += size) {
      const inWindow = x + size > WINDOW[0] - 20 && x < WINDOW[0] + WINDOW[2] + 20 && y < WINDOW[1] + WINDOW[3] + 22;
      if (inWindow) continue;
      const c = cols[Math.floor(r() * cols.length)];
      out.push(`<rect x="${x + 1.5}" y="${y + 1.5}" width="${size - 3}" height="${size - 3}" rx="3" fill="${c}"/>`);
      if (r() < 0.5) out.push(`<rect x="${x + 5}" y="${y + 5}" width="${size - 18}" height="5" rx="2" fill="#fffbf5" opacity="0.35"/>`);
    }
  }
  return out.join("\n  ");
}

const bg = roomSvg(`  <defs>
    <linearGradient id="ceiling" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ead5b6"/><stop offset="1" stop-color="#f6e7cf"/></linearGradient>
    <linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff4e2"/><stop offset="1" stop-color="#f4e0c2"/></linearGradient>
    <linearGradient id="floorShade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3b2e3a" stop-opacity="0.2"/><stop offset="0.3" stop-color="#3b2e3a" stop-opacity="0"/><stop offset="1" stop-color="#3b2e3a" stop-opacity="0.18"/></linearGradient>
    <linearGradient id="brass" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f0c877"/><stop offset="1" stop-color="#a87a2e"/></linearGradient>
  </defs>
  <rect x="-240" y="-180" width="2400" height="252" fill="url(#ceiling)"/>
  <rect x="-240" y="54" width="2400" height="16" fill="#fffbf5"/>
  <rect x="-240" y="70" width="2400" height="12" fill="#3b2e3a" opacity="0.06"/>
  <g>
  ${checkerFloor(FLOOR_Y, 1260, "#f3ddb3", "#e59a7c", "#c8674a")}
  </g>
  <rect x="-240" y="${FLOOR_Y}" width="2400" height="490" fill="url(#floorShade)"/>
  ${wallWithHoles(-240, 70, 2160, FLOOR_Y, [WINDOW, DOOR], "url(#wall)")}
  <!-- backsplash -->
  <rect x="468" y="328" width="274" height="222" fill="#fffbf5"/>
  <rect x="1178" y="328" width="464" height="222" fill="#fffbf5"/>
  <rect x="742" y="536" width="436" height="14" fill="#fffbf5"/>
  ${tiles()}
  <!-- window over the sink -->
  ${frame(WINDOW, 18, "#fffbf5")}
  <rect x="952" y="160" width="16" height="360" fill="#fffbf5"/>
  ${glassReflections(WINDOW)}
  <rect x="744" y="518" width="432" height="20" rx="4" fill="#fffbf5"/>
  <rect x="744" y="536" width="432" height="8" fill="#3b2e3a" opacity="0.08"/>
  <!-- herbs on the sill -->
  <rect x="770" y="480" width="44" height="40" rx="6" fill="#c8674a"/><rect x="766" y="476" width="52" height="10" rx="5" fill="#e08e6d"/>
  <ellipse cx="782" cy="462" rx="12" ry="18" fill="#5e7f5e"/><ellipse cx="800" cy="458" rx="12" ry="22" fill="#8faf8a"/><ellipse cx="792" cy="448" rx="9" ry="16" fill="#a9c7a3"/>
  <!-- balcony door (left) -->
  ${frame(DOOR, 20, "#fffbf5")}
  <rect x="${DOOR[0]}" y="${DOOR[1]}" width="${DOOR[2]}" height="12" fill="#fffbf5"/>
  <rect x="${DOOR[0]}" y="${DOOR[1]}" width="14" height="${DOOR[3]}" fill="#fffbf5"/>
  <rect x="${DOOR[0] + DOOR[2] - 14}" y="${DOOR[1]}" width="14" height="${DOOR[3]}" fill="#fffbf5"/>
  ${glassReflections(DOOR)}
  <rect x="402" y="384" width="12" height="136" rx="6" fill="#a87a2e"/>
  <rect x="403" y="386" width="5" height="130" rx="2" fill="#f0c877" opacity="0.8"/>
  <rect x="146" y="${FLOOR_Y - 12}" width="308" height="16" rx="3" fill="#a87a2e"/>
  <!-- pendant lights -->
  <rect x="797" y="-180" width="6" height="250" fill="#7a5134"/>
  <path d="M760 110 C760 80 780 66 800 66 C820 66 840 80 840 110 Z" fill="url(#brass)"/>
  <ellipse cx="800" cy="112" rx="40" ry="6" fill="#fbe3a0"/>
  <rect x="1117" y="-180" width="6" height="250" fill="#7a5134"/>
  <path d="M1080 110 C1080 80 1100 66 1120 66 C1140 66 1160 80 1160 110 Z" fill="url(#brass)"/>
  <ellipse cx="1120" cy="112" rx="40" ry="6" fill="#fbe3a0"/>
  <!-- baseboards where no furniture stands -->
  <rect x="-240" y="${FLOOR_Y - 24}" width="390" height="24" fill="#fffbf5"/>
  <rect x="450" y="${FLOOR_Y - 24}" width="30" height="24" fill="#fffbf5"/>
  <rect x="1640" y="${FLOOR_Y - 24}" width="520" height="24" fill="#fffbf5"/>
  <rect x="-240" y="${FLOOR_Y}" width="2400" height="10" fill="#3b2e3a" opacity="0.12"/>`, "Kitchen & Bar background. Window over the sink and the balcony door (left) are transparent holes.");
save("rooms/kitchen_bg.svg", bg);

save("rooms/kitchen_light.svg", lightLayer(
  ["760,520 952,520 880,1100 520,1100", "968,520 1160,520 1420,1100 1060,1100", "184,770 416,770 520,1150 120,1150"],
  [[960, 860, 520, 110, 1], [300, 900, 220, 70, 0.7]],
  "Sunbeams through the kitchen window and balcony door (additive, strength follows the sunrise)."));

// ---------------------------------------------------------------- furniture
const shadow = (cx, cy, rx, ry, op = 0.18) => `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="#3b2e3a" opacity="${op}"/>`;
const door = (x, y, w, h, fill, inset, knobX, knobY) => `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="8" fill="${fill}"/>
  <rect x="${x + 12}" y="${y + 12}" width="${w - 24}" height="${h - 24}" rx="5" fill="${inset}"/>
  <circle cx="${knobX}" cy="${knobY}" r="7" fill="#d4a24c"/><circle cx="${knobX - 2}" cy="${knobY - 2}" r="2.5" fill="#fbe3a0"/>`;

save("props/kitchen/counter.svg", svg(1180, 300, `  ${shadow(590, 292, 580, 10)}
  <!-- sink faucet -->
  <path d="M600 58 V16 C600 2 626 2 626 16 V26" stroke="#a87a2e" stroke-width="9" fill="none" stroke-linecap="round"/>
  <rect x="586" y="44" width="30" height="16" rx="4" fill="#d4a24c"/>
  <!-- countertop -->
  <rect x="0" y="60" width="1180" height="30" rx="6" fill="#c99a6b"/>
  <rect x="0" y="60" width="1180" height="6" rx="3" fill="#fffbf5" opacity="0.35"/>
  <ellipse cx="600" cy="66" rx="150" ry="9" fill="#6b5a66"/>
  <ellipse cx="600" cy="64" rx="140" ry="6" fill="#4d3d4b"/>
  <!-- cabinets -->
  <rect x="10" y="90" width="1160" height="198" fill="#8faf8a"/>
  <rect x="10" y="90" width="1160" height="8" fill="#3b2e3a" opacity="0.12"/>
  ${door(22, 104, 172, 170, "#9fbe9a", "#8faf8a", 180, 190)}
  ${door(202, 104, 172, 170, "#9fbe9a", "#8faf8a", 216, 190)}
  ${door(392, 104, 196, 170, "#9fbe9a", "#8faf8a", 574, 190)}
  ${door(596, 104, 196, 170, "#9fbe9a", "#8faf8a", 610, 190)}
  <rect x="806" y="104" width="352" height="52" rx="8" fill="#9fbe9a"/><rect x="946" y="124" width="72" height="10" rx="5" fill="#d4a24c"/>
  <rect x="806" y="164" width="352" height="52" rx="8" fill="#9fbe9a"/><rect x="946" y="184" width="72" height="10" rx="5" fill="#d4a24c"/>
  <rect x="806" y="224" width="352" height="52" rx="8" fill="#9fbe9a"/><rect x="946" y="244" width="72" height="10" rx="5" fill="#d4a24c"/>
  <rect x="10" y="284" width="1160" height="14" fill="#5e7f5e"/>`, "Sage kitchen counter: cabinets left, sink in the middle, drawers right."));

save("props/kitchen/fridge.svg", svg(250, 530, `  ${shadow(125, 522, 118, 8)}
  <rect x="0" y="0" width="250" height="520" rx="42" fill="#6cc2be"/>
  <rect x="14" y="10" width="20" height="490" rx="10" fill="#a6e0dc" opacity="0.6"/>
  <rect x="10" y="163" width="230" height="6" fill="#2e8c8c" opacity="0.6"/>
  <rect x="26" y="52" width="14" height="80" rx="7" fill="#e9e6f2"/><rect x="28" y="54" width="5" height="74" rx="2" fill="#fffbf5"/>
  <rect x="26" y="196" width="14" height="110" rx="7" fill="#e9e6f2"/><rect x="28" y="198" width="5" height="104" rx="2" fill="#fffbf5"/>
  <rect x="100" y="126" width="54" height="16" rx="8" fill="#d4a24c"/>
  <!-- magnets -->
  <g transform="translate(66 300)">
    <ellipse cx="30" cy="20" rx="20" ry="15" fill="#f6c453"/><path d="M40 6 C46 0 56 2 56 8 C50 8 46 8 40 6 Z" fill="#8faf8a"/>
    <circle cx="96" cy="18" r="16" fill="#fffbf5"/><circle cx="96" cy="18" r="6" fill="#f6c453"/>
    <path d="M140 30 C120 18 118 6 126 0 C132 -4 138 0 140 6 C142 0 148 -4 154 0 C162 6 160 18 140 30 Z" fill="#ee7b6b"/>
    <rect x="12" y="62" width="40" height="30" rx="6" fill="#9c8ac4"/><rect x="18" y="68" width="28" height="18" rx="3" fill="#fffbf5"/>
    <circle cx="96" cy="78" r="15" fill="#2e8c8c"/><path d="M88 78 C92 70 100 70 104 78" stroke="#fffbf5" stroke-width="3" fill="none"/>
    <rect x="124" y="60" width="34" height="40" rx="4" fill="#fcd9b8"/><path d="M130 72 H152 M130 80 H148 M130 88 H150" stroke="#c8674a" stroke-width="2"/>
  </g>
  <rect x="40" y="508" width="30" height="14" rx="4" fill="#3b2e3a" opacity="0.5"/><rect x="180" y="508" width="30" height="14" rx="4" fill="#3b2e3a" opacity="0.5"/>`, "Retro mint fridge with a freezer on top and colourful magnets."));

save("props/kitchen/espresso.svg", svg(180, 190, `  ${shadow(90, 184, 80, 6)}
  <rect x="10" y="18" width="160" height="34" rx="12" fill="#c95b52"/>
  <rect x="20" y="40" width="140" height="140" rx="18" fill="#ee7b6b"/>
  <rect x="28" y="48" width="18" height="120" rx="9" fill="#fcd9b8" opacity="0.5"/>
  <circle cx="126" cy="80" r="18" fill="#fffbf5"/><circle cx="126" cy="80" r="14" fill="#fff4e2"/>
  <line x1="126" y1="80" x2="134" y2="72" stroke="#3b2e3a" stroke-width="3" stroke-linecap="round"/>
  <rect x="58" y="96" width="60" height="18" rx="6" fill="#d4a24c"/>
  <rect x="44" y="104" width="90" height="10" rx="5" fill="#a87a2e"/>
  <rect x="30" y="160" width="120" height="16" rx="5" fill="#6b5a66"/>
  <path d="M72 140 H106 V156 C106 164 72 164 72 156 Z" fill="#fffbf5"/>
  <path d="M106 144 C116 144 116 154 106 154" stroke="#fffbf5" stroke-width="4" fill="none"/>`, "Coral espresso machine with a cup on the drip tray."));

save("props/kitchen/spice_rack.svg", svg(230, 160, `  <rect x="6" y="8" width="226" height="152" rx="8" fill="#3b2e3a" opacity="0.12"/>
  <rect x="0" y="0" width="226" height="152" rx="8" fill="#a8744a"/>
  <rect x="10" y="10" width="206" height="132" rx="4" fill="#ecd6b4"/>
  <rect x="10" y="72" width="206" height="10" fill="#a8744a"/>
  ${[0, 1, 2, 3, 4].map(i => `<rect x="${18 + i * 40}" y="${30}" width="30" height="42" rx="6" fill="#fffbf5" opacity="0.9"/>
  <rect x="${18 + i * 40}" y="${24}" width="30" height="10" rx="4" fill="${["#ee7b6b", "#f6c453", "#8faf8a", "#9c8ac4", "#2e8c8c"][i]}"/>
  <rect x="${22 + i * 40}" y="${44}" width="22" height="20" rx="3" fill="${["#c8674a", "#f6c453", "#5e7f5e", "#c95b52", "#a8744a"][i]}" opacity="0.8"/>`).join("\n  ")}
  ${[0, 1, 2, 3, 4].map(i => `<rect x="${18 + i * 40}" y="${96}" width="30" height="42" rx="6" fill="#fffbf5" opacity="0.9"/>
  <rect x="${18 + i * 40}" y="${90}" width="30" height="10" rx="4" fill="${["#2e8c8c", "#9c8ac4", "#ee7b6b", "#f6c453", "#8faf8a"][i]}"/>
  <rect x="${22 + i * 40}" y="${110}" width="22" height="20" rx="3" fill="${["#e08e6d", "#6b5a66", "#f9b98a", "#8faf8a", "#c99a6b"][i]}" opacity="0.8"/>`).join("\n  ")}`, "Wooden spice rack with ten little jars."));

save("props/kitchen/island.svg", svg(880, 230, `  ${shadow(440, 226, 430, 8, 0.2)}
  <rect x="14" y="30" width="852" height="196" fill="#c99a6b"/>
  ${Array.from({ length: 20 }, (_, i) => `<rect x="${30 + i * 42}" y="104" width="4" height="118" fill="#a8744a" opacity="0.6"/>`).join("")}
  <rect x="30" y="46" width="400" height="52" rx="8" fill="#dbb286"/><rect x="190" y="66" width="80" height="10" rx="5" fill="#d4a24c"/>
  <rect x="450" y="46" width="400" height="52" rx="8" fill="#dbb286"/><rect x="610" y="66" width="80" height="10" rx="5" fill="#d4a24c"/>
  <rect x="0" y="0" width="880" height="36" rx="10" fill="#f3ddb3"/>
  <rect x="0" y="0" width="880" height="10" rx="5" fill="#fffbf5" opacity="0.7"/>
  <path d="M60 20 C120 14 160 26 220 18 M520 22 C580 14 640 28 700 20" stroke="#d9bd8c" stroke-width="2" fill="none"/>`, "Kitchen island with a marble top and two drawers."));

save("props/kitchen/fruit_bowl.svg", svg(210, 120, `  ${shadow(105, 114, 90, 6)}
  <circle cx="64" cy="54" r="22" fill="#f6c453"/><circle cx="58" cy="48" r="6" fill="#fbe3a0"/>
  <circle cx="104" cy="44" r="24" fill="#f9b98a"/><circle cx="98" cy="38" r="6" fill="#fcd9b8"/>
  <circle cx="146" cy="54" r="22" fill="#f6c453"/>
  <path d="M104 22 C100 10 110 4 116 8 C110 12 108 16 106 22 Z" fill="#8faf8a"/>
  <path d="M16 62 H194 C190 96 150 112 105 112 C60 112 20 96 16 62 Z" fill="#e08e6d"/>
  <path d="M16 62 H194 C193 70 190 76 186 80 H24 C20 76 17 70 16 62 Z" fill="#c8674a"/>
  <path d="M40 92 C70 100 140 100 170 92" stroke="#fcd9b8" stroke-width="4" fill="none" opacity="0.7"/>`, "Terracotta bowl of lemons and a peach."));

console.log("kitchen art written");
