// Generates item, symbol, UI icon and puzzle SVGs. The SVG files are the real, editable art; this script is
// just how they were first drawn. Re-running it overwrites them:  node tools/art/items_ui.mjs
import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const SPRITES = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "assets", "sprites");
const svg = (w, h, body, note) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${w} ${h}" width="${w}" height="${h}">\n  <!-- ${note} -->\n${body}\n</svg>\n`;
const out = {};
const item = (name, body, note) => (out[`items/${name}.svg`] = svg(128, 128, body, note));

// ---------------------------------------------------------------- items (128x128)
const rays = (cx, cy, r1, r2, n, color, width) => Array.from({ length: n }, (_, i) => {
  const a = (i / n) * Math.PI * 2;
  return `<line x1="${(cx + Math.cos(a) * r1).toFixed(1)}" y1="${(cy + Math.sin(a) * r1).toFixed(1)}" x2="${(cx + Math.cos(a) * r2).toFixed(1)}" y2="${(cy + Math.sin(a) * r2).toFixed(1)}" stroke="${color}" stroke-width="${width}" stroke-linecap="round"/>`;
}).join("");
const keyShaft = (x1, x2, y, fill, shade) => `  <rect x="${x1}" y="${y - 6}" width="${x2 - x1}" height="12" rx="6" fill="${fill}"/>
  <rect x="${x1}" y="${y - 6}" width="${x2 - x1}" height="4" rx="2" fill="#fffbf5" opacity="0.4"/>
  <rect x="${x2 - 26}" y="${y + 4}" width="9" height="16" rx="2" fill="${shade}"/>
  <rect x="${x2 - 12}" y="${y + 4}" width="9" height="22" rx="2" fill="${shade}"/>`;
item("brass_key", `  <g transform="rotate(-20 64 64)">
${keyShaft(50, 116, 64, "#d4a24c", "#a87a2e")}
  ${rays(34, 64, 18, 28, 10, "#d4a24c", 6)}
  <circle cx="34" cy="64" r="19" fill="#d4a24c"/>
  <circle cx="34" cy="64" r="8" fill="#fff4e2"/>
  <circle cx="28" cy="57" r="4" fill="#fbe3a0"/>
  </g>`, "Brass key with a sun-shaped bow.");
item("tiny_key", `  <g transform="rotate(-25 64 64)">
  <rect x="52" y="60" width="44" height="8" rx="4" fill="#b9b2c9"/>
  <rect x="82" y="66" width="6" height="10" rx="2" fill="#8f86a3"/><rect x="90" y="66" width="6" height="14" rx="2" fill="#8f86a3"/>
  <circle cx="42" cy="64" r="14" fill="#b9b2c9"/><circle cx="42" cy="64" r="6" fill="#fff4e2"/>
  <circle cx="37" cy="58" r="3" fill="#fffbf5" opacity="0.8"/>
  </g>`, "Tiny silver key.");
item("shell_key", `  <g transform="rotate(-20 64 64)">
${keyShaft(56, 114, 64, "#c99a6b", "#a8744a")}
  <circle cx="50" cy="64" r="10" fill="#c99a6b"/><circle cx="50" cy="64" r="4" fill="#fff4e2"/>
  <path d="M30 86 C14 80 12 60 26 50 C34 56 36 70 30 86 Z" fill="#ee7b6b"/>
  <path d="M30 86 C24 76 22 64 26 54 M30 86 C28 76 30 66 32 58 M30 86 C20 78 16 70 18 62" stroke="#c95b52" stroke-width="2" fill="none"/>
  <line x1="40" y1="64" x2="32" y2="56" stroke="#a8744a" stroke-width="3"/>
  </g>`, "Key with a seashell charm.");
item("old_key", `  <g transform="rotate(-20 64 64)">
  <rect x="44" y="59" width="72" height="10" rx="5" fill="#6b5a66"/>
  <rect x="96" y="67" width="8" height="16" rx="2" fill="#4d3d4b"/><rect x="106" y="67" width="8" height="22" rx="2" fill="#4d3d4b"/>
  <circle cx="30" cy="54" r="10" fill="none" stroke="#6b5a66" stroke-width="7"/>
  <circle cx="30" cy="74" r="10" fill="none" stroke="#6b5a66" stroke-width="7"/>
  <circle cx="18" cy="64" r="10" fill="none" stroke="#6b5a66" stroke-width="7"/>
  <rect x="36" y="58" width="10" height="12" rx="3" fill="#6b5a66"/>
  </g>`, "Old iron key, mended.");
