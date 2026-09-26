// Generates the shared prop SVGs in assets/sprites/props/common/ (wall safe, clock, painting, boxes, notes...).
// The SVG files are the real, editable art; this script is just how they were first drawn.
// Re-running it overwrites those files:  node tools/art/props_common.mjs
import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const OUT = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "assets", "sprites", "props", "common");
mkdirSync(OUT, { recursive: true });
const svg = (w, h, body, note) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${w} ${h}" width="${w}" height="${h}">\n  <!-- ${note} -->\n${body}\n</svg>\n`;
const files = {};

// ---- wall safe
const safeBody = `  <rect x="8" y="10" width="140" height="138" rx="16" fill="#3b2e3a" opacity="0.15"/>
  <rect x="4" y="4" width="140" height="138" rx="16" fill="#1f5f6b"/>
  <rect x="4" y="4" width="140" height="10" rx="5" fill="#6cc2be" opacity="0.35"/>`;
files["wall_safe.svg"] = svg(150, 150, `${safeBody}
  <rect x="16" y="16" width="116" height="114" rx="10" fill="#2e8c8c"/>
  <rect x="16" y="16" width="116" height="8" rx="4" fill="#6cc2be" opacity="0.5"/>
  <circle cx="68" cy="72" r="30" fill="#a87a2e"/>
  <circle cx="68" cy="72" r="25" fill="#d4a24c"/>
  <circle cx="68" cy="72" r="10" fill="#a87a2e"/>
  <g stroke="#7a5134" stroke-width="3" stroke-linecap="round">
    <line x1="68" y1="49" x2="68" y2="55"/><line x1="91" y1="72" x2="85" y2="72"/><line x1="68" y1="95" x2="68" y2="89"/><line x1="45" y1="72" x2="51" y2="72"/>
  </g>
  <circle cx="61" cy="64" r="4" fill="#fbe3a0" opacity="0.8"/>
  <rect x="108" y="56" width="12" height="34" rx="6" fill="#d4a24c"/>
  <rect x="110" y="58" width="4" height="28" rx="2" fill="#fbe3a0" opacity="0.8"/>
  <circle cx="28" cy="28" r="4" fill="#1f5f6b"/><circle cx="120" cy="28" r="4" fill="#1f5f6b"/><circle cx="28" cy="118" r="4" fill="#1f5f6b"/><circle cx="120" cy="118" r="4" fill="#1f5f6b"/>`, "Wall safe (closed).");
files["wall_safe_open.svg"] = svg(150, 150, `${safeBody}
  <rect x="16" y="16" width="116" height="114" rx="8" fill="#123c44"/>
  <rect x="16" y="78" width="116" height="6" fill="#1f5f6b"/>
  <rect x="16" y="16" width="116" height="10" fill="#000000" opacity="0.2"/>
  <path d="M16 16 L2 26 L2 122 L16 130 Z" fill="#2e8c8c"/>
  <path d="M16 16 L8 21 L8 126 L16 130 Z" fill="#6cc2be" opacity="0.4"/>
  <circle cx="7" cy="72" r="5" fill="#d4a24c"/>`, "Wall safe (open).");

// ---- wall clock: little wooden house clock with a compartment door under the face
const clockTop = `  <rect x="24" y="30" width="108" height="118" rx="10" fill="#3b2e3a" opacity="0.15"/>
  <path d="M75 4 L142 52 L8 52 Z" fill="#7a5134"/>
  <path d="M75 12 L130 50 L20 50 Z" fill="#a8744a"/>
  <rect x="20" y="46" width="110" height="98" rx="8" fill="#c99a6b"/>
  <rect x="20" y="46" width="110" height="8" fill="#3b2e3a" opacity="0.12"/>
  <circle cx="75" cy="84" r="30" fill="#a87a2e"/>
  <circle cx="75" cy="84" r="26" fill="#fff4e2"/>
  <g stroke="#6b5a66" stroke-width="3" stroke-linecap="round">
    <line x1="75" y1="61" x2="75" y2="66"/><line x1="98" y1="84" x2="93" y2="84"/><line x1="75" y1="107" x2="75" y2="102"/><line x1="52" y1="84" x2="57" y2="84"/>
  </g>
  <line x1="75" y1="84" x2="62" y2="74" stroke="#3b2e3a" stroke-width="4" stroke-linecap="round"/>
  <line x1="75" y1="84" x2="90" y2="68" stroke="#3b2e3a" stroke-width="3" stroke-linecap="round"/>
  <circle cx="75" cy="84" r="4" fill="#ee7b6b"/>
  <circle cx="75" cy="30" r="7" fill="#f6c453"/>`;
