// Draws the props for the v2 puzzle types (orders, number squares, patterns, rotation puzzles),
// the counter props (1-9 things to count) and two lock badges.
// The SVG files are the real, editable art; this script is just how they were first drawn.
// Re-running it overwrites them:  node tools/art/puzzles_v2.mjs
import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "assets", "sprites");
const svg = (w, h, body, note) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${w} ${h}" width="${w}" height="${h}">\n  <!-- ${note} -->\n${body}\n</svg>\n`;
const out = (dir, name, text) => {
  mkdirSync(join(ROOT, dir), { recursive: true });
  writeFileSync(join(ROOT, dir, name), text);
};
const C = {
  ink: "#3b2e3a", inkSoft: "#6b5a66", cream: "#fff4e2", white: "#fffbf5", sand: "#f3ddb3",
  peach: "#f9b98a", peachL: "#fcd9b8", coral: "#ee7b6b", coralD: "#c95b52", gold: "#f6c453", goldL: "#fbe3a0",
  teal: "#2e8c8c", tealD: "#1f5f6b", tealL: "#6cc2be", lav: "#9c8ac4", lavL: "#c9bde3", indigo: "#3e3570",
  terra: "#c8674a", terraL: "#e08e6d", sage: "#8faf8a", sageD: "#5e7f5e", wood: "#a8744a", woodL: "#c99a6b",
  woodD: "#7a5134", brass: "#d4a24c", brassD: "#a87a2e",
};
const shadow = (cx, cy, rx, ry, o = 0.16) => `  <ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="${C.ink}" opacity="${o}"/>`;

// ================================================================== counters (1-9 things)

// Shell jar: an old jam jar with n shells, filled from the bottom row up.
const shell = (x, y, s, color) => `  <g transform="translate(${x} ${y}) scale(${s})">
    <path d="M0 8 C-9 6 -10 -4 -6 -8 C-3 -11 3 -11 6 -8 C10 -4 9 6 0 8 Z" fill="${color}"/>
    <path d="M0 7 L-5 -7 M0 7 L0 -9 M0 7 L5 -7" stroke="${C.white}" stroke-width="1.4" opacity="0.7" fill="none"/>
    <path d="M-3 8 L0 11 L3 8 Z" fill="${color}"/>
  </g>`;
const SHELL_POS = [[28, 98], [45, 99], [62, 98], [28, 80], [45, 81], [62, 80], [28, 62], [45, 63], [62, 62]];
const SHELL_COL = [C.coral, C.peach, C.sand, C.terraL, C.peachL, C.coral, C.sand, C.peach, C.terraL];
for (let n = 1; n <= 9; n++) {
  let shells = "";
  for (let i = 0; i < n; i++) shells += shell(SHELL_POS[i][0], SHELL_POS[i][1], 0.78, SHELL_COL[i]) + "\n";
  out("props/counters", `shell_jar_${n}.svg`, svg(90, 120, `${shadow(45, 114, 34, 5)}
  <rect x="14" y="30" width="62" height="82" rx="14" fill="#cfeeea" opacity="0.55"/>
${shells}  <rect x="14" y="30" width="62" height="82" rx="14" fill="none" stroke="${C.tealL}" stroke-width="3" opacity="0.8"/>
  <rect x="20" y="36" width="8" height="60" rx="4" fill="${C.white}" opacity="0.5"/>
  <rect x="18" y="18" width="54" height="16" rx="5" fill="${C.woodL}"/>
  <rect x="18" y="18" width="54" height="5" rx="2.5" fill="${C.goldL}" opacity="0.6"/>
  <path d="M16 30 L74 30" stroke="${C.coral}" stroke-width="4"/>`, `Jar of shells with ${n} shell${n > 1 ? "s" : ""} (counter prop).`));
}