item("key_bow", `  <g transform="rotate(-20 64 64)">
  <circle cx="44" cy="54" r="10" fill="none" stroke="#6b5a66" stroke-width="7"/>
  <circle cx="44" cy="74" r="10" fill="none" stroke="#6b5a66" stroke-width="7"/>
  <circle cx="32" cy="64" r="10" fill="none" stroke="#6b5a66" stroke-width="7"/>
  <path d="M50 59 L78 59 L74 64 L80 69 L50 69 Z" fill="#6b5a66"/>
  </g>`, "The ring end of a broken key.");
item("key_blade", `  <g transform="rotate(-20 64 64)">
  <path d="M30 59 L100 59 L100 69 L30 69 L34 64 Z" fill="#6b5a66"/>
  <rect x="80" y="67" width="8" height="16" rx="2" fill="#4d3d4b"/><rect x="90" y="67" width="8" height="22" rx="2" fill="#4d3d4b"/>
  </g>`, "The toothy end of a broken key.");
const torch = (lit) => `  <g transform="rotate(-30 64 64)">
  ${lit ? '<path d="M96 52 L128 30 L128 98 L96 76 Z" fill="#fbe3a0" opacity="0.75"/>' : ""}
  <rect x="24" y="54" width="54" height="20" rx="8" fill="#2e8c8c"/>
  <rect x="24" y="54" width="54" height="6" rx="3" fill="#6cc2be"/>
  <path d="M76 50 L96 44 L96 84 L76 78 Z" fill="#1f5f6b"/>
  <rect x="94" y="44" width="6" height="40" rx="2" fill="${lit ? "#fffbf5" : "#6b5a66"}"/>
  <rect x="18" y="56" width="8" height="16" rx="3" fill="#1f5f6b"/>
  <rect x="44" y="50" width="12" height="6" rx="2" fill="#ee7b6b"/>
  </g>`;
item("flashlight_empty", torch(false), "Flashlight without batteries.");
item("flashlight", torch(true), "Working flashlight.");
item("batteries", `  <g transform="rotate(-12 64 64)">
  <rect x="30" y="30" width="28" height="64" rx="6" fill="#3b2e3a"/><rect x="30" y="30" width="28" height="20" rx="6" fill="#f6c453"/><rect x="38" y="24" width="12" height="8" rx="2" fill="#a87a2e"/>
  <rect x="66" y="36" width="28" height="64" rx="6" fill="#3b2e3a"/><rect x="66" y="36" width="28" height="20" rx="6" fill="#f6c453"/><rect x="74" y="30" width="12" height="8" rx="2" fill="#a87a2e"/>
  <rect x="34" y="56" width="6" height="30" rx="3" fill="#fffbf5" opacity="0.3"/><rect x="70" y="62" width="6" height="30" rx="3" fill="#fffbf5" opacity="0.3"/>
  </g>`, "Two batteries.");
item("trowel", `  <g transform="rotate(35 64 64)">
  <rect x="56" y="14" width="16" height="40" rx="8" fill="#a8744a"/><rect x="58" y="16" width="5" height="34" rx="2" fill="#c99a6b"/>
  <rect x="60" y="52" width="8" height="12" fill="#8f86a3"/>
  <path d="M44 64 L84 64 C84 90 72 108 64 116 C56 108 44 90 44 64 Z" fill="#b9b2c9"/>
  <path d="M50 66 L60 66 C60 86 58 98 56 104 C52 96 50 84 50 66 Z" fill="#fffbf5" opacity="0.45"/>
  </g>`, "Small garden trowel.");
item("screwdriver", `  <g transform="rotate(-40 64 64)">
  <rect x="18" y="52" width="46" height="24" rx="10" fill="#ee7b6b"/>
  <rect x="22" y="56" width="38" height="5" rx="2" fill="#fcd9b8" opacity="0.7"/>
  <rect x="62" y="59" width="46" height="10" rx="3" fill="#b9b2c9"/>
  <rect x="104" y="58" width="10" height="12" rx="2" fill="#8f86a3"/>
  </g>`, "Screwdriver with a coral handle.");
