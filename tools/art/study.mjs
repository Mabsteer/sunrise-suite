// Generates the furniture first drawn for the (retired) study: grandfather clock, globe, desk, bookcase, trunk, world map.
// re-running this overwrites them:  node tools/art/study.mjs
import { save, svg, roomSvg, woodFloor, wallWithHoles, glassReflections, lightLayer } from "./room_kit.mjs";

const LEAF_L = [760, 110, 190, 650];
const LEAF_R = [970, 110, 190, 650];
const FLOOR_Y = 760;

const stripes = Array.from({ length: 70 }, (_, i) => -240 + i * 36).filter(x => x < 734 || x > 1186).map(x => `<rect x="${x}" y="70" width="6" height="410" fill="#cbbfdf" opacity="0.7"/>`).join("");
const panels = Array.from({ length: 13 }, (_, i) => {
  const x = -220 + i * 190;
  if (x > 700 && x < 1180) return "";
  return `<rect x="${x}" y="520" width="160" height="200" rx="6" fill="none" stroke="#c99a6b" stroke-width="6"/><rect x="${x + 8}" y="528" width="144" height="10" fill="#3b2e3a" opacity="0.12"/>`;
}).join("\n  ");
const muntins = [LEAF_L, LEAF_R].map(([x, y, w, h]) => [270, 430, 590].map(my => `<rect x="${x}" y="${my}" width="${w}" height="10" fill="#fffbf5"/>`).join("") + `<rect x="${x + w / 2 - 5}" y="${y}" width="10" height="${h}" fill="#fffbf5" opacity="0"/>`).join("");

