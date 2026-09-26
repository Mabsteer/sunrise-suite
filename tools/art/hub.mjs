// Generates the penthouse hub background + all decor sprites. The SVG files are the editable source;
// re-running this overwrites them:  node tools/art/hub.mjs
import { save, svg, roomSvg, woodFloor, lightLayer } from "./room_kit.mjs";

const FLOOR_Y = 760;
// Three arched openings: left window, middle terrace door (to the floor), right window.
const ARCHES = [
  { x: 330, w: 320, bottom: 640 },
  { x: 800, w: 320, bottom: FLOOR_Y },
  { x: 1270, w: 320, bottom: 640 },
];
const archPath = ({ x, w, bottom }, top = 140) => {
  const r = w / 2;
  return `M${x} ${bottom} V${top + r} A${r} ${r} 0 0 1 ${x + w} ${top + r} V${bottom} Z`;
};
const archFrame = (a, fw) => {
  const o = { x: a.x - fw, w: a.w + fw * 2, bottom: a.bottom + (a.bottom === FLOOR_Y ? 0 : fw) };
  return `<path fill="#fffbf5" fill-rule="evenodd" d="${archPath(o, 140 - fw)} ${archPath(a)}"/>`;
};

const wall = `<path fill="url(#wall)" fill-rule="evenodd" d="M-240 70 H2160 V${FLOOR_Y} H-240 Z ${ARCHES.map(a => archPath(a)).join(" ")}"/>`;
const beams = [-200, 180, 560, 940, 1320, 1700, 2080].map(x => `<rect x="${x}" y="-180" width="40" height="250" fill="#c99a6b"/><rect x="${x}" y="-180" width="10" height="250" fill="#dbb286"/>`).join("");
const sills = ARCHES.filter(a => a.bottom !== FLOOR_Y).map(a => `<rect x="${a.x - 30}" y="${a.bottom}" width="${a.w + 60}" height="26" rx="6" fill="#fffbf5"/><rect x="${a.x - 30}" y="${a.bottom + 24}" width="${a.w + 60}" height="10" fill="#3b2e3a" opacity="0.08"/>`).join("");
const mullions = ARCHES.map(a => `<rect x="${a.x + a.w / 2 - 6}" y="${140 + a.w / 2 - 40}" width="12" height="${a.bottom - 140 - a.w / 2 + 40}" fill="#fffbf5"/><rect x="${a.x}" y="${300}" width="${a.w}" height="10" fill="#fffbf5"/>`).join("");
const reflections = ARCHES.map(a => `<polygon points="${a.x + 40},${320} ${a.x + 100},${300} ${a.x},${460} ${a.x},${400}" fill="#fffbf5" opacity="0.12"/>`).join("");

save("rooms/hub_bg.svg", roomSvg(`  <defs>
    <linearGradient id="ceiling" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f1e1c8"/><stop offset="1" stop-color="#fbf0de"/></linearGradient>
    <linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff7ea"/><stop offset="1" stop-color="#f7e4cb"/></linearGradient>
    <linearGradient id="floorShade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3b2e3a" stop-opacity="0.16"/><stop offset="0.3" stop-color="#3b2e3a" stop-opacity="0"/><stop offset="1" stop-color="#3b2e3a" stop-opacity="0.14"/></linearGradient>
  </defs>
  <rect x="-240" y="-180" width="2400" height="252" fill="url(#ceiling)"/>
  ${beams}
  <rect x="-240" y="56" width="2400" height="16" fill="#fffbf5"/>
  <g>
  ${woodFloor(FLOOR_Y, 1260, ["#e2c29a", "#dcb88d", "#e6c8a2", "#d9b489"], "#a8744a", 5)}
  </g>
  <rect x="-240" y="${FLOOR_Y}" width="2400" height="500" fill="url(#floorShade)"/>
  ${wall}
  ${ARCHES.map(a => archFrame(a, 20)).join("\n  ")}
  ${mullions}
  ${reflections}
  ${sills}
  <rect x="${ARCHES[1].x - 26}" y="${FLOOR_Y - 12}" width="${ARCHES[1].w + 52}" height="16" rx="3" fill="#a87a2e"/>
  <rect x="-240" y="${FLOOR_Y - 22}" width="${ARCHES[1].x - 20 + 240}" height="22" fill="#fffbf5"/>
  <rect x="${ARCHES[1].x + ARCHES[1].w + 20}" y="${FLOOR_Y - 22}" width="${2160 - ARCHES[1].x - ARCHES[1].w - 20}" height="22" fill="#fffbf5"/>
  <rect x="-240" y="${FLOOR_Y}" width="2400" height="10" fill="#3b2e3a" opacity="0.1"/>`, "Penthouse hub: airy room with beams and three arched openings (the middle one is the terrace door)."));