// Daisy vase: n daisies on stems out of a little terracotta vase.
const DAISY_POS = [[50, 12], [28, 20], [72, 20], [38, 38], [62, 38], [14, 40], [86, 40], [24, 62], [76, 62]];
const daisy = (x, y) => {
  let petals = "";
  for (let k = 0; k < 8; k++) {
    const a = (k * 45 * Math.PI) / 180;
    petals += `<ellipse cx="${(x + Math.cos(a) * 6).toFixed(1)}" cy="${(y + Math.sin(a) * 6).toFixed(1)}" rx="3.6" ry="2.4" transform="rotate(${k * 45} ${(x + Math.cos(a) * 6).toFixed(1)} ${(y + Math.sin(a) * 6).toFixed(1)})" fill="${C.white}"/>`;
  }
  return `  <g>${petals}<circle cx="${x}" cy="${y}" r="3.6" fill="${C.gold}"/></g>`;
};
for (let n = 1; n <= 9; n++) {
  let stems = "", heads = "";
  for (let i = 0; i < n; i++) {
    const [x, y] = DAISY_POS[i];
    stems += `  <path d="M50 92 Q${(50 + x) / 2} ${(92 + y) / 2 + 8} ${x} ${y + 4}" stroke="${C.sageD}" stroke-width="2.4" fill="none"/>\n`;
    heads += daisy(x, y) + "\n";
  }
  out("props/counters", `daisy_vase_${n}.svg`, svg(100, 130, `${shadow(50, 125, 28, 5)}
${stems}${heads}  <path d="M34 90 L66 90 L62 124 L38 124 Z" fill="${C.terra}"/>
  <rect x="31" y="86" width="38" height="8" rx="3" fill="${C.terraL}"/>
  <path d="M38 98 L40 120" stroke="${C.white}" stroke-width="3" opacity="0.35"/>`, `Vase with ${n} ${n > 1 ? "daisies" : "daisy"} (counter prop).`));
}

// Harbour photo: n sailboats on the sea at dawn, in a white photo frame.
const BOAT_POS = [[30, 100, 0.95], [72, 100, 0.95], [114, 100, 0.95], [51, 83, 0.75], [93, 83, 0.75], [131, 83, 0.75], [30, 66, 0.55], [70, 66, 0.55], [110, 66, 0.55]];
const boat = (x, y, s) => `  <g transform="translate(${x} ${y}) scale(${s})">
    <path d="M-12 0 L12 0 L8 6 L-8 6 Z" fill="${C.woodD}"/>
    <path d="M0 -1 L0 -24 L11 -2 Z" fill="${C.white}"/>
    <path d="M-1 -2 L-1 -18 L-9 -2 Z" fill="${C.peachL}"/>
  </g>`;
for (let n = 1; n <= 9; n++) {
  let boats = "";
  const order = [...BOAT_POS.slice(0, n)].sort((a, b) => a[1] - b[1]);
  for (const [x, y, s] of order) boats += boat(x, y, s) + "\n";
  out("props/counters", `boat_photo_${n}.svg`, svg(160, 120, `  <defs><linearGradient id="dawn" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${C.lav}"/><stop offset="1" stop-color="${C.peach}"/></linearGradient></defs>
  <rect x="6" y="8" width="150" height="110" rx="4" fill="${C.ink}" opacity="0.18"/>
  <rect x="2" y="2" width="150" height="110" rx="4" fill="${C.white}"/>
  <rect x="10" y="10" width="134" height="94" fill="url(#dawn)"/>
  <circle cx="112" cy="50" r="12" fill="${C.gold}"/>
  <rect x="10" y="54" width="134" height="50" fill="${C.teal}"/>
  <rect x="10" y="54" width="134" height="4" fill="${C.tealL}"/>
  <rect x="96" y="62" width="30" height="3" rx="1.5" fill="${C.goldL}" opacity="0.7"/>
${boats}  <rect x="2" y="2" width="150" height="5" rx="2" fill="${C.cream}"/>`, `Harbour photo with ${n} boat${n > 1 ? "s" : ""} (counter prop).`));
}

// Bird picture: n little birds sitting on two wires.
const BIRD_POS = [[34, 44], [62, 46], [90, 46], [118, 44], [48, 80], [76, 82], [104, 82], [132, 80], [20, 78]];
const bird = (x, y, flip) => `  <g transform="translate(${x} ${y}) scale(${flip ? -1 : 1} 1)">
    <path d="M-7 -2 L-12 2 L-7 1 Z" fill="${C.inkSoft}"/>
    <ellipse cx="0" cy="-3" rx="7.5" ry="6" fill="${C.indigo}"/>
    <circle cx="5" cy="-9" r="4.2" fill="${C.indigo}"/>
    <path d="M9 -9.5 L12.5 -8.5 L9 -7.5 Z" fill="${C.gold}"/>
    <circle cx="6" cy="-10" r="1" fill="${C.white}"/>
    <ellipse cx="-1" cy="-2" rx="4" ry="2.6" fill="${C.lav}"/>
  </g>`;
