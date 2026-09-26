// Generates the five postcard fronts (640x420). The SVG files are the editable source;
// re-running this overwrites them:  node tools/art/postcards.mjs
import { save, svg } from "./room_kit.mjs";

const card = (body, sky) => `  <defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">${sky.map((c, i) => `<stop offset="${(i / (sky.length - 1)).toFixed(2)}" stop-color="${c}"/>`).join("")}</linearGradient></defs>
  <rect x="6" y="8" width="634" height="412" rx="14" fill="#3b2e3a" opacity="0.18"/>
  <rect x="0" y="0" width="634" height="412" rx="14" fill="#fffbf5"/>
  <rect x="20" y="20" width="594" height="372" rx="6" fill="url(#sky)"/>
${body}`;

// ---------------------------------------------------------------- Lisbon: tram, roofs, river, sunrise
save("postcards/lisbon.svg", svg(640, 420, card(`  <circle cx="470" cy="220" r="56" fill="#f6c453"/>
  <rect x="20" y="220" width="594" height="60" fill="#6cc2be"/><rect x="20" y="236" width="594" height="6" fill="#fbe3a0" opacity="0.7"/>
  <path d="M20 280 L90 240 L140 262 L210 226 L270 254 L330 230 L400 260 L470 236 L540 258 L614 240 V392 H20 Z" fill="#e08e6d"/>
  ${[40, 110, 190, 270, 350, 430, 510].map((x, i) => `<rect x="${x}" y="${270 + (i % 2) * 12}" width="60" height="${120 - (i % 2) * 12}" fill="${["#fff4e2", "#fcd9b8", "#f3ddb3"][i % 3]}"/><path d="M${x - 4} ${270 + (i % 2) * 12} L${x + 30} ${250 + (i % 2) * 12} L${x + 64} ${270 + (i % 2) * 12} Z" fill="#c8674a"/><rect x="${x + 12}" y="${300 + (i % 2) * 12}" width="12" height="16" fill="#2e8c8c"/><rect x="${x + 36}" y="${300 + (i % 2) * 12}" width="12" height="16" fill="#2e8c8c"/>`).join("")}
  <rect x="150" y="300" width="200" height="72" rx="14" fill="#f6c453"/>
  <rect x="150" y="300" width="200" height="16" rx="8" fill="#fbe3a0"/>
  ${[166, 206, 246, 286].map(x => `<rect x="${x}" y="322" width="30" height="24" rx="4" fill="#fff4e2"/>`).join("")}
  <rect x="150" y="354" width="200" height="8" fill="#c8674a"/>
  <path d="M250 300 L250 270 L290 250" stroke="#3b2e3a" stroke-width="3" fill="none"/>
  <circle cx="180" cy="374" r="10" fill="#3b2e3a"/><circle cx="320" cy="374" r="10" fill="#3b2e3a"/>
  <path d="M20 382 H614" stroke="#6b5a66" stroke-width="4"/>`, ["#9c8ac4", "#f9b98a", "#fbe3a0"]), "Postcard: Lisbon sunrise with a yellow tram."));

// ---------------------------------------------------------------- Kyoto: pagoda, torii, blossoms
save("postcards/kyoto.svg", svg(640, 420, card(`  <circle cx="200" cy="200" r="60" fill="#fbe3a0" opacity="0.9"/>
  <path d="M20 300 C120 260 220 280 320 250 S520 270 614 240 V392 H20 Z" fill="#8faf8a"/>
  <path d="M20 330 C160 300 300 320 420 300 S560 310 614 296 V392 H20 Z" fill="#5e7f5e"/>
  <g fill="#3e3570">
    <rect x="428" y="130" width="12" height="190"/>
    ${[140, 180, 220, 260].map((y, i) => `<path d="M${384 + i * 6} ${y} H${484 - i * 6} L${470 - i * 6} ${y - 18} H${398 + i * 6} Z"/>`).join("")}
    <path d="M430 100 L434 130 L438 100 Z"/>
  </g>
  <g fill="#c95b52"><rect x="90" y="250" width="16" height="130"/><rect x="200" y="250" width="16" height="130"/><rect x="72" y="244" width="162" height="16" rx="4"/><rect x="84" y="270" width="138" height="10"/></g>
  ${[[70, 90], [110, 70], [150, 96], [560, 80], [590, 120], [530, 110], [300, 60]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="16" fill="#fcd9b8"/><circle cx="${x + 12}" cy="${y + 6}" r="12" fill="#f9b98a"/>`).join("")}
  ${[[250, 170], [320, 220], [380, 150], [140, 190]].map(([x, y]) => `<ellipse cx="${x}" cy="${y}" rx="5" ry="3" fill="#fcd9b8" transform="rotate(30 ${x} ${y})"/>`).join("")}`, ["#c9bde3", "#fcd9b8", "#fbe3a0"]), "Postcard: Kyoto pagoda and torii gate with blossoms."));

// ---------------------------------------------------------------- Santorini: white houses, blue domes
save("postcards/santorini.svg", svg(640, 420, card(`  <circle cx="160" cy="210" r="50" fill="#f6c453"/>
  <rect x="20" y="210" width="594" height="182" fill="#2e8c8c"/><rect x="60" y="226" width="140" height="6" rx="3" fill="#fbe3a0" opacity="0.8"/>
  <path d="M280 392 V250 C340 230 420 220 520 230 C570 236 600 250 614 260 V392 Z" fill="#e3c393"/>
  ${[[300, 250, 90, 70], [390, 238, 80, 80], [470, 250, 90, 70], [330, 310, 110, 70], [450, 316, 100, 64], [540, 290, 74, 90]].map(([x, y, w, h]) => `<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="#fffbf5"/><rect x="${x + 16}" y="${y + h - 30}" width="16" height="26" fill="#2e8c8c"/>`).join("")}
  <path d="M390 238 C390 200 470 200 470 238 Z" fill="#1f5f6b"/><path d="M530 290 C530 262 600 262 600 290 Z" fill="#1f5f6b"/>
  <rect x="428" y="186" width="4" height="18" fill="#f6c453"/><rect x="422" y="192" width="16" height="4" fill="#f6c453"/>
  <g transform="translate(250 330)"><ellipse cx="30" cy="20" rx="26" ry="14" fill="#9c8ac4"/><rect x="10" y="28" width="6" height="22" fill="#9c8ac4"/><rect x="42" y="28" width="6" height="22" fill="#9c8ac4"/><path d="M50 14 L68 0 L70 16 Z" fill="#9c8ac4"/><path d="M60 0 L58 -12 L64 -2 Z" fill="#9c8ac4"/></g>`, ["#6cc2be", "#fcd9b8", "#f9b98a"]), "Postcard: Santorini's white houses and blue domes, with a donkey."));

// ---------------------------------------------------------------- Marrakech: rooftop, arches, lanterns
save("postcards/marrakech.svg", svg(640, 420, card(`  <circle cx="320" cy="170" r="70" fill="#fbe3a0"/>
  <path d="M20 250 H614 V392 H20 Z" fill="#c8674a"/>
  <path d="M60 250 V160 H140 V250 Z M180 250 V120 H220 V250 Z" fill="#a9533b"/>
  <rect x="190" y="100" width="20" height="24" fill="#a9533b"/><circle cx="200" cy="96" r="8" fill="#f6c453"/>
  ${[60, 180, 300, 420, 540].map(x => `<path d="M${x} 392 V320 C${x} 290 ${x + 60} 290 ${x + 60} 320 V392 Z" fill="#7a3a2a"/><path d="M${x + 6} 392 V322 C${x + 6} 298 ${x + 54} 298 ${x + 54} 322 V392 Z" fill="#2e8c8c" opacity="0.5"/>`).join("")}
  <rect x="20" y="250" width="594" height="16" fill="#e08e6d"/>
  ${[[100, 40], [250, 60], [400, 40], [540, 60]].map(([x, y]) => `<path d="M${x} 20 V${y}" stroke="#7a5134" stroke-width="2"/><path d="M${x - 14} ${y} H${x + 14} L${x + 8} ${y + 34} H${x - 8} Z" fill="#f6c453"/><rect x="${x - 10}" y="${y + 8}" width="20" height="6" fill="#ee7b6b"/>`).join("")}
  <path d="M520 250 C530 190 510 150 540 120 M540 120 C510 110 490 120 480 130 M540 120 C560 100 580 104 596 116 M540 120 C540 96 550 84 566 80" stroke="#5e7f5e" stroke-width="6" fill="none" stroke-linecap="round"/>`, ["#ee7b6b", "#f9b98a", "#fbe3a0"]), "Postcard: a Marrakech rooftop at dawn with lanterns and arches."));

// ---------------------------------------------------------------- Reykjavik: colourful houses, mountains, low sun
save("postcards/reykjavik.svg", svg(640, 420, card(`  <circle cx="480" cy="250" r="40" fill="#f9b98a"/>
  <path d="M20 260 L120 150 L200 230 L300 120 L420 250 L500 190 L614 260 Z" fill="#9c8ac4"/>
  <path d="M100 172 L120 150 L140 172 L130 176 L120 166 L110 176 Z M280 142 L300 120 L320 142 L310 148 L300 136 L290 148 Z" fill="#fffbf5"/>
  <rect x="20" y="260" width="594" height="60" fill="#6cc2be"/><rect x="380" y="274" width="200" height="6" rx="3" fill="#fbe3a0" opacity="0.7"/>
  ${[["#ee7b6b", 40], ["#f6c453", 120], ["#2e8c8c", 200], ["#fffbf5", 280], ["#9c8ac4", 360], ["#ee7b6b", 440], ["#8faf8a", 520]].map(([c, x]) => `<rect x="${x}" y="310" width="70" height="82" fill="${c}"/><path d="M${x - 4} 312 L${x + 35} 282 L${x + 74} 312 Z" fill="#3b2e3a"/><rect x="${x + 14}" y="330" width="14" height="16" fill="#fbe3a0"/><rect x="${x + 42}" y="330" width="14" height="16" fill="#fbe3a0"/>`).join("")}
  <path d="M20 392 H614" stroke="#3b2e3a" stroke-width="4"/>`, ["#c9bde3", "#fcd9b8", "#f9b98a"]), "Postcard: Reykjavik's colourful houses under the midnight sun."));

console.log("postcards written");