files["wall_clock.svg"] = svg(150, 150, `${clockTop}
  <rect x="52" y="118" width="46" height="24" rx="4" fill="#a8744a"/>
  <circle cx="92" cy="130" r="3" fill="#d4a24c"/>`, "Little wooden wall clock with a compartment under the face (closed).");
files["wall_clock_open.svg"] = svg(150, 150, `${clockTop}
  <rect x="52" y="118" width="46" height="24" rx="4" fill="#3b2e3a"/>
  <path d="M52 118 L38 124 L38 146 L52 142 Z" fill="#a8744a"/>`, "Wall clock with its little compartment open.");

// ---- painting of the sea (clue carrier / hides a niche)
const paintingArt = (tx, rot) => `  <g transform="translate(${tx} 0) rotate(${rot} 80 65)">
    <rect x="6" y="8" width="152" height="120" rx="6" fill="#3b2e3a" opacity="0.18"/>
    <rect x="2" y="2" width="152" height="120" rx="6" fill="#d4a24c"/>
    <rect x="12" y="12" width="132" height="100" fill="#f9b98a"/>
    <rect x="12" y="12" width="132" height="40" fill="#9c8ac4"/>
    <rect x="12" y="44" width="132" height="18" fill="#ee7b6b" opacity="0.6"/>
    <circle cx="96" cy="70" r="16" fill="#f6c453"/>
    <rect x="12" y="70" width="132" height="42" fill="#2e8c8c"/>
    <rect x="12" y="70" width="132" height="6" fill="#6cc2be"/>
    <rect x="70" y="82" width="40" height="4" rx="2" fill="#fbe3a0" opacity="0.8"/>
    <rect x="82" y="92" width="24" height="3" rx="1" fill="#fbe3a0" opacity="0.6"/>
    <path d="M40 90 L60 90 L56 98 L44 98 Z" fill="#fff4e2"/>
    <path d="M50 88 L50 64 L62 86 Z" fill="#fffbf5"/>
    <path d="M30 34 C33 30 36 30 38 34 C40 30 43 30 46 34" stroke="#3b2e3a" stroke-width="2" fill="none"/>
    <path d="M60 26 C62 23 64 23 66 26 C68 23 70 23 72 26" stroke="#3b2e3a" stroke-width="2" fill="none"/>
    <path d="M112 30 C114 27 117 27 119 30 C121 27 124 27 126 30" stroke="#3b2e3a" stroke-width="2" fill="none"/>
    <rect x="2" y="2" width="152" height="6" rx="3" fill="#fbe3a0" opacity="0.6"/>
  </g>`;
files["painting.svg"] = svg(160, 130, paintingArt(0, 0), "Sea painting with three gulls (can hide a niche behind it).");
files["painting_open.svg"] = svg(160, 130, `  <rect x="30" y="24" width="96" height="80" rx="6" fill="#6b5a66"/>
  <rect x="36" y="30" width="84" height="68" rx="4" fill="#3b2e3a"/>
${paintingArt(34, 14)}`, "Sea painting swung aside, showing a niche in the wall.");

// ---- switch panel
const plate = `  <rect x="6" y="6" width="56" height="96" rx="10" fill="#3b2e3a" opacity="0.15"/>
  <rect x="2" y="2" width="56" height="96" rx="10" fill="#d4a24c"/>
  <rect x="2" y="2" width="56" height="8" rx="4" fill="#fbe3a0" opacity="0.6"/>`;
const toggles = [22, 42, 62, 82].map((y, i) => `  <rect x="14" y="${y - 7}" width="32" height="14" rx="7" fill="#a87a2e"/>
  <circle cx="${i % 2 ? 36 : 24}" cy="${y}" r="6" fill="#fff4e2"/>`).join("\n");
files["switch_panel.svg"] = svg(64, 104, `${plate}\n${toggles}`, "Brass panel with four little switches.");
files["switch_panel_open.svg"] = svg(64, 104, `  <rect x="4" y="4" width="56" height="96" rx="10" fill="#3b2e3a"/>
  <rect x="8" y="50" width="48" height="4" fill="#6b5a66"/>
  <path d="M4 4 L1 10 L1 96 L4 100 Z" fill="#d4a24c"/>`, "Switch panel swung open, showing a hollow.");