for (let n = 1; n <= 9; n++) {
  let birds = "";
  for (let i = 0; i < n; i++) birds += bird(BIRD_POS[i][0], BIRD_POS[i][1], i % 3 === 1) + "\n";
  out("props/counters", `bird_picture_${n}.svg`, svg(160, 110, `  <rect x="6" y="8" width="150" height="100" rx="6" fill="${C.ink}" opacity="0.18"/>
  <rect x="2" y="2" width="150" height="100" rx="6" fill="${C.wood}"/>
  <rect x="10" y="10" width="134" height="84" fill="${C.cream}"/>
  <rect x="10" y="10" width="134" height="30" fill="${C.peachL}" opacity="0.6"/>
  <path d="M10 45 Q77 52 144 45" stroke="${C.inkSoft}" stroke-width="1.6" fill="none"/>
  <path d="M10 81 Q77 88 144 81" stroke="${C.inkSoft}" stroke-width="1.6" fill="none"/>
${birds}  <rect x="2" y="2" width="150" height="5" rx="2" fill="${C.woodL}"/>`, `Picture with ${n} bird${n > 1 ? "s" : ""} on the wires (counter prop).`));
}

// ================================================================== puzzle props

// Jar shelf (order lock): a wall shelf with four jars and a little drawer below.
const jarShelfTop = `  <rect x="12" y="102" width="150" height="10" rx="3" fill="${C.ink}" opacity="0.18"/>
  <rect x="8" y="94" width="154" height="12" rx="4" fill="${C.wood}"/>
  <rect x="8" y="94" width="154" height="4" rx="2" fill="${C.woodL}"/>
  ${[[22, C.coral], [58, C.tealL], [94, C.gold], [130, C.lav]].map(([x, col]) => `<rect x="${x}" y="46" width="28" height="48" rx="8" fill="#cfeeea" opacity="0.7"/><rect x="${x}" y="58" width="28" height="36" rx="7" fill="${col}" opacity="0.75"/><rect x="${x - 2}" y="38" width="32" height="10" rx="4" fill="${C.woodD}"/><rect x="${x + 4}" y="50" width="5" height="36" rx="2.5" fill="${C.white}" opacity="0.5"/>`).join("\n  ")}`;
out("props/puzzles", "jar_shelf.svg", svg(170, 150, `${jarShelfTop}
  <rect x="44" y="108" width="82" height="34" rx="6" fill="${C.woodL}"/>
  <rect x="50" y="114" width="70" height="22" rx="4" fill="${C.wood}"/>
  <circle cx="85" cy="125" r="4" fill="${C.brass}"/>`, "Jar shelf with a little drawer (order lock, closed)."));
out("props/puzzles", "jar_shelf_open.svg", svg(170, 150, `${jarShelfTop}
  <rect x="44" y="108" width="82" height="34" rx="6" fill="${C.woodL}"/>
  <rect x="50" y="114" width="70" height="22" rx="4" fill="${C.ink}"/>
  <rect x="40" y="128" width="90" height="18" rx="5" fill="${C.wood}"/>
  <circle cx="85" cy="137" r="4" fill="${C.brass}"/>`, "Jar shelf with its drawer pulled out (order lock, open)."));

// Photo ledge (order lock): four little frames on a ledge, a small cupboard below.
const frames = [[16, C.peach], [54, C.tealL], [92, C.lavL], [130, C.goldL]].map(([x, col], i) =>
  `<rect x="${x}" y="${30 + (i % 2) * 6}" width="32" height="${44 - (i % 2) * 6}" rx="3" fill="${C.white}"/><rect x="${x + 4}" y="${34 + (i % 2) * 6}" width="24" height="${34 - (i % 2) * 6}" fill="${col}"/><circle cx="${x + 16}" cy="${48 + (i % 2) * 4}" r="5" fill="${C.inkSoft}" opacity="0.5"/>`).join("\n  ");
const ledgeTop = `  <rect x="8" y="74" width="156" height="10" rx="3" fill="${C.woodD}"/>
  <rect x="8" y="74" width="156" height="3" fill="${C.woodL}"/>
  ${frames}`;