item("string", `  <rect x="34" y="30" width="60" height="70" rx="10" fill="#c9bde3"/>
  <g stroke="#fff4e2" stroke-width="5" stroke-linecap="round">
    <line x1="30" y1="42" x2="98" y2="42"/><line x1="30" y1="52" x2="98" y2="52"/><line x1="30" y1="62" x2="98" y2="62"/><line x1="30" y1="72" x2="98" y2="72"/><line x1="30" y1="82" x2="98" y2="82"/>
  </g>
  <path d="M98 82 C112 88 110 104 96 108" stroke="#fff4e2" stroke-width="5" fill="none" stroke-linecap="round"/>`, "A card with kitchen string wound around it.");
const lemon = `<ellipse cx="0" cy="0" rx="30" ry="22" fill="#f6c453"/><ellipse cx="-8" cy="-6" rx="10" ry="6" fill="#fbe3a0"/><path d="M-30 0 L-38 -2 L-36 4 Z M30 0 L38 -2 L36 4 Z" fill="#f6c453"/><path d="M6 -22 C14 -34 28 -32 30 -24 C22 -22 14 -20 6 -22 Z" fill="#8faf8a"/>`;
item("magnet", `  <g transform="translate(64 68) rotate(-15)">${lemon}</g>`, "Lemon-shaped fridge magnet.");
item("fishing_magnet", `  <path d="M64 6 C60 30 70 50 64 74" stroke="#c9bde3" stroke-width="5" fill="none" stroke-linecap="round"/>
  <circle cx="64" cy="8" r="5" fill="#9c8ac4"/>
  <g transform="translate(64 94) rotate(8) scale(0.85)">${lemon}</g>`, "Lemon magnet tied to a piece of string.");
const photoArt = `<rect x="0" y="0" width="92" height="72" fill="#fffbf5"/><rect x="6" y="6" width="80" height="60" fill="#6cc2be"/><rect x="6" y="6" width="80" height="26" fill="#f9b98a"/><circle cx="46" cy="30" r="10" fill="#f6c453"/><rect x="6" y="40" width="80" height="26" fill="#2e8c8c"/><path d="M20 58 L36 58 L32 64 L24 64 Z" fill="#fff4e2"/>`;
item("torn_photo_left", `  <g transform="translate(20 28) rotate(-6)"><path d="M0 0 H50 L44 12 L52 24 L44 36 L50 48 L44 60 L50 72 H0 Z" fill="#fffbf5"/><rect x="6" y="6" width="38" height="60" fill="#6cc2be"/><rect x="6" y="6" width="38" height="26" fill="#f9b98a"/><rect x="6" y="40" width="38" height="26" fill="#2e8c8c"/><path d="M20 58 L36 58 L32 64 L24 64 Z" fill="#fff4e2"/></g>`, "Left half of a torn photo.");
item("torn_photo_right", `  <g transform="translate(56 30) rotate(5)"><path d="M6 0 H50 V72 H6 L0 60 L6 48 L0 36 L8 24 L0 12 Z" fill="#fffbf5"/><rect x="8" y="6" width="36" height="60" fill="#6cc2be"/><rect x="8" y="6" width="36" height="26" fill="#f9b98a"/><circle cx="8" cy="30" r="10" fill="#f6c453"/><rect x="8" y="40" width="36" height="26" fill="#2e8c8c"/></g>`, "Right half of a torn photo.");
item("photo", `  <g transform="translate(18 26) rotate(-4)">${photoArt}<rect x="36" y="-6" width="20" height="84" fill="#fbe3a0" opacity="0.6"/></g>`, "A photo taped back together.");

// ---------------------------------------------------------------- symbols (64x64): colour AND shape
const sym = (name, body, note) => (out[`ui/symbols/${name}.svg`] = svg(64, 64, body, note));
sym("sun", `  ${rays(32, 32, 16, 27, 8, "#e0a92e", 5)}
  <circle cx="32" cy="32" r="15" fill="#f6c453"/><circle cx="27" cy="27" r="5" fill="#fbe3a0"/>`, "Sun symbol (gold).");
sym("shell", `  <path d="M32 54 C14 50 6 34 12 20 C20 10 44 10 52 20 C58 34 50 50 32 54 Z" fill="#ee7b6b"/>
  <path d="M32 54 L20 16 M32 54 L32 12 M32 54 L44 16 M32 54 L12 26 M32 54 L52 26" stroke="#c95b52" stroke-width="3" stroke-linecap="round"/>
  <rect x="24" y="50" width="16" height="8" rx="3" fill="#c95b52"/>`, "Scallop shell symbol (coral).");