// ---- vent
const slats = [22, 36, 50, 64].map(y => `  <rect x="18" y="${y}" width="94" height="8" rx="4" fill="#e9d6b8"/>`).join("\n");
files["vent.svg"] = svg(130, 90, `  <rect x="6" y="6" width="122" height="82" rx="8" fill="#3b2e3a" opacity="0.12"/>
  <rect x="2" y="2" width="122" height="82" rx="8" fill="#fffbf5"/>
  <rect x="12" y="14" width="102" height="60" rx="4" fill="#6b5a66"/>
${slats}
  <circle cx="10" cy="10" r="4" fill="#a87a2e"/><circle cx="116" cy="10" r="4" fill="#a87a2e"/><circle cx="10" cy="76" r="4" fill="#a87a2e"/><circle cx="116" cy="76" r="4" fill="#a87a2e"/>
  <line x1="7" y1="10" x2="13" y2="10" stroke="#7a5134" stroke-width="2"/><line x1="113" y1="10" x2="119" y2="10" stroke="#7a5134" stroke-width="2"/>`, "Air vent screwed to the wall.");
files["vent_open.svg"] = svg(130, 90, `  <rect x="12" y="14" width="102" height="60" rx="4" fill="#2b2350"/>
  <rect x="12" y="14" width="102" height="10" fill="#000000" opacity="0.25"/>
  <g transform="rotate(14 20 80)">
    <rect x="4" y="44" width="116" height="40" rx="8" fill="#fffbf5"/>
    <rect x="18" y="52" width="90" height="6" rx="3" fill="#e9d6b8"/><rect x="18" y="64" width="90" height="6" rx="3" fill="#e9d6b8"/>
  </g>`, "Air vent with its cover taken off.");

// ---- photo frame on the wall
files["photo_frame.svg"] = svg(130, 150, `  <rect x="8" y="8" width="120" height="140" rx="6" fill="#3b2e3a" opacity="0.15"/>
  <rect x="2" y="2" width="120" height="140" rx="6" fill="#fffbf5"/>
  <rect x="5" y="5" width="114" height="134" rx="5" fill="none" stroke="#d4a24c" stroke-width="6"/>
  <rect x="16" y="16" width="92" height="110" fill="#fcd9b8"/>
  <rect x="16" y="16" width="92" height="56" fill="#9c8ac4" opacity="0.7"/>
  <rect x="16" y="86" width="92" height="40" fill="#2e8c8c"/>
  <rect x="16" y="98" width="92" height="6" fill="#a8744a"/>
  <rect x="16" y="104" width="92" height="22" fill="#7a5134"/>
  <circle cx="60" cy="58" r="10" fill="#fcd9b8"/>
  <ellipse cx="60" cy="50" rx="20" ry="5" fill="#f6c453"/>
  <path d="M52 50 C52 40 68 40 68 50 Z" fill="#f6c453"/>
  <rect x="50" y="68" width="20" height="30" rx="8" fill="#ee7b6b"/>
  <rect x="54" y="96" width="4" height="10" fill="#3b2e3a"/><rect x="62" y="96" width="4" height="10" fill="#3b2e3a"/>
  <path d="M68 74 L80 64" stroke="#fcd9b8" stroke-width="5" stroke-linecap="round"/>`, "Framed photo of Grandma June on a pier, waving.");

// ---- corkboard
files["corkboard.svg"] = svg(160, 130, `  <rect x="6" y="8" width="154" height="122" rx="8" fill="#3b2e3a" opacity="0.15"/>
  <rect x="2" y="2" width="154" height="122" rx="8" fill="#a8744a"/>
  <rect x="10" y="10" width="138" height="106" rx="4" fill="#d9b07e"/>
  <g fill="#c99a6b" opacity="0.7"><circle cx="30" cy="30" r="2"/><circle cx="90" cy="20" r="2"/><circle cx="130" cy="60" r="2"/><circle cx="40" cy="100" r="2"/><circle cx="110" cy="100" r="2"/><circle cx="70" cy="70" r="2"/></g>
  <rect x="20" y="22" width="50" height="40" fill="#fff4e2" transform="rotate(-6 45 42)"/>
  <rect x="80" y="18" width="52" height="60" fill="#fffbf5" transform="rotate(5 106 48)"/>
  <rect x="85" y="24" width="42" height="36" fill="#6cc2be" transform="rotate(5 106 48)"/>
  <rect x="34" y="70" width="60" height="36" fill="#fcd9b8" transform="rotate(3 64 88)"/>
  <circle cx="45" cy="24" r="4" fill="#ee7b6b"/><circle cx="106" cy="20" r="4" fill="#2e8c8c"/><circle cx="64" cy="72" r="4" fill="#f6c453"/>
  <path d="M26 36 H62 M26 44 H56 M26 52 H60" stroke="#6b5a66" stroke-width="2" transform="rotate(-6 45 42)"/>`, "Corkboard with pinned notes and a polaroid.");