out("props/puzzles", "photo_ledge.svg", svg(170, 140, `${ledgeTop}
  <rect x="50" y="88" width="70" height="46" rx="6" fill="${C.wood}"/>
  <rect x="56" y="94" width="58" height="34" rx="4" fill="${C.woodL}"/>
  <circle cx="106" cy="111" r="3.5" fill="${C.brass}"/>`, "Photo ledge with a small cupboard (order lock, closed)."));
out("props/puzzles", "photo_ledge_open.svg", svg(170, 140, `${ledgeTop}
  <rect x="50" y="88" width="70" height="46" rx="6" fill="${C.wood}"/>
  <rect x="56" y="94" width="58" height="34" rx="4" fill="${C.ink}"/>
  <path d="M56 94 L40 100 L40 132 L56 128 Z" fill="${C.woodL}"/>`, "Photo ledge with its cupboard open (order lock, open)."));

// Morning paper with a 4x4 number square (sudoku lock).
const grid4 = (x, y, cell, filled) => {
  let s = `<rect x="${x}" y="${y}" width="${cell * 4}" height="${cell * 4}" fill="${C.white}" stroke="${C.ink}" stroke-width="1.5"/>`;
  for (let i = 1; i < 4; i++) {
    const w = i === 2 ? 1.6 : 0.7;
    s += `<path d="M${x + i * cell} ${y} V${y + cell * 4} M${x} ${y + i * cell} H${x + cell * 4}" stroke="${C.ink}" stroke-width="${w}"/>`;
  }
  const marks = filled ? [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] : [0, 3, 5, 6, 9, 12, 15];
  for (const m of marks) s += `<circle cx="${x + (m % 4) * cell + cell / 2}" cy="${y + Math.floor(m / 4) * cell + cell / 2}" r="${cell * 0.18}" fill="${C.inkSoft}"/>`;
  return s;
};
const paperBase = `${shadow(66, 84, 56, 5)}
  <path d="M8 18 L118 10 L124 76 L12 82 Z" fill="${C.cream}"/>
  <path d="M8 18 L118 10 L119 20 L9 28 Z" fill="${C.sand}"/>
  ${[36, 44, 52, 60, 68].map((y) => `<path d="M16 ${y + 2} L58 ${y - 1}" stroke="${C.inkSoft}" stroke-width="2" opacity="0.45"/>`).join("")}`;
out("props/puzzles", "newspaper.svg", svg(130, 90, `${paperBase}
  <g transform="rotate(-4 90 50)">${grid4(70, 30, 11, false)}</g>
  <rect x="92" y="62" width="30" height="5" rx="2.5" transform="rotate(-30 107 64)" fill="${C.gold}"/>`, "Morning paper folded open at the number square (sudoku lock)."));
out("props/puzzles", "newspaper_open.svg", svg(130, 90, `${paperBase}
  <g transform="rotate(-4 90 50)">${grid4(70, 30, 11, true)}</g>
  <path d="M100 18 L106 24 L118 10" stroke="${C.sageD}" stroke-width="4" fill="none" stroke-linecap="round"/>`, "Morning paper with the number square solved."));

// Number box: a wooden box with a 4x4 grid inlaid in the lid (sudoku lock).
out("props/puzzles", "number_box.svg", svg(110, 90, `${shadow(55, 84, 48, 5)}
  <rect x="8" y="30" width="94" height="52" rx="8" fill="${C.wood}"/>
  <rect x="4" y="18" width="102" height="22" rx="8" fill="${C.woodL}"/>
  <g transform="translate(34 20) scale(1 0.42)">${grid4(0, 0, 11, false)}</g>
  <rect x="48" y="50" width="14" height="12" rx="3" fill="${C.brass}"/>`, "Wooden number box (sudoku lock, closed)."));
out("props/puzzles", "number_box_open.svg", svg(110, 90, `${shadow(55, 84, 48, 5)}
  <rect x="8" y="30" width="94" height="52" rx="8" fill="${C.wood}"/>
  <rect x="14" y="30" width="82" height="14" rx="4" fill="${C.ink}"/>
  <path d="M6 30 L104 30 L96 4 L14 4 Z" fill="${C.woodL}"/>
  <g transform="translate(34 8) scale(1 0.42)">${grid4(0, 0, 11, true)}</g>`, "Wooden number box with its lid open."));