sym("wave", `  <path d="M4 44 C12 44 14 22 30 20 C44 18 52 30 46 38 C42 42 36 38 38 34 C28 32 26 46 36 50 C44 54 56 50 60 44 L60 56 L4 56 Z" fill="#2e8c8c"/>
  <path d="M12 44 C18 36 22 28 30 26" stroke="#6cc2be" stroke-width="3" fill="none" stroke-linecap="round"/>`, "Wave symbol (teal).");
sym("star", `  <path d="M32 6 L39 24 L58 24 L43 36 L49 56 L32 44 L15 56 L21 36 L6 24 L25 24 Z" fill="#9c8ac4"/>
  <path d="M32 14 L36 26 L30 26 Z" fill="#c9bde3"/>`, "Star symbol (lavender).");
sym("leaf", `  <path d="M10 54 C8 28 26 10 54 8 C56 36 38 56 10 54 Z" fill="#8faf8a"/>
  <path d="M12 52 C24 40 36 28 50 12" stroke="#5e7f5e" stroke-width="3" fill="none" stroke-linecap="round"/>
  <path d="M26 38 L22 26 M34 30 L44 30 M22 44 L32 46" stroke="#5e7f5e" stroke-width="2" stroke-linecap="round"/>`, "Leaf symbol (sage).");
sym("heart", `  <path d="M32 56 C8 40 4 26 12 16 C20 8 30 12 32 20 C34 12 44 8 52 16 C60 26 56 40 32 56 Z" fill="#c8674a"/>
  <path d="M16 20 C20 16 24 16 26 20" stroke="#e08e6d" stroke-width="4" fill="none" stroke-linecap="round"/>`, "Heart symbol (terracotta).");

// ---------------------------------------------------------------- UI icons (64x64)
const ui = (name, body, note, w = 64, h = 64) => (out[`ui/${name}.svg`] = svg(w, h, body, note));
ui("hint", `  <rect x="12" y="8" width="40" height="50" rx="6" fill="#fffbf5"/>
  <rect x="12" y="8" width="40" height="10" rx="4" fill="#ee7b6b"/>
  <g fill="#c95b52"><circle cx="20" cy="8" r="3"/><circle cx="32" cy="8" r="3"/><circle cx="44" cy="8" r="3"/></g>
  <path d="M18 28 H44 M18 36 H40 M18 44 H34" stroke="#9c8ac4" stroke-width="3" stroke-linecap="round"/>
  <path d="M40 58 L56 30 L62 34 L46 62 L38 64 Z" fill="#f6c453"/><path d="M38 64 L40 58 L46 62 Z" fill="#3b2e3a"/>`, "Grandma's notepad (hints).");
ui("close", `  <path d="M18 18 L46 46 M46 18 L18 46" stroke="#3b2e3a" stroke-width="7" stroke-linecap="round"/>`, "Close.");
ui("pause", `  <rect x="18" y="14" width="10" height="36" rx="5" fill="#3b2e3a"/><rect x="36" y="14" width="10" height="36" rx="5" fill="#3b2e3a"/>`, "Pause.");
ui("back", `  <path d="M38 14 L20 32 L38 50" stroke="#3b2e3a" stroke-width="7" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`, "Back.");
ui("forward", `  <path d="M26 14 L44 32 L26 50" stroke="#3b2e3a" stroke-width="7" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`, "Forward.");
ui("star_full", `  <path d="M32 4 L40 23 L61 24 L45 37 L51 58 L32 46 L13 58 L19 37 L3 24 L24 23 Z" fill="#f6c453"/>
  <path d="M32 12 L36 24 L28 24 Z" fill="#fbe3a0"/>`, "Earned star.");
ui("star_empty", `  <path d="M32 4 L40 23 L61 24 L45 37 L51 58 L32 46 L13 58 L19 37 L3 24 L24 23 Z" fill="#fffbf5" fill-opacity="0.35" stroke="#c9bde3" stroke-width="3" stroke-linejoin="round"/>`, "Star not earned yet.");
ui("seashell", `  <path d="M32 56 C12 52 4 34 10 20 C18 8 46 8 54 20 C60 34 52 52 32 56 Z" fill="#f9b98a"/>
  <path d="M32 56 L20 14 M32 56 L32 10 M32 56 L44 14 M32 56 L10 24 M32 56 L54 24" stroke="#c8674a" stroke-width="3" stroke-linecap="round"/>
  <rect x="24" y="52" width="16" height="8" rx="3" fill="#c8674a"/>`, "Seashell (currency).");