const bg = roomSvg(`  <defs>
    <linearGradient id="ceiling" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#dcc6ab"/><stop offset="1" stop-color="#eddcc4"/></linearGradient>
    <linearGradient id="paper" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e2d8ef"/><stop offset="1" stop-color="#d4c8e6"/></linearGradient>
    <linearGradient id="wood" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#a8744a"/><stop offset="1" stop-color="#8f6441"/></linearGradient>
    <linearGradient id="floorShade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3b2e3a" stop-opacity="0.28"/><stop offset="0.3" stop-color="#3b2e3a" stop-opacity="0"/><stop offset="1" stop-color="#3b2e3a" stop-opacity="0.22"/></linearGradient>
    <linearGradient id="velvet" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1f5f6b"/><stop offset="0.5" stop-color="#2e8c8c"/><stop offset="1" stop-color="#1f5f6b"/></linearGradient>
    <linearGradient id="brass" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f0c877"/><stop offset="1" stop-color="#a87a2e"/></linearGradient>
  </defs>
  <rect x="-240" y="-180" width="2400" height="252" fill="url(#ceiling)"/>
  <rect x="-240" y="50" width="2400" height="22" fill="#fffbf5"/>
  <rect x="-240" y="64" width="2400" height="6" fill="#e9d6b8"/>
  <g>
  ${woodFloor(FLOOR_Y, 1260, ["#8f6441", "#9b6c47", "#a57a51", "#946745"], "#5a3a26", 21)}
  </g>
  <rect x="-240" y="${FLOOR_Y}" width="2400" height="500" fill="url(#floorShade)"/>
  <!-- rug -->
  <path d="M640 800 H1280 L1380 1060 H540 Z" fill="#c8674a"/>
  <path d="M664 814 H1256 L1346 1046 H574 Z" fill="none" stroke="#f3ddb3" stroke-width="8"/>
  <path d="M700 834 H1220 L1296 1024 H624 Z" fill="#3e3570"/>
  <path d="M760 860 H1160 L1210 996 H710 Z" fill="none" stroke="#f6c453" stroke-width="6"/>
  <path d="M960 870 L1040 928 L960 986 L880 928 Z" fill="#ee7b6b"/><path d="M960 896 L1004 928 L960 960 L916 928 Z" fill="#f3ddb3"/>
  <!-- wallpaper + wainscot, with the French doors cut out -->
  ${wallWithHoles(-240, 70, 2160, 480, [[LEAF_L[0], 110, 400, 370]], "url(#paper)")}
  <g opacity="0.9">${stripes}</g>
  ${wallWithHoles(-240, 480, 2160, FLOOR_Y, [[LEAF_L[0], 480, 400, 280]], "url(#wood)")}
  <rect x="-240" y="474" width="2400" height="14" fill="#7a5134"/>
  <rect x="-240" y="474" width="2400" height="4" fill="#c99a6b"/>
  ${panels}
  <!-- the wallpaper stripes must not cover the door opening -->
  <!-- French doors -->
  <path fill="#3b2e3a" opacity="0.08" fill-rule="evenodd" d="M740 90 H1190 V${FLOOR_Y} H740 Z M760 110 H1160 V${FLOOR_Y} H760 Z"/>
  <path fill="#fffbf5" fill-rule="evenodd" d="M736 86 H1184 V${FLOOR_Y} H736 Z M760 110 H950 V${FLOOR_Y} H760 Z M970 110 H1160 V${FLOOR_Y} H970 Z"/>
  ${muntins}
  ${glassReflections(LEAF_L)}
  ${glassReflections(LEAF_R)}
  <rect x="932" y="400" width="10" height="70" rx="5" fill="#a87a2e"/><rect x="978" y="400" width="10" height="70" rx="5" fill="#a87a2e"/>
  <rect x="728" y="${FLOOR_Y - 10}" width="464" height="16" rx="3" fill="#a87a2e"/>
  <!-- velvet curtains -->
  <rect x="640" y="72" width="640" height="46" rx="10" fill="#1f5f6b"/>
  <path d="M640 118 C690 138 740 138 790 118 C840 138 890 138 940 118 C990 138 1040 138 1090 118 C1140 138 1190 138 1240 118 C1260 124 1280 124 1280 118" fill="#1f5f6b"/>
  <path d="M650 110 H760 C752 300 780 520 760 ${FLOOR_Y} H662 C680 520 640 300 650 110 Z" fill="url(#velvet)"/>
  <path d="M1270 110 H1160 C1168 300 1140 520 1160 ${FLOOR_Y} H1258 C1240 520 1280 300 1270 110 Z" fill="url(#velvet)"/>
  <path d="M690 120 C700 320 690 540 700 ${FLOOR_Y}" stroke="#6cc2be" stroke-width="5" fill="none" opacity="0.5"/>
  <path d="M1230 120 C1220 320 1230 540 1220 ${FLOOR_Y}" stroke="#6cc2be" stroke-width="5" fill="none" opacity="0.5"/>
  <rect x="648" y="470" width="118" height="16" rx="8" fill="url(#brass)"/>
  <rect x="1154" y="470" width="118" height="16" rx="8" fill="url(#brass)"/>
  <!-- little brass chandelier -->
  <rect x="957" y="-180" width="6" height="200" fill="#7a5134"/>
  <path d="M910 40 C930 60 990 60 1010 40" stroke="#d4a24c" stroke-width="6" fill="none"/>
  <circle cx="910" cy="36" r="9" fill="#fbe3a0"/><circle cx="960" cy="44" r="10" fill="#fbe3a0"/><circle cx="1010" cy="36" r="9" fill="#fbe3a0"/>
  <rect x="-240" y="${FLOOR_Y - 20}" width="970" height="20" fill="#7a5134"/>
  <rect x="1190" y="${FLOOR_Y - 20}" width="970" height="20" fill="#7a5134"/>
  <rect x="-240" y="${FLOOR_Y}" width="2400" height="10" fill="#3b2e3a" opacity="0.15"/>`, "Grandma's Study background. The French balcony doors in the middle are transparent holes.");
// v2: the study is no longer a room (the house route has seven other rooms), so its background and
// light layer aren't written any more. Its furniture stays: the grandfather clock stands in the hall.
void bg;

// ---------------------------------------------------------------- furniture
const shadow = (cx, cy, rx, ry, op = 0.2) => `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="#3b2e3a" opacity="${op}"/>`;
const drawer = (x, y, w, h) => `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="6" fill="#8f6441"/><rect x="${x + 6}" y="${y + 6}" width="${w - 12}" height="${h - 12}" rx="4" fill="#9b6c47"/><rect x="${x + w / 2 - 18}" y="${y + h / 2 - 4}" width="36" height="8" rx="4" fill="#d4a24c"/>`;