// Little chalkboard cupboard (pattern lock): chalk marks in a row, door opens.
const chalk = [18, 36, 54, 72, 90, 108].map((x, i) => i % 3 === 2
  ? `<rect x="${x}" y="${58}" width="11" height="11" fill="none" stroke="${C.white}" stroke-width="2.4"/>`
  : `<circle cx="${x + 5}" cy="${63}" r="5.5" fill="none" stroke="${C.white}" stroke-width="2.4"/>`).join("");
out("props/puzzles", "chalkboard.svg", svg(150, 150, `  <rect x="12" y="14" width="132" height="132" rx="8" fill="${C.ink}" opacity="0.18"/>
  <rect x="6" y="6" width="134" height="134" rx="8" fill="${C.woodL}"/>
  <rect x="16" y="16" width="114" height="100" rx="4" fill="#3f5a4c"/>
  ${chalk}
  <path d="M124 60 L128 60 M124 66 L128 66" stroke="${C.white}" stroke-width="2.4"/>
  <circle cx="126" cy="92" r="3" fill="${C.white}" opacity="0.8"/>
  <rect x="16" y="122" width="114" height="10" rx="3" fill="${C.wood}"/>
  <rect x="30" y="118" width="18" height="5" rx="2" fill="${C.white}"/>`, "Little chalkboard cupboard with a pattern of chalk marks (pattern lock, closed)."));
out("props/puzzles", "chalkboard_open.svg", svg(150, 150, `  <rect x="12" y="14" width="132" height="132" rx="8" fill="${C.ink}" opacity="0.18"/>
  <rect x="6" y="6" width="134" height="134" rx="8" fill="${C.woodL}"/>
  <rect x="16" y="16" width="114" height="100" rx="4" fill="${C.ink}"/>
  <rect x="16" y="64" width="114" height="5" fill="${C.wood}"/>
  <path d="M16 16 L2 22 L2 112 L16 116 Z" fill="#3f5a4c"/>
  <rect x="16" y="122" width="114" height="10" rx="3" fill="${C.wood}"/>`, "Chalkboard cupboard, door open (pattern lock, open)."));

// Bead box (pattern lock): a necklace with a pattern of beads, one gap.
const beads = [C.coral, C.teal, C.gold, C.coral, C.teal, C.gold, C.coral].map((col, i) =>
  i === 6 ? `<circle cx="${18 + i * 13}" cy="${42 + Math.sin(i) * 3}" r="5" fill="none" stroke="${C.inkSoft}" stroke-dasharray="2 2"/>` :
  `<circle cx="${18 + i * 13}" cy="${42 + Math.sin(i) * 3}" r="5.5" fill="${col}"/>`).join("");
out("props/puzzles", "bead_box.svg", svg(120, 80, `${shadow(60, 74, 52, 5)}
  <rect x="8" y="26" width="104" height="46" rx="8" fill="${C.lav}"/>
  <rect x="14" y="30" width="92" height="36" rx="5" fill="${C.lavL}"/>
  <path d="M14 40 Q60 52 106 40" stroke="${C.inkSoft}" stroke-width="1.2" fill="none"/>
  ${beads}`, "Box with a bead necklace missing some beads (pattern lock, closed)."));
out("props/puzzles", "bead_box_open.svg", svg(120, 80, `${shadow(60, 74, 52, 5)}
  <rect x="8" y="26" width="104" height="46" rx="8" fill="${C.lav}"/>
  <rect x="14" y="30" width="92" height="36" rx="5" fill="${C.indigo}"/>
  <path d="M14 40 Q60 52 106 40" stroke="${C.gold}" stroke-width="1.6" fill="none"/>
  ${[C.coral, C.teal, C.gold, C.coral, C.teal, C.gold, C.coral].map((col, i) => `<circle cx="${18 + i * 13}" cy="${42 + Math.sin(i) * 3}" r="5.5" fill="${col}"/>`).join("")}`, "Bead box with the necklace complete (pattern lock, open)."));

// Picture box (rotate lock): a box whose lid is a picture in 2x2 turned tiles.
const tilesLid = `<g transform="translate(30 20)">
    <rect x="0" y="0" width="24" height="14" fill="${C.lav}"/><rect x="26" y="0" width="24" height="14" fill="${C.peach}" transform="rotate(180 38 7)"/>
    <rect x="0" y="16" width="24" height="12" fill="${C.teal}" transform="rotate(180 12 22)"/><rect x="26" y="16" width="24" height="12" fill="${C.teal}"/>
    <circle cx="38" cy="10" r="4" fill="${C.gold}"/>
  </g>`;