// ---- calendar
files["calendar.svg"] = svg(60, 96, `  <rect x="4" y="6" width="54" height="88" rx="4" fill="#3b2e3a" opacity="0.15"/>
  <rect x="2" y="4" width="54" height="88" rx="4" fill="#fffbf5"/>
  <rect x="2" y="4" width="54" height="22" rx="4" fill="#ee7b6b"/>
  <circle cx="16" cy="6" r="3" fill="#6b5a66"/><circle cx="42" cy="6" r="3" fill="#6b5a66"/>
  <g fill="#c9bde3"><rect x="8" y="34" width="8" height="6"/><rect x="20" y="34" width="8" height="6"/><rect x="32" y="34" width="8" height="6"/><rect x="44" y="34" width="8" height="6"/>
  <rect x="8" y="46" width="8" height="6"/><rect x="20" y="46" width="8" height="6"/><rect x="32" y="46" width="8" height="6"/><rect x="44" y="46" width="8" height="6"/>
  <rect x="8" y="58" width="8" height="6"/><rect x="20" y="58" width="8" height="6"/><rect x="44" y="58" width="8" height="6"/>
  <rect x="8" y="70" width="8" height="6"/><rect x="20" y="70" width="8" height="6"/><rect x="32" y="70" width="8" height="6"/></g>
  <circle cx="36" cy="61" r="8" fill="none" stroke="#ee7b6b" stroke-width="2.5"/>`, "Small wall calendar with a circled date.");

// ---- surface props
const box = (bodyFill, lidFill, extra) => `  <ellipse cx="60" cy="86" rx="56" ry="5" fill="#3b2e3a" opacity="0.18"/>
  <rect x="6" y="30" width="108" height="56" rx="8" fill="${bodyFill}"/>
  <rect x="6" y="30" width="108" height="8" fill="#3b2e3a" opacity="0.12"/>
  <rect x="2" y="18" width="116" height="20" rx="8" fill="${lidFill}"/>
  <rect x="8" y="21" width="60" height="4" rx="2" fill="#fffbf5" opacity="0.4"/>
${extra}`;
files["lockbox.svg"] = svg(120, 92, box("#c95b52", "#ee7b6b", `  <rect x="46" y="34" width="28" height="30" rx="5" fill="#d4a24c"/>
  <circle cx="60" cy="46" r="5" fill="#7a5134"/><rect x="58" y="48" width="4" height="10" rx="2" fill="#7a5134"/>`), "Coral lockbox with a brass lock plate.");
files["lockbox_open.svg"] = svg(120, 92, `  <ellipse cx="60" cy="86" rx="56" ry="5" fill="#3b2e3a" opacity="0.18"/>
  <path d="M8 22 L112 22 L104 4 L16 4 Z" fill="#ee7b6b"/>
  <rect x="6" y="30" width="108" height="56" rx="8" fill="#c95b52"/>
  <rect x="12" y="30" width="96" height="14" rx="4" fill="#5a2a2a"/>
  <rect x="46" y="44" width="28" height="22" rx="5" fill="#d4a24c"/>`, "Lockbox with its lid open.");
files["tin_box.svg"] = svg(110, 84, `  <ellipse cx="55" cy="78" rx="52" ry="5" fill="#3b2e3a" opacity="0.18"/>
  <rect x="6" y="26" width="98" height="52" rx="14" fill="#6cc2be"/>
  <rect x="6" y="46" width="98" height="10" fill="#fff4e2" opacity="0.6"/>
  <rect x="2" y="16" width="106" height="20" rx="10" fill="#2e8c8c"/>
  <circle cx="30" cy="62" r="5" fill="#f6c453"/><circle cx="55" cy="66" r="5" fill="#ee7b6b"/><circle cx="80" cy="62" r="5" fill="#f6c453"/>
  <rect x="49" y="18" width="12" height="16" rx="3" fill="#d4a24c"/><circle cx="55" cy="24" r="2.5" fill="#7a5134"/>`, "Biscuit tin with a little lock on the lid.");