save("props/study/desk.svg", svg(600, 330, `  ${shadow(300, 322, 290, 9)}
  <!-- typewriter -->
  <rect x="80" y="0" width="140" height="42" rx="4" fill="#fffbf5"/>
  <path d="M96 12 H200 M96 20 H188 M96 28 H196" stroke="#9c8ac4" stroke-width="2.5"/>
  <rect x="56" y="34" width="190" height="20" rx="8" fill="#2e8c8c"/>
  <rect x="50" y="50" width="200" height="42" rx="10" fill="#1f5f6b"/>
  ${Array.from({ length: 9 }, (_, i) => `<circle cx="${76 + i * 19}" cy="66" r="5" fill="#fff4e2"/><circle cx="${84 + i * 19}" cy="80" r="5" fill="#fff4e2"/>`).join("")}
  <!-- banker's lamp -->
  <rect x="512" y="80" width="56" height="12" rx="4" fill="#d4a24c"/>
  <rect x="536" y="36" width="8" height="46" fill="#d4a24c"/>
  <path d="M488 40 C488 20 592 20 592 40 L596 50 H484 Z" fill="#5e7f5e"/>
  <rect x="484" y="46" width="112" height="6" rx="3" fill="#a9c7a3"/>
  <!-- top -->
  <rect x="0" y="90" width="600" height="34" rx="8" fill="#7a5134"/>
  <rect x="0" y="90" width="600" height="8" rx="4" fill="#c99a6b" opacity="0.6"/>
  <!-- pedestals -->
  <rect x="16" y="124" width="208" height="206" fill="#7a5134"/>
  <rect x="376" y="124" width="208" height="206" fill="#7a5134"/>
  <rect x="224" y="124" width="152" height="40" fill="#7a5134"/>
  <rect x="236" y="164" width="128" height="150" fill="#3b2e3a" opacity="0.35"/>
  ${drawer(26, 134, 188, 88)}${drawer(26, 230, 188, 88)}
  ${drawer(386, 134, 188, 88)}${drawer(386, 230, 188, 88)}`, "Grandma's writing desk with a typewriter and a green banker's lamp."));

const land = `<path d="M40 60 C70 40 110 50 120 80 C110 110 80 120 60 150 C40 130 30 100 40 60 Z" fill="#f3ddb3"/>
    <path d="M150 50 C190 40 230 60 250 90 C240 120 200 110 180 140 C160 120 140 90 150 50 Z" fill="#f3ddb3"/>
    <path d="M280 60 C330 50 380 70 390 110 C360 130 320 120 300 150 C280 120 270 90 280 60 Z" fill="#f3ddb3"/>
    <path d="M300 170 C330 160 360 180 350 210 C330 220 310 210 300 170 Z" fill="#f3ddb3"/>`;
save("props/study/world_map.svg", svg(440, 270, `  <rect x="8" y="10" width="432" height="260" rx="6" fill="#3b2e3a" opacity="0.15"/>
  <rect x="0" y="0" width="432" height="260" rx="6" fill="#7a5134"/>
  <rect x="14" y="14" width="404" height="232" fill="#6cc2be"/>
  <g transform="translate(14 14)">${land}</g>
  <path d="M100 110 C150 60 220 70 260 100 S360 130 380 160" stroke="#fffbf5" stroke-width="3" stroke-dasharray="8 7" fill="none"/>
  <g fill="#ee7b6b"><circle cx="100" cy="112" r="8"/><circle cx="262" cy="102" r="8"/><circle cx="380" cy="160" r="8"/><circle cx="330" cy="206" r="8"/><circle cx="190" cy="84" r="8"/></g>
  <g fill="#fffbf5"><circle cx="98" cy="110" r="2.5"/><circle cx="260" cy="100" r="2.5"/><circle cx="378" cy="158" r="2.5"/><circle cx="328" cy="204" r="2.5"/><circle cx="188" cy="82" r="2.5"/></g>
  <circle cx="40" cy="220" r="18" fill="#fffbf5" opacity="0.8"/><path d="M40 204 L44 220 L40 236 L36 220 Z" fill="#c8674a"/>`, "Framed world map with red pins and a dotted travel route."));