out("props/puzzles", "picture_box.svg", svg(110, 90, `${shadow(55, 84, 48, 5)}
  <rect x="8" y="30" width="94" height="52" rx="8" fill="${C.terra}"/>
  <rect x="4" y="16" width="102" height="24" rx="8" fill="${C.terraL}"/>
  ${tilesLid}
  <rect x="48" y="52" width="14" height="12" rx="3" fill="${C.brass}"/>`, "Box with a turned-tile picture on the lid (rotate lock, closed)."));
out("props/puzzles", "picture_box_open.svg", svg(110, 90, `${shadow(55, 84, 48, 5)}
  <rect x="8" y="30" width="94" height="52" rx="8" fill="${C.terra}"/>
  <rect x="14" y="30" width="82" height="14" rx="4" fill="${C.ink}"/>
  <path d="M6 30 L104 30 L96 4 L14 4 Z" fill="${C.terraL}"/>`, "Picture box with its lid open (rotate lock, open)."));

// Tile picture (rotate lock): a frame with 3x3 picture tiles, some turned; it swings open.
let tiles = "";
for (let r = 0; r < 3; r++) for (let c = 0; c < 3; c++) {
  const x = 22 + c * 36, y = 22 + r * 36;
  const col = r === 0 ? C.lav : r === 1 ? C.peach : C.teal;
  const turn = (r * 3 + c) % 3 === 1 ? 90 : (r * 3 + c) % 4 === 2 ? 180 : 0;
  tiles += `<g transform="rotate(${turn} ${x + 17} ${y + 17})"><rect x="${x}" y="${y}" width="34" height="34" fill="${col}"/>${r === 1 && c === 1 ? `<circle cx="${x + 17}" cy="${y + 24}" r="10" fill="${C.gold}"/>` : ""}<rect x="${x}" y="${y}" width="34" height="6" fill="${C.white}" opacity="0.25"/></g>`;
}
out("props/puzzles", "tile_frame.svg", svg(150, 150, `  <rect x="12" y="14" width="132" height="132" rx="6" fill="${C.ink}" opacity="0.18"/>
  <rect x="6" y="6" width="134" height="134" rx="6" fill="${C.brass}"/>
  <rect x="16" y="16" width="114" height="114" fill="${C.ink}"/>
  ${tiles}`, "Frame with 3x3 turned picture tiles (rotate lock, closed)."));
out("props/puzzles", "tile_frame_open.svg", svg(150, 150, `  <rect x="12" y="14" width="132" height="132" rx="6" fill="${C.ink}" opacity="0.18"/>
  <rect x="24" y="16" width="112" height="118" rx="4" fill="${C.inkSoft}"/>
  <rect x="30" y="70" width="100" height="6" fill="${C.woodD}"/>
  <path d="M24 10 L4 22 L4 140 L24 138 Z" fill="${C.brass}"/>`, "Tile frame swung open (rotate lock, open)."));

// ================================================================== rotate pictures (600x600)

out("puzzles", "picture_lemon_tree.svg", svg(600, 600, `  <defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${C.lav}"/><stop offset="1" stop-color="${C.peachL}"/></linearGradient></defs>
  <rect width="600" height="600" fill="url(#sky)"/>
  <circle cx="470" cy="130" r="56" fill="${C.gold}"/>
  <circle cx="470" cy="130" r="80" fill="${C.goldL}" opacity="0.35"/>
  <path d="M0 430 Q150 400 300 420 T600 410 L600 600 L0 600 Z" fill="${C.sage}"/>
  <path d="M0 470 Q200 450 360 470 T600 460 L600 600 L0 600 Z" fill="${C.sageD}"/>
  <path d="M282 440 C276 360 270 320 250 280 L272 276 C288 312 300 350 306 440 Z" fill="${C.woodD}"/>
  <path d="M290 330 C320 300 350 290 380 292" stroke="${C.woodD}" stroke-width="14" fill="none" stroke-linecap="round"/>
  <circle cx="260" cy="230" r="120" fill="${C.sageD}"/>
  <circle cx="330" cy="200" r="100" fill="${C.sage}"/>
  <circle cx="200" cy="200" r="80" fill="${C.sage}"/>
  ${[[210, 170], [300, 150], [360, 230], [250, 260], [180, 250], [320, 290], [270, 200]].map(([x, y]) => `<ellipse cx="${x}" cy="${y}" rx="16" ry="12" fill="${C.gold}"/><ellipse cx="${x - 4}" cy="${y - 4}" rx="5" ry="3" fill="${C.white}" opacity="0.6"/>`).join("")}
  <rect x="90" y="470" width="130" height="14" rx="5" fill="${C.wood}"/>
  <rect x="100" y="484" width="10" height="44" fill="${C.woodD}"/><rect x="200" y="484" width="10" height="44" fill="${C.woodD}"/>
  <rect x="90" y="440" width="130" height="12" rx="5" fill="${C.woodL}"/>`, "Lemon tree in the garden at dawn (rotation puzzle picture)."));