files["tin_box_open.svg"] = svg(110, 84, `  <ellipse cx="55" cy="78" rx="52" ry="5" fill="#3b2e3a" opacity="0.18"/>
  <rect x="6" y="26" width="98" height="52" rx="14" fill="#6cc2be"/>
  <rect x="12" y="26" width="86" height="12" rx="6" fill="#1f5f6b"/>
  <rect x="6" y="46" width="98" height="10" fill="#fff4e2" opacity="0.6"/>
  <ellipse cx="92" cy="18" rx="18" ry="6" fill="#2e8c8c" transform="rotate(20 92 18)"/>`, "Biscuit tin, lid off.");
const musicLid = `  <rect x="2" y="16" width="106" height="20" rx="6" fill="#c99a6b"/>
  <circle cx="30" cy="26" r="5" fill="#f6c453"/><circle cx="55" cy="26" r="5" fill="#ee7b6b"/><circle cx="80" cy="26" r="5" fill="#2e8c8c"/>`;
files["music_box.svg"] = svg(110, 92, `  <ellipse cx="55" cy="86" rx="52" ry="5" fill="#3b2e3a" opacity="0.18"/>
  <rect x="6" y="30" width="98" height="56" rx="6" fill="#a8744a"/>
  <rect x="14" y="40" width="82" height="36" rx="4" fill="#7a5134"/>
  <path d="M30 58 C40 48 50 68 60 58 C70 48 80 68 90 58" stroke="#fbe3a0" stroke-width="3" fill="none"/>
${musicLid}
  <rect x="104" y="50" width="6" height="18" rx="3" fill="#d4a24c"/>`, "Wooden music box with symbol inlays and a crank.");
files["music_box_open.svg"] = svg(110, 92, `  <ellipse cx="55" cy="86" rx="52" ry="5" fill="#3b2e3a" opacity="0.18"/>
  <path d="M4 30 L106 30 L100 2 L10 2 Z" fill="#c99a6b"/>
  <rect x="10" y="6" width="90" height="20" rx="3" fill="#fbe3a0" opacity="0.5"/>
  <rect x="6" y="30" width="98" height="56" rx="6" fill="#a8744a"/>
  <rect x="12" y="30" width="86" height="12" rx="4" fill="#5a3a26"/>
  <circle cx="55" cy="30" r="8" fill="#f6c453"/>`, "Music box with its lid up; a tiny golden sun spins inside.");
const tiles = [0, 1, 2].flatMap(r => [0, 1, 2].map(c => `  <rect x="${30 + c * 17}" y="${44 + r * 13}" width="15" height="11" rx="2" fill="${["#f6c453", "#ee7b6b", "#2e8c8c"][(r + c) % 3]}"/>`)).join("\n");
files["puzzle_box.svg"] = svg(110, 100, `  <ellipse cx="55" cy="94" rx="52" ry="5" fill="#3b2e3a" opacity="0.18"/>
  <rect x="6" y="26" width="98" height="68" rx="8" fill="#9c8ac4"/>
  <rect x="2" y="16" width="106" height="18" rx="8" fill="#c9bde3"/>
  <rect x="26" y="40" width="58" height="46" rx="4" fill="#3e3570"/>
${tiles}`, "Puzzle box with a sliding-tile picture on its front.");
files["puzzle_box_open.svg"] = svg(110, 100, `  <ellipse cx="55" cy="94" rx="52" ry="5" fill="#3b2e3a" opacity="0.18"/>
  <path d="M4 28 L106 28 L98 0 L12 0 Z" fill="#c9bde3"/>
  <rect x="6" y="26" width="98" height="68" rx="8" fill="#9c8ac4"/>
  <rect x="12" y="26" width="86" height="12" rx="4" fill="#3e3570"/>
  <rect x="26" y="44" width="58" height="42" rx="4" fill="#f9b98a"/>
  <circle cx="55" cy="68" r="10" fill="#f6c453"/><rect x="26" y="70" width="58" height="16" fill="#2e8c8c"/>`, "Puzzle box, solved and open.");