save("rooms/hub_light.svg", lightLayer(
  ["330,640 650,640 700,1150 250,1150", "800,760 1120,760 1250,1180 700,1180", "1270,640 1590,640 1720,1150 1250,1150"],
  [[960, 930, 700, 140, 1]], "Sunbeams through the hub's arches."));

// ---------------------------------------------------------------- decor
const D = (name, w, h, body, note) => save(`props/decor/${name}.svg`, svg(w, h, body, note));
const shadow = (cx, cy, rx, ry, op = 0.18) => `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="#3b2e3a" opacity="${op}"/>`;
const dots = (x0, y0, cols, rows, dx, dy, r, fill) => Array.from({ length: cols * rows }, (_, i) => `<circle cx="${x0 + (i % cols) * dx}" cy="${y0 + Math.floor(i / cols) * dy}" r="${r}" fill="${fill}"/>`).join("");

D("linen_sofa", 420, 230, `  ${shadow(210, 222, 200, 9)}
  <rect x="20" y="40" width="380" height="120" rx="40" fill="#f3ddb3"/>
  <rect x="0" y="100" width="70" height="110" rx="30" fill="#ecd3a6"/><rect x="350" y="100" width="70" height="110" rx="30" fill="#ecd3a6"/>
  <rect x="50" y="120" width="320" height="70" rx="26" fill="#fff4e2"/>
  <rect x="50" y="160" width="320" height="30" rx="14" fill="#f3ddb3"/>
  <rect x="200" y="124" width="6" height="60" rx="3" fill="#ecd3a6"/>
  <rect x="70" y="64" width="110" height="70" rx="22" fill="#9c8ac4"/><rect x="240" y="64" width="110" height="70" rx="22" fill="#6cc2be"/>
  <rect x="70" y="92" width="110" height="10" fill="#c9bde3"/><circle cx="295" cy="99" r="12" fill="#fffbf5" opacity="0.6"/>
  <rect x="40" y="200" width="16" height="22" rx="4" fill="#a8744a"/><rect x="364" y="200" width="16" height="22" rx="4" fill="#a8744a"/>`, "Linen sofa with lavender and teal cushions.");
D("potted_palm", 180, 300, `  ${shadow(90, 294, 70, 7)}
  <path d="M90 200 C80 140 60 90 30 60 M90 200 C94 130 110 80 150 50 M90 200 C88 130 90 70 92 20 M90 200 C70 150 40 130 10 130 M90 200 C110 150 140 130 172 128" stroke="#5e7f5e" stroke-width="5" fill="none" stroke-linecap="round"/>
  ${[[30, 60, -40], [150, 50, 40], [92, 22, 0], [12, 130, -70], [170, 128, 70]].map(([x, y, r]) => `<ellipse cx="${x}" cy="${y}" rx="14" ry="40" fill="#8faf8a" transform="rotate(${r} ${x} ${y})"/>`).join("")}
  <path d="M40 200 H140 L130 290 H50 Z" fill="#fff4e2"/><rect x="36" y="192" width="108" height="18" rx="8" fill="#f3ddb3"/>
  <path d="M52 236 H128 M50 256 H130" stroke="#c9bde3" stroke-width="4"/>`, "Potted palm in a white planter.");