save("props/study/grandfather_clock.svg", svg(140, 580, `  ${shadow(70, 574, 64, 7)}
  <path d="M10 60 C10 10 130 10 130 60 V180 H10 Z" fill="#7a5134"/>
  <path d="M22 60 C22 24 118 24 118 60 V170 H22 Z" fill="#8f6441"/>
  <circle cx="70" cy="100" r="44" fill="#d4a24c"/><circle cx="70" cy="100" r="38" fill="#fff4e2"/>
  <g stroke="#6b5a66" stroke-width="3" stroke-linecap="round"><line x1="70" y1="66" x2="70" y2="72"/><line x1="104" y1="100" x2="98" y2="100"/><line x1="70" y1="134" x2="70" y2="128"/><line x1="36" y1="100" x2="42" y2="100"/></g>
  <line x1="70" y1="100" x2="58" y2="84" stroke="#3b2e3a" stroke-width="4" stroke-linecap="round"/>
  <line x1="70" y1="100" x2="90" y2="92" stroke="#3b2e3a" stroke-width="3" stroke-linecap="round"/>
  <circle cx="70" cy="100" r="4" fill="#ee7b6b"/>
  <rect x="20" y="180" width="100" height="320" fill="#7a5134"/>
  <rect x="32" y="196" width="76" height="288" rx="30" fill="#5a3a26"/>
  <rect x="38" y="204" width="64" height="272" rx="26" fill="#9c8ac4" opacity="0.25"/>
  <line x1="70" y1="210" x2="70" y2="400" stroke="#d4a24c" stroke-width="4"/>
  <circle cx="70" cy="410" r="24" fill="#d4a24c"/><circle cx="64" cy="404" r="7" fill="#fbe3a0"/>
  <rect x="10" y="500" width="120" height="70" rx="6" fill="#7a5134"/>
  <rect x="22" y="512" width="96" height="46" rx="4" fill="#8f6441"/>
  <circle cx="70" cy="22" r="8" fill="#f6c453"/>`, "Tall grandfather clock with a brass pendulum."));

save("props/study/globe.svg", svg(230, 360, `  ${shadow(115, 352, 100, 8)}
  <path d="M60 350 L100 250 H130 L170 350" stroke="#7a5134" stroke-width="12" fill="none" stroke-linecap="round"/>
  <path d="M115 250 V350" stroke="#7a5134" stroke-width="12" stroke-linecap="round"/>
  <rect x="80" y="238" width="70" height="18" rx="8" fill="#a8744a"/>
  <circle cx="115" cy="128" r="96" fill="#6cc2be"/>
  <path d="M60 70 C90 50 120 60 126 90 C110 118 84 110 70 140 C54 120 50 94 60 70 Z" fill="#f3ddb3"/>
  <path d="M140 110 C170 100 196 120 196 150 C176 170 150 160 140 190 C126 170 126 132 140 110 Z" fill="#f3ddb3"/>
  <path d="M80 170 C100 170 110 190 100 206 C86 210 76 196 80 170 Z" fill="#f3ddb3"/>
  <circle cx="84" cy="96" r="30" fill="#fffbf5" opacity="0.18"/>
  <path d="M115 20 C190 30 220 110 200 180 C190 214 160 236 115 240" stroke="#d4a24c" stroke-width="8" fill="none"/>
  <circle cx="115" cy="24" r="8" fill="#d4a24c"/><circle cx="115" cy="236" r="8" fill="#d4a24c"/>
  <path d="M22 132 H208" stroke="#1f5f6b" stroke-width="3" opacity="0.5"/>`, "Globe on a wooden stand (it secretly opens)."));