files["jar.svg"] = svg(80, 124, `  <ellipse cx="40" cy="118" rx="36" ry="5" fill="#3b2e3a" opacity="0.18"/>
  <rect x="14" y="4" width="52" height="14" rx="5" fill="#a8744a"/>
  <path d="M10 22 C10 16 70 16 70 22 L70 108 C70 116 64 120 56 120 L24 120 C16 120 10 116 10 108 Z" fill="#6cc2be" opacity="0.45"/>
  <ellipse cx="30" cy="104" rx="10" ry="6" fill="#ee7b6b"/><ellipse cx="50" cy="108" rx="9" ry="6" fill="#fcd9b8"/><ellipse cx="40" cy="96" rx="7" ry="5" fill="#9c8ac4"/>
  <circle cx="46" cy="112" r="4" fill="#f6c453"/><circle cx="45" cy="111" r="1.5" fill="#fffbf5"/>
  <rect x="16" y="28" width="8" height="70" rx="4" fill="#fffbf5" opacity="0.5"/>`, "Tall jar of sea glass and shells; something glints at the bottom.");
files["note.svg"] = svg(90, 62, `  <ellipse cx="45" cy="56" rx="40" ry="4" fill="#3b2e3a" opacity="0.15"/>
  <g transform="rotate(-6 45 32)">
    <rect x="8" y="10" width="74" height="46" rx="3" fill="#fffbf5"/>
    <path d="M8 34 L82 34" stroke="#f3ddb3" stroke-width="3"/>
    <path d="M16 20 H60 M16 27 H52 M16 42 H64 M16 49 H44" stroke="#9c8ac4" stroke-width="2.5" stroke-linecap="round"/>
    <path d="M70 44 C66 40 64 46 70 50 C76 46 74 40 70 44 Z" fill="#ee7b6b"/>
  </g>`, "A folded note in Grandma's handwriting.");
files["open_book.svg"] = svg(130, 62, `  <ellipse cx="65" cy="56" rx="60" ry="5" fill="#3b2e3a" opacity="0.15"/>
  <path d="M6 16 C30 8 52 10 64 18 L64 56 C52 48 30 46 6 54 Z" fill="#fffbf5"/>
  <path d="M124 16 C100 8 78 10 66 18 L66 56 C78 48 100 46 124 54 Z" fill="#fff4e2"/>
  <path d="M4 18 L4 58 C30 50 52 50 64 58 L66 58 C78 50 100 50 126 58 L126 18" stroke="#2e8c8c" stroke-width="4" fill="none"/>
  <path d="M14 24 H54 M14 32 H50 M14 40 H56 M76 24 H116 M76 32 H112 M76 40 H104" stroke="#c9bde3" stroke-width="2.5" stroke-linecap="round"/>`, "An open travel diary.");
files["photo_stand.svg"] = svg(80, 102, `  <ellipse cx="40" cy="98" rx="34" ry="4" fill="#3b2e3a" opacity="0.18"/>
  <path d="M30 96 L40 60 L50 96 Z" fill="#7a5134"/>
  <rect x="6" y="6" width="68" height="86" rx="4" fill="#d4a24c"/>
  <rect x="12" y="12" width="56" height="74" fill="#fcd9b8"/>
  <rect x="12" y="12" width="56" height="30" fill="#6cc2be"/>
  <circle cx="40" cy="52" r="9" fill="#f9b98a"/><rect x="30" y="60" width="20" height="26" rx="8" fill="#9c8ac4"/>
  <path d="M26 44 C30 36 50 36 54 44 Z" fill="#fffbf5"/>`, "A standing photo frame.");
files["postcard_small.svg"] = svg(70, 52, `  <g transform="rotate(-8 35 26)">
    <rect x="6" y="8" width="60" height="40" rx="3" fill="#3b2e3a" opacity="0.15"/>
    <rect x="4" y="6" width="60" height="40" rx="3" fill="#fffbf5"/>
    <rect x="44" y="10" width="16" height="18" rx="2" fill="#ee7b6b"/>
    <circle cx="52" cy="19" r="4" fill="#f6c453"/>
    <path d="M10 18 H38 M10 26 H34 M10 34 H38" stroke="#9c8ac4" stroke-width="2" stroke-linecap="round"/>
    <path d="M36 12 V42" stroke="#f3ddb3" stroke-width="2"/>
  </g>`, "A postcard peeking out.");

for (const [name, content] of Object.entries(files)) writeFileSync(join(OUT, name), content);
console.log(`${Object.keys(files).length} prop SVGs written to ${OUT}`);