D("rattan_chair", 280, 320, `  ${shadow(140, 312, 120, 8)}
  <path d="M140 200 C40 200 10 120 20 60 C40 10 100 0 140 0 C180 0 240 10 260 60 C270 120 240 200 140 200 Z" fill="#d9b07e"/>
  <path d="M140 190 C60 190 36 124 44 72 C60 30 110 22 140 22 C170 22 220 30 236 72 C244 124 220 190 140 190 Z" fill="#e6c496"/>
  ${[60, 100, 140, 180, 220].map(x => `<path d="M140 190 L${x} 36" stroke="#c99a6b" stroke-width="3"/>`).join("")}
  <rect x="70" y="170" width="140" height="50" rx="22" fill="#ee7b6b"/><rect x="70" y="200" width="140" height="20" rx="10" fill="#c95b52"/>
  <path d="M100 220 L80 310 M180 220 L200 310 M140 220 V310" stroke="#a8744a" stroke-width="8" stroke-linecap="round"/>`, "Rattan peacock chair with a coral cushion.");
D("hammock", 460, 260, `  ${shadow(230, 252, 220, 8)}
  <path d="M20 250 L60 40 M440 250 L400 40" stroke="#a8744a" stroke-width="14" stroke-linecap="round"/>
  <path d="M20 250 H440" stroke="#a8744a" stroke-width="12" stroke-linecap="round"/>
  <path d="M60 60 C140 200 320 200 400 60" stroke="#fff4e2" stroke-width="40" fill="none"/>
  <path d="M60 60 C140 200 320 200 400 60" stroke="#ee7b6b" stroke-width="8" fill="none" stroke-dasharray="18 14"/>
  <path d="M90 120 C150 190 310 190 370 120" stroke="#f6c453" stroke-width="6" fill="none"/>`, "Striped hammock on a wooden stand.");
D("fiddle_leaf", 200, 420, `  ${shadow(100, 414, 72, 7)}
  <path d="M100 330 C96 250 104 150 100 60" stroke="#7a5134" stroke-width="8" stroke-linecap="round"/>
  ${[[100, 50, 0, 1], [70, 110, -30, 0.9], [134, 130, 30, 0.9], [66, 190, -40, 0.95], [138, 210, 40, 0.95], [80, 270, -50, 0.8], [124, 280, 50, 0.8]].map(([x, y, r, s]) => `<g transform="translate(${x} ${y}) rotate(${r}) scale(${s})"><path d="M0 34 C-34 20 -34 -24 0 -40 C34 -24 34 20 0 34 Z" fill="#5e7f5e"/><path d="M0 30 V-34" stroke="#8faf8a" stroke-width="3"/></g>`).join("")}
  <path d="M40 330 H160 L150 410 H50 Z" fill="#c99a6b"/><path d="M44 350 H156 M46 372 H154 M48 394 H152" stroke="#a8744a" stroke-width="4"/>`, "Fiddle-leaf fig in a woven basket.");
D("surfboard", 150, 430, `  ${shadow(80, 424, 56, 6)}
  <path d="M75 6 C130 60 136 300 110 424 H44 C18 300 22 60 75 6 Z" fill="#6cc2be"/>
  <path d="M75 20 C112 70 118 250 100 410 H52 C36 250 40 70 75 20 Z" fill="#fff4e2"/>
  <path d="M42 160 C70 150 90 150 116 160" stroke="#ee7b6b" stroke-width="14" fill="none"/><path d="M40 200 C70 190 90 190 118 200" stroke="#f6c453" stroke-width="14" fill="none"/>
  <path d="M75 20 V400" stroke="#2e8c8c" stroke-width="3" opacity="0.5"/>`, "Retro surfboard leaning on the wall.");