const bookColors = ["#ee7b6b", "#2e8c8c", "#f3ddb3", "#8faf8a", "#9c8ac4", "#c8674a", "#f6c453", "#6cc2be", "#5e7f5e"];
const books = (x0, yBottom, count, seed) => {
  let x = x0; let out = "";
  for (let i = 0; i < count; i++) {
    const w = 18 + ((i * 7 + seed) % 12); const h = 86 + ((i * 13 + seed) % 34);
    out += `<rect x="${x}" y="${yBottom - h}" width="${w}" height="${h}" rx="2" fill="${bookColors[(i + seed) % bookColors.length]}"/><rect x="${x}" y="${yBottom - h + 12}" width="${w}" height="4" fill="#fbe3a0" opacity="0.6"/>`;
    x += w + 2;
  }
  return out;
};
save("props/study/bookcase.svg", svg(320, 620, `  <rect x="10" y="8" width="310" height="612" rx="6" fill="#3b2e3a" opacity="0.12"/>
  <rect x="0" y="0" width="310" height="610" rx="6" fill="#7a5134"/>
  <rect x="14" y="14" width="282" height="420" fill="#e2c9a4"/>
  <rect x="0" y="0" width="310" height="14" rx="5" fill="#8f6441"/>
  ${books(22, 150, 8, 1)}
  <path d="M250 150 L262 104 L274 150 Z" fill="#6b5a66"/><circle cx="262" cy="98" r="8" fill="#6b5a66"/>
  <rect x="14" y="150" width="282" height="12" fill="#8f6441"/><rect x="14" y="162" width="282" height="6" fill="#3b2e3a" opacity="0.3"/>
  ${books(22, 292, 5, 3)}
  <rect x="14" y="292" width="282" height="12" fill="#8f6441"/><rect x="14" y="304" width="282" height="6" fill="#3b2e3a" opacity="0.3"/>
  <path d="M40 432 C40 404 76 404 76 432 Z" fill="#e08e6d"/><rect x="36" y="428" width="44" height="6" rx="3" fill="#c8674a"/>
  ${books(200, 432, 4, 5)}
  <rect x="14" y="432" width="282" height="12" fill="#8f6441"/>
  <rect x="14" y="444" width="282" height="146" fill="#5a3a26"/>
  <rect x="24" y="454" width="126" height="126" rx="6" fill="#8f6441"/><rect x="34" y="464" width="106" height="106" rx="4" fill="#9c8ac4" opacity="0.3"/>
  <rect x="160" y="454" width="126" height="126" rx="6" fill="#8f6441"/><rect x="170" y="464" width="106" height="106" rx="4" fill="#9c8ac4" opacity="0.3"/>
  <circle cx="144" cy="518" r="6" fill="#d4a24c"/><circle cx="166" cy="518" r="6" fill="#d4a24c"/>
  <rect x="6" y="590" width="298" height="20" rx="4" fill="#5a3a26"/>`, "Tall study bookcase with souvenirs and a glass-door cabinet."));

save("props/study/trunk.svg", svg(380, 210, `  ${shadow(190, 204, 184, 8)}
  <rect x="10" y="40" width="360" height="160" rx="12" fill="#1f5f6b"/>
  <path d="M10 60 C10 20 370 20 370 60 V80 H10 Z" fill="#2e8c8c"/>
  <rect x="10" y="76" width="360" height="8" fill="#123c44"/>
  <rect x="80" y="30" width="20" height="170" fill="#a8744a"/><rect x="280" y="30" width="20" height="170" fill="#a8744a"/>
  <rect x="160" y="84" width="60" height="44" rx="6" fill="#d4a24c"/><circle cx="190" cy="100" r="6" fill="#7a5134"/><rect x="188" y="102" width="4" height="12" rx="2" fill="#7a5134"/>
  <path d="M10 180 V200 H40 M370 180 V200 H340 M10 60 V40 H40 M370 60 V40 H340" stroke="#d4a24c" stroke-width="8" fill="none"/>
  <g transform="rotate(-8 130 150)"><rect x="110" y="130" width="46" height="32" rx="6" fill="#f6c453"/><circle cx="133" cy="146" r="8" fill="#ee7b6b"/></g>
  <circle cx="236" cy="156" r="20" fill="#f9b98a"/><path d="M226 156 H246" stroke="#c8674a" stroke-width="3"/>
  <g transform="rotate(10 320 140)"><rect x="306" y="120" width="44" height="30" rx="4" fill="#fffbf5"/><rect x="312" y="126" width="32" height="8" fill="#9c8ac4"/></g>`, "Vintage travel trunk with brass corners and travel stickers."));

console.log("study art written");