out("puzzles", "picture_market.svg", svg(600, 600, `  <defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${C.peachL}"/><stop offset="1" stop-color="${C.cream}"/></linearGradient></defs>
  <rect width="600" height="600" fill="url(#sky)"/>
  <circle cx="110" cy="110" r="46" fill="${C.gold}"/>
  <rect x="0" y="470" width="600" height="130" fill="${C.sand}"/>
  ${[0, 60, 120, 180, 240, 300, 360, 420, 480, 540].map((x, i) => `<ellipse cx="${x + 30}" cy="${520 + (i % 2) * 30}" rx="24" ry="10" fill="${C.woodL}" opacity="0.45"/>`).join("")}
  <rect x="120" y="240" width="14" height="240" fill="${C.woodD}"/><rect x="466" y="240" width="14" height="240" fill="${C.woodD}"/>
  ${[0, 1, 2, 3, 4, 5, 6].map((i) => `<path d="M${100 + i * 57} 190 L${157 + i * 57} 190 L${157 + i * 57} 260 Q${128 + i * 57} 280 ${100 + i * 57} 260 Z" fill="${i % 2 ? C.white : C.coral}"/>`).join("")}
  <rect x="90" y="176" width="420" height="18" rx="6" fill="${C.coralD}"/>
  <rect x="110" y="380" width="380" height="24" rx="6" fill="${C.wood}"/>
  <rect x="120" y="404" width="360" height="70" fill="${C.woodL}"/>
  ${[[150, C.gold], [220, C.coral], [290, C.sage], [360, C.peach], [430, C.gold]].map(([x, col]) => `<rect x="${x - 26}" y="336" width="52" height="46" rx="6" fill="${C.wood}"/>${[0, 1, 2].map((k) => `<circle cx="${x - 14 + k * 14}" cy="${338 - (k % 2) * 8}" r="10" fill="${col}"/>`).join("")}`).join("")}
  <path d="M300 300 C290 280 310 270 300 250" stroke="${C.sageD}" stroke-width="4" fill="none"/>
  <circle cx="300" cy="244" r="16" fill="${C.gold}"/><circle cx="300" cy="244" r="6" fill="${C.woodD}"/>`, "Market stall with fruit under a striped awning (rotation puzzle picture)."));

// ================================================================== badges

out("ui", "puzzle_badge.svg", svg(64, 64, `  <circle cx="32" cy="32" r="27" fill="${C.white}" opacity="0.85"/>
  <path d="M18 22 H27 C27 16 37 16 37 22 H46 V31 C52 31 52 41 46 41 V48 H37 C37 42 27 42 27 48 H18 Z" fill="${C.coral}"/>
  <path d="M18 22 H27 C27 16 37 16 37 22 H46 V26 H18 Z" fill="${C.peachL}" opacity="0.6"/>`, "Small badge: this is a puzzle."));
out("ui", "tool_badge.svg", svg(64, 64, `  <circle cx="32" cy="32" r="27" fill="${C.white}" opacity="0.85"/>
  <path d="M42 14 C36 14 32 19 34 25 L16 43 C14 45 14 48 16 50 C18 52 21 52 23 50 L41 32 C47 34 52 30 52 24 L46 28 L40 24 L40 18 Z" fill="${C.teal}"/>
  <circle cx="19.5" cy="46.5" r="2.4" fill="${C.white}"/>`, "Small badge: this needs a tool."));

console.log("puzzle v2 art written");