D("record_crate", 220, 190, `  ${shadow(110, 184, 100, 6)}
  ${[20, 44, 68, 92, 116, 140].map((x, i) => `<rect x="${x}" y="${20 + (i % 3) * 6}" width="22" height="100" rx="2" fill="${["#ee7b6b", "#2e8c8c", "#f6c453", "#9c8ac4", "#8faf8a", "#f9b98a"][i]}"/>`).join("")}
  <circle cx="180" cy="40" r="30" fill="#3b2e3a"/><circle cx="180" cy="40" r="10" fill="#ee7b6b"/>
  <rect x="10" y="80" width="200" height="100" rx="8" fill="#c99a6b"/><rect x="10" y="80" width="200" height="12" fill="#a8744a"/>
  <path d="M30 110 H190 M30 140 H190" stroke="#a8744a" stroke-width="5"/>`, "Wooden crate of vinyl records.");
D("telescope", 210, 370, `  ${shadow(105, 364, 90, 7)}
  <path d="M105 200 L40 360 M105 200 L170 360 M105 200 V360" stroke="#7a5134" stroke-width="10" stroke-linecap="round"/>
  <g transform="rotate(-28 105 170)"><rect x="30" y="148" width="170" height="40" rx="14" fill="#d4a24c"/><rect x="0" y="154" width="40" height="28" rx="8" fill="#a87a2e"/><rect x="190" y="140" width="24" height="56" rx="8" fill="#a87a2e"/><rect x="40" y="152" width="150" height="8" rx="4" fill="#fbe3a0" opacity="0.7"/></g>
  <circle cx="105" cy="200" r="12" fill="#a87a2e"/>`, "Brass telescope on a wooden tripod.");
D("cushion_pile", 230, 150, `  ${shadow(115, 144, 104, 7)}
  <rect x="10" y="80" width="210" height="60" rx="26" fill="#9c8ac4"/><rect x="10" y="104" width="210" height="10" fill="#c9bde3"/>
  <rect x="30" y="40" width="160" height="54" rx="24" fill="#f9b98a"/><path d="M50 67 H170" stroke="#ee7b6b" stroke-width="6" stroke-dasharray="10 8"/>
  <rect x="60" y="6" width="110" height="46" rx="20" fill="#6cc2be"/><circle cx="115" cy="29" r="8" fill="#fffbf5" opacity="0.7"/>`, "Pile of cosy floor cushions.");
D("floor_lamp", 170, 430, `  ${shadow(85, 424, 60, 6)}
  <path d="M85 150 V410" stroke="#a8744a" stroke-width="8"/>
  <path d="M40 420 H130" stroke="#a8744a" stroke-width="10" stroke-linecap="round"/>
  <path d="M20 150 C20 60 150 60 150 150 Z" fill="#e6c496"/>
  ${[40, 64, 88, 112, 136].map(x => `<path d="M${x} 146 L85 70" stroke="#c99a6b" stroke-width="3"/>`).join("")}
  <ellipse cx="85" cy="150" rx="66" ry="10" fill="#fbe3a0"/>`, "Rattan floor lamp.");
D("string_lanterns", 380, 130, `  <path d="M10 20 C100 70 280 70 370 20" stroke="#7a5134" stroke-width="3" fill="none"/>
  ${[[50, 38, "#ee7b6b"], [110, 54, "#f6c453"], [170, 62, "#6cc2be"], [230, 60, "#9c8ac4"], [290, 52, "#f9b98a"], [340, 36, "#8faf8a"]].map(([x, y, c]) => `<rect x="${x - 4}" y="${y - 6}" width="8" height="10" fill="#7a5134"/><ellipse cx="${x}" cy="${y + 26}" rx="22" ry="28" fill="${c}"/><ellipse cx="${x - 7}" cy="${y + 18}" rx="6" ry="10" fill="#fffbf5" opacity="0.45"/>`).join("")}`, "Garland of paper lanterns.");
D("seascape_painting", 250, 190, `  <rect x="8" y="10" width="242" height="180" rx="6" fill="#3b2e3a" opacity="0.15"/>
  <rect x="0" y="0" width="242" height="180" rx="6" fill="#fffbf5"/>
  <rect x="14" y="14" width="214" height="152" fill="#fcd9b8"/><rect x="14" y="14" width="214" height="60" fill="#c9bde3"/>
  <circle cx="160" cy="92" r="24" fill="#f9b98a"/><rect x="14" y="98" width="214" height="68" fill="#6cc2be"/>
  <path d="M14 120 C60 110 100 130 150 118 S210 122 228 116 V166 H14 Z" fill="#2e8c8c"/>
  <path d="M14 146 C80 136 140 152 228 140 V166 H14 Z" fill="#f3ddb3"/>`, "Big seascape painting in a white frame.");
D("fishing_net", 270, 210, `  <path d="M10 10 C80 40 190 40 260 10 L240 200 H30 Z" fill="none" stroke="#c99a6b" stroke-width="4"/>
  ${Array.from({ length: 6 }, (_, i) => `<path d="M${30 + i * 42} ${24 + (i === 0 || i === 5 ? 0 : 8)} L${40 + i * 38} 200" stroke="#c99a6b" stroke-width="2.5"/>`).join("")}
  ${[60, 100, 140, 180].map(y => `<path d="M${22 + y / 12} ${y} H${248 - y / 12}" stroke="#c99a6b" stroke-width="2.5"/>`).join("")}
  <path d="M90 90 L96 104 L112 106 L100 116 L104 132 L90 124 L76 132 L80 116 L68 106 L84 104 Z" fill="#ee7b6b"/>
  <path d="M170 140 C154 132 154 112 170 108 C186 112 186 132 170 140 Z" fill="#fcd9b8"/>
  <path d="M170 140 L162 112 M170 140 L170 108 M170 140 L178 112" stroke="#e08e6d" stroke-width="2"/>
  <ellipse cx="130" cy="160" rx="14" ry="9" fill="#9c8ac4"/>`, "Fishing net with a starfish and shells.");
D("ceramic_vases", 160, 150, `  ${shadow(80, 144, 70, 6)}
  <path d="M20 140 C10 100 20 60 40 50 H60 C80 60 90 100 80 140 Z" fill="#6cc2be"/><rect x="36" y="36" width="28" height="18" rx="4" fill="#2e8c8c"/>
  <path d="M90 140 C84 110 90 90 110 84 C130 90 136 110 130 140 Z" fill="#f9b98a"/>
  <path d="M110 84 C104 60 108 30 116 16 M110 84 C114 60 130 40 140 34" stroke="#8faf8a" stroke-width="3" fill="none"/>
  <circle cx="116" cy="16" r="6" fill="#ee7b6b"/><circle cx="140" cy="34" r="6" fill="#f6c453"/>`, "Two ceramic vases with a wildflower.");
D("candles", 140, 120, `  ${shadow(70, 114, 62, 5)}
  <rect x="10" y="100" width="120" height="14" rx="6" fill="#d4a24c"/>
  <rect x="24" y="50" width="26" height="54" rx="6" fill="#fff4e2"/><rect x="58" y="30" width="26" height="74" rx="6" fill="#fcd9b8"/><rect x="92" y="60" width="26" height="44" rx="6" fill="#fff4e2"/>
  ${[[37, 40], [71, 20], [105, 50]].map(([x, y]) => `<path d="M${x} ${y} C${x - 7} ${y - 8} ${x} ${y - 20} ${x} ${y - 20} C${x} ${y - 20} ${x + 7} ${y - 8} ${x} ${y} Z" fill="#f6c453"/>`).join("")}`, "Three candles on a brass tray.");
D("jute_rug", 800, 160, `  <ellipse cx="400" cy="84" rx="396" ry="74" fill="#3b2e3a" opacity="0.1"/>
  <ellipse cx="400" cy="80" rx="390" ry="72" fill="#e3c393"/>
  ${[330, 270, 210, 150].map((rx, i) => `<ellipse cx="400" cy="80" rx="${rx}" ry="${rx * 0.18}" fill="none" stroke="${i % 2 ? "#d4b07e" : "#c99a6b"}" stroke-width="10"/>`).join("")}`, "Round jute rug.");
D("striped_rug", 780, 150, `  <path d="M60 10 H720 L780 140 H0 Z" fill="#fff4e2"/>
  ${[0, 1, 2, 3, 4].map(i => `<path d="M${60 - i * 12} ${20 + i * 24} H${720 + i * 12} L${726 + i * 12} ${32 + i * 24} H${54 - i * 12} Z" fill="${["#ee7b6b", "#6cc2be", "#f6c453", "#9c8ac4", "#ee7b6b"][i]}"/>`).join("")}
  <path d="M0 140 H780" stroke="#c99a6b" stroke-width="4" stroke-dasharray="6 6"/>`, "Striped cotton rug.");
D("mango_cat", 190, 130, `  ${shadow(95, 124, 80, 6)}
  <ellipse cx="96" cy="88" rx="78" ry="36" fill="#f6c453"/>
  <path d="M30 84 C20 60 40 44 60 50 L64 36 L74 52 C84 50 96 56 98 70" fill="#f6c453"/>
  <path d="M60 50 L64 36 L72 50 Z" fill="#e0a92e"/>
  <path d="M46 70 C50 66 54 66 58 70 M70 70 C74 66 78 66 82 70" stroke="#3b2e3a" stroke-width="3" fill="none" stroke-linecap="round"/>
  <circle cx="64" cy="78" r="3" fill="#ee7b6b"/>
  <path d="M110 70 C130 74 150 70 160 80 M100 100 C120 96 140 100 150 104" stroke="#e0a92e" stroke-width="6" stroke-linecap="round" fill="none"/>
  <path d="M170 94 C188 80 186 60 170 54" stroke="#f6c453" stroke-width="14" fill="none" stroke-linecap="round"/>
`, "Mango, Grandma's sleepy ginger cat.");
D("sunburst_mirror", 230, 230, `  ${Array.from({ length: 24 }, (_, i) => { const a = (i / 24) * Math.PI * 2; const r2 = i % 2 ? 100 : 112; return `<line x1="${(115 + Math.cos(a) * 60).toFixed(1)}" y1="${(115 + Math.sin(a) * 60).toFixed(1)}" x2="${(115 + Math.cos(a) * r2).toFixed(1)}" y2="${(115 + Math.sin(a) * r2).toFixed(1)}" stroke="#d4a24c" stroke-width="6" stroke-linecap="round"/>`; }).join("")}
  <circle cx="115" cy="115" r="64" fill="#a87a2e"/><circle cx="115" cy="115" r="56" fill="#dbe8f0"/>
  <path d="M84 96 C96 80 110 76 124 78" stroke="#fffbf5" stroke-width="8" fill="none" stroke-linecap="round" opacity="0.8"/>`, "Golden sunburst mirror.");
D("hanging_egg_chair", 280, 430, `  ${shadow(140, 424, 110, 7)}
  <path d="M140 10 C230 10 240 120 220 160" stroke="#7a5134" stroke-width="12" fill="none" stroke-linecap="round"/>
  <path d="M220 160 V420 M180 420 H260" stroke="#7a5134" stroke-width="12" stroke-linecap="round"/>
  <path d="M140 110 V150" stroke="#a8744a" stroke-width="4"/>
  <path d="M60 260 C60 170 100 140 140 140 C180 140 220 170 220 260 C220 330 180 360 140 360 C100 360 60 330 60 260 Z" fill="#d9b07e"/>
  <path d="M78 262 C78 184 110 160 140 160 C170 160 202 184 202 262 C202 320 170 342 140 342 C110 342 78 320 78 262 Z" fill="#e6c496"/>
  <rect x="84" y="270" width="112" height="56" rx="24" fill="#fff4e2"/><rect x="110" y="220" width="60" height="50" rx="18" fill="#6cc2be"/>`, "Hanging rattan egg chair.");
D("shell_lamp", 130, 170, `  ${shadow(65, 164, 50, 5)}
  <rect x="40" y="130" width="50" height="34" rx="10" fill="#f3ddb3"/>
  <rect x="60" y="90" width="10" height="44" fill="#d4a24c"/>
  <path d="M65 100 C20 96 8 60 20 30 C36 6 94 6 110 30 C122 60 110 96 65 100 Z" fill="#fcd9b8"/>
  <path d="M65 100 L36 22 M65 100 L65 12 M65 100 L94 22 M65 100 L18 44 M65 100 L112 44" stroke="#f9b98a" stroke-width="4" stroke-linecap="round"/>
  <ellipse cx="65" cy="60" rx="40" ry="30" fill="#fbe3a0" opacity="0.4"/>`, "Seashell table lamp.");
D("grandma_portrait", 210, 250, `  <rect x="8" y="10" width="202" height="240" rx="100" fill="#3b2e3a" opacity="0.15"/>
  <rect x="0" y="0" width="202" height="240" rx="100" fill="#d4a24c"/>
  <rect x="14" y="14" width="174" height="212" rx="87" fill="#c9bde3"/>
  <path d="M40 226 C40 170 70 150 101 150 C132 150 162 170 162 226 Z" fill="#ee7b6b"/>
  <circle cx="101" cy="110" r="36" fill="#fcd9b8"/>
  <path d="M64 104 C62 70 140 70 138 104 C130 88 72 88 64 104 Z" fill="#fffbf5"/>
  <ellipse cx="101" cy="78" rx="66" ry="14" fill="#f6c453"/><path d="M70 78 C70 50 132 50 132 78 Z" fill="#f6c453"/>
  <path d="M86 112 C90 108 94 108 96 112 M106 112 C110 108 114 108 116 112" stroke="#3b2e3a" stroke-width="3" fill="none" stroke-linecap="round"/>
  <path d="M90 126 C96 132 106 132 112 126" stroke="#c95b52" stroke-width="3" fill="none" stroke-linecap="round"/>`, "Portrait of Grandma June in her sun hat.");
D("golden_sun", 150, 160, `  ${shadow(75, 154, 56, 5)}
  <rect x="40" y="130" width="70" height="24" rx="6" fill="#7a5134"/>
  ${Array.from({ length: 12 }, (_, i) => { const a = (i / 12) * Math.PI * 2; return `<line x1="${(75 + Math.cos(a) * 34).toFixed(1)}" y1="${(68 + Math.sin(a) * 34).toFixed(1)}" x2="${(75 + Math.cos(a) * 58).toFixed(1)}" y2="${(68 + Math.sin(a) * 58).toFixed(1)}" stroke="#f6c453" stroke-width="8" stroke-linecap="round"/>`; }).join("")}
  <circle cx="75" cy="68" r="34" fill="#f6c453"/><circle cx="66" cy="58" r="10" fill="#fbe3a0"/>
  <rect x="70" y="100" width="10" height="32" fill="#d4a24c"/>`, "Golden sun sculpture: for finishing Grandma's book.");
D("sea_glass_mobile", 200, 280, `  <path d="M20 30 H180" stroke="#a8744a" stroke-width="6" stroke-linecap="round"/>
  <path d="M100 0 V30" stroke="#7a5134" stroke-width="3"/>
  ${[[30, 120, "#6cc2be"], [65, 180, "#9c8ac4"], [100, 140, "#8faf8a"], [135, 200, "#f9b98a"], [170, 110, "#6cc2be"]].map(([x, len, c]) => `<path d="M${x} 30 V${len}" stroke="#7a5134" stroke-width="2"/><path d="M${x} ${len} L${x + 14} ${len + 18} L${x} ${len + 38} L${x - 14} ${len + 18} Z" fill="${c}" opacity="0.85"/>`).join("")}`, "Mobile of sea glass pieces.");

console.log("hub + decor art written");