ui("check", `  <path d="M14 34 L27 47 L50 18" stroke="#5e7f5e" stroke-width="8" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`, "Check mark.");
ui("arrow_up", `  <path d="M14 40 L32 22 L50 40" stroke="#3b2e3a" stroke-width="8" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`, "Up.");
ui("arrow_down", `  <path d="M14 24 L32 42 L50 24" stroke="#3b2e3a" stroke-width="8" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`, "Down.");
ui("unlocked", `  <circle cx="32" cy="32" r="26" fill="#fffbf5" opacity="0.9"/>
  <path d="M22 28 V20 C22 10 40 10 42 18" stroke="#a87a2e" stroke-width="5" fill="none" stroke-linecap="round"/>
  <rect x="16" y="28" width="32" height="24" rx="6" fill="#d4a24c"/>
  <circle cx="32" cy="38" r="4" fill="#7a5134"/><rect x="30" y="40" width="4" height="7" rx="2" fill="#7a5134"/>`, "Small badge showing something was unlocked.");
ui("padlock", `  <circle cx="32" cy="32" r="27" fill="#fffbf5" opacity="0.85"/>
  <path d="M22 30 V22 C22 12 42 12 42 22 V30" stroke="#a87a2e" stroke-width="5" fill="none" stroke-linecap="round"/>
  <rect x="16" y="28" width="32" height="24" rx="6" fill="#d4a24c"/>
  <rect x="16" y="28" width="32" height="6" rx="3" fill="#fbe3a0" opacity="0.7"/>
  <circle cx="32" cy="38" r="4" fill="#7a5134"/><rect x="30" y="40" width="4" height="7" rx="2" fill="#7a5134"/>`, "Small brass padlock badge: this is locked.");
ui("sparkle", `  <path d="M32 4 C34 22 42 30 60 32 C42 34 34 42 32 60 C30 42 22 34 4 32 C22 30 30 22 32 4 Z" fill="#f6c453"/>
  <path d="M32 16 C33 26 38 31 48 32 C38 33 33 38 32 48 C31 38 26 33 16 32 C26 31 31 26 32 16 Z" fill="#fffbf5" opacity="0.7"/>`, "Sparkle.");
ui("gear", `  <g transform="translate(32 32)">${Array.from({ length: 8 }, (_, i) => `<rect x="-5" y="-28" width="10" height="14" rx="3" fill="#6b5a66" transform="rotate(${i * 45})"/>`).join("")}
  <circle r="18" fill="#6b5a66"/><circle r="8" fill="#fffbf5"/></g>`, "Settings.");
ui("home", `  <path d="M8 32 L32 10 L56 32" stroke="#3b2e3a" stroke-width="6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M16 30 V54 H48 V30" fill="#fffbf5" stroke="#3b2e3a" stroke-width="5" stroke-linejoin="round"/>
  <rect x="27" y="38" width="10" height="16" rx="2" fill="#ee7b6b"/>`, "Home / penthouse.");

// ---------------------------------------------------------------- puzzle art
out["puzzles/slider_sunrise.svg"] = svg(600, 600, `  <defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3e3570"/><stop offset="0.5" stop-color="#9c8ac4"/><stop offset="1" stop-color="#f9b98a"/></linearGradient></defs>
  <rect width="600" height="600" fill="url(#sky)"/>
  <circle cx="300" cy="360" r="120" fill="#f6c453" opacity="0.25"/>
  <circle cx="300" cy="360" r="86" fill="#f6c453"/>
  <circle cx="276" cy="336" r="26" fill="#fbe3a0"/>
  <g fill="#fffbf5" opacity="0.9"><circle cx="70" cy="70" r="4"/><circle cx="160" cy="40" r="3"/><circle cx="520" cy="60" r="4"/><circle cx="450" cy="120" r="3"/><circle cx="90" cy="170" r="3"/></g>
  <path d="M90 140 C120 118 170 120 190 140 C210 128 250 132 262 150 H80 C80 146 84 142 90 140 Z" fill="#fcd9b8"/>
  <path d="M380 200 C400 186 440 186 454 200 C470 194 494 198 500 210 H372 C372 206 376 202 380 200 Z" fill="#fcd9b8" opacity="0.8"/>
  <path d="M170 250 C176 242 184 242 188 250 C192 242 200 242 206 250" stroke="#3b2e3a" stroke-width="5" fill="none"/>
  <path d="M400 290 C404 284 410 284 414 290 C418 284 424 284 428 290" stroke="#3b2e3a" stroke-width="4" fill="none"/>
  <rect y="400" width="600" height="200" fill="#2e8c8c"/>
  <rect y="400" width="600" height="14" fill="#6cc2be"/>
  <rect x="220" y="430" width="160" height="10" rx="5" fill="#fbe3a0"/><rect x="250" y="462" width="100" height="8" rx="4" fill="#fbe3a0" opacity="0.8"/><rect x="274" y="492" width="52" height="6" rx="3" fill="#fbe3a0" opacity="0.6"/>
  <path d="M80 470 L180 470 L166 500 L94 500 Z" fill="#fff4e2"/><path d="M128 466 L128 350 L184 462 Z" fill="#fffbf5"/><path d="M124 470 L124 380 L84 462 Z" fill="#ee7b6b"/>
  <path d="M470 600 C476 520 486 460 500 410 L512 412 C500 462 492 522 490 600 Z" fill="#1f5f6b"/>
  <path d="M506 412 C470 390 432 396 410 420 C444 404 478 410 500 424 Z M506 412 C530 380 566 376 596 392 C562 392 534 404 512 426 Z M506 412 C500 380 510 350 532 334 C520 362 516 390 512 420 Z M506 412 C540 414 570 432 584 456 C560 438 532 430 508 428 Z" fill="#1f5f6b"/>
  <rect y="560" width="600" height="40" fill="#1f5f6b" opacity="0.6"/>`, "Sunrise picture used by the sliding-tile puzzle.");
out["puzzles/clock_face.svg"] = svg(420, 420, `  <circle cx="210" cy="214" r="200" fill="#3b2e3a" opacity="0.18"/>
  <circle cx="210" cy="210" r="200" fill="#a8744a"/>
  <circle cx="210" cy="210" r="184" fill="#c99a6b"/>
  <circle cx="210" cy="210" r="168" fill="#fff4e2"/>
  <circle cx="210" cy="210" r="150" fill="none" stroke="#f3ddb3" stroke-width="4"/>
  ${Array.from({ length: 60 }, (_, i) => {
    const a = (i / 60) * Math.PI * 2; const big = i % 5 === 0; const r1 = big ? 128 : 144; const r2 = 158;
    return `<line x1="${(210 + Math.sin(a) * r1).toFixed(1)}" y1="${(210 - Math.cos(a) * r1).toFixed(1)}" x2="${(210 + Math.sin(a) * r2).toFixed(1)}" y2="${(210 - Math.cos(a) * r2).toFixed(1)}" stroke="${big ? "#6b5a66" : "#c9bde3"}" stroke-width="${big ? (i % 15 === 0 ? 10 : 6) : 3}" stroke-linecap="round"/>`;
  }).join("\n  ")}
  <circle cx="210" cy="96" r="10" fill="#f6c453"/>
  <path d="M190 300 C200 290 220 290 230 300" stroke="#9c8ac4" stroke-width="4" fill="none" stroke-linecap="round"/>`, "Clock face for the clock lock (hands are drawn by the game).");
out["puzzles/keyhole.svg"] = svg(240, 300, `  <rect x="10" y="14" width="224" height="282" rx="40" fill="#3b2e3a" opacity="0.2"/>
  <rect x="4" y="4" width="224" height="282" rx="40" fill="#d4a24c"/>
  <rect x="18" y="18" width="196" height="254" rx="30" fill="#e8bd62"/>
  <rect x="18" y="18" width="196" height="30" rx="15" fill="#fbe3a0" opacity="0.5"/>
  <circle cx="116" cy="118" r="34" fill="#3b2e3a"/>
  <path d="M100 136 L132 136 L140 210 L92 210 Z" fill="#3b2e3a"/>
  <circle cx="40" cy="40" r="7" fill="#a87a2e"/><circle cx="192" cy="40" r="7" fill="#a87a2e"/><circle cx="40" cy="250" r="7" fill="#a87a2e"/><circle cx="192" cy="250" r="7" fill="#a87a2e"/>`, "Brass keyhole plate.");

for (const [path, content] of Object.entries(out)) {
  const full = join(SPRITES, path);
  mkdirSync(dirname(full), { recursive: true });
  writeFileSync(full, content);
}
console.log(`${Object.keys(out).length} SVGs written`);
