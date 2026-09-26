// Draws Chloé, Céline's white Maltese, in her poses, and her things (Gaston the squeaky seagull,
// kibble, leash, water jug, brush) plus the scent items she can follow.
// The SVG files are the real, editable art; re-running overwrites them:  node tools/art/chloe.mjs
import { save, svg } from "./room_kit.mjs";

const FUR = "#fffbf5";
const FUR_SHADE = "#e6dfee";
const FUR_DEEP = "#cfc6dd";
const INK = "#3b2e3a";
const PINK = "#ee9b9b";
const BOW = "#ee7b6b";
const shadow = (cx, cy, rx, ry, o = 0.18) => `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="${INK}" opacity="${o}"/>`;

// A fluffy blob: an ellipse whose edge is a row of soft scallops (curls of fur).
const fluff = (cx, cy, rx, ry, bumps, fill, jitter = 0.08) => {
  const pt = (a, k) => [cx + Math.cos(a) * rx * k, cy + Math.sin(a) * ry * k];
  let d = "";
  for (let i = 0; i < bumps; i++) {
    const a0 = (i / bumps) * Math.PI * 2, a1 = ((i + 1) / bumps) * Math.PI * 2;
    const [x0, y0] = pt(a0, 1 - jitter);
    const [qx, qy] = pt((a0 + a1) / 2, 1 + jitter * 1.6);
    const [x1, y1] = pt(a1, 1 - jitter);
    if (i === 0) d += `M${x0.toFixed(1)} ${y0.toFixed(1)} `;
    d += `Q${qx.toFixed(1)} ${qy.toFixed(1)} ${x1.toFixed(1)} ${y1.toFixed(1)} `;
  }
  return `<path d="${d}Z" fill="${fill}"/>`;
};

// Head seen from the front: ears, fringe, eyes, nose, tongue, the coral bow.
const headFront = (cx, cy, s = 1, eyes = "open") => {
  const e = eyes === "open"
    ? `<circle cx="${cx - 15 * s}" cy="${cy + 2 * s}" r="${6 * s}" fill="${INK}"/><circle cx="${cx + 15 * s}" cy="${cy + 2 * s}" r="${6 * s}" fill="${INK}"/><circle cx="${cx - 13 * s}" cy="${cy}" r="${2 * s}" fill="#ffffff"/><circle cx="${cx + 17 * s}" cy="${cy}" r="${2 * s}" fill="#ffffff"/>`
    : `<path d="M${cx - 21 * s} ${cy + 3 * s} Q${cx - 15 * s} ${cy + 8 * s} ${cx - 9 * s} ${cy + 3 * s} M${cx + 9 * s} ${cy + 3 * s} Q${cx + 15 * s} ${cy + 8 * s} ${cx + 21 * s} ${cy + 3 * s}" stroke="${INK}" stroke-width="${2.5 * s}" fill="none" stroke-linecap="round"/>`;
  return `${fluff(cx - 30 * s, cy + 14 * s, 14 * s, 30 * s, 14, FUR_SHADE, 0.12)}${fluff(cx + 30 * s, cy + 14 * s, 14 * s, 30 * s, 14, FUR_SHADE, 0.12)}
  ${fluff(cx, cy, 34 * s, 32 * s, 18, FUR, 0.06)}
  <path d="M${cx - 28 * s} ${cy - 10 * s} Q${cx - 14 * s} ${cy - 26 * s} ${cx} ${cy - 14 * s} Q${cx + 14 * s} ${cy - 26 * s} ${cx + 28 * s} ${cy - 10 * s} Q${cx} ${cy - 40 * s} ${cx - 28 * s} ${cy - 10 * s} Z" fill="${FUR}"/>
  ${e}
  <ellipse cx="${cx}" cy="${cy + 16 * s}" rx="${7 * s}" ry="${5 * s}" fill="${INK}"/>
  <path d="M${cx} ${cy + 21 * s} L${cx} ${cy + 25 * s}" stroke="${INK}" stroke-width="${2 * s}"/>
  <path d="M${cx - 5 * s} ${cy + 27 * s} Q${cx} ${cy + 40 * s} ${cx + 5 * s} ${cy + 27 * s} Z" fill="${PINK}"/>
  <path d="M${cx + 12 * s} ${cy - 30 * s} l${-12 * s} ${-8 * s} l0 ${16 * s} Z M${cx + 12 * s} ${cy - 30 * s} l${12 * s} ${-8 * s} l0 ${16 * s} Z" fill="${BOW}"/><circle cx="${cx + 12 * s}" cy="${cy - 30 * s}" r="${4 * s}" fill="#c95b52"/>`;
};

// Sitting, facing the player.
save("props/chloe/chloe_sit.svg", svg(160, 170, `  ${shadow(80, 162, 56, 8)}
  ${fluff(80, 118, 46, 40, 20, FUR_SHADE, 0.07)}
  ${fluff(80, 112, 40, 36, 20, FUR, 0.07)}
  ${fluff(58, 150, 14, 12, 10, FUR, 0.1)}${fluff(102, 150, 14, 12, 10, FUR, 0.1)}
  ${fluff(126, 128, 16, 12, 10, FUR_SHADE, 0.12)}
  ${headFront(80, 64, 1)}`, "Chloé the white Maltese, sitting and looking at you."));

// Side view helpers: body, legs, tail, head.
const sideBody = (dx = 0) => `${fluff(88 + dx, 96, 52, 30, 22, FUR_SHADE, 0.07)}${fluff(86 + dx, 92, 48, 26, 22, FUR, 0.07)}`;
const legs = (lift = 0) => [[52, lift], [70, 0], [108, 0], [124, lift]].map(([x, l]) => `${fluff(x, 124 - l, 10, 16, 10, FUR, 0.1)}`).join("");
const tail = `${fluff(138, 62, 16, 12, 10, FUR_SHADE, 0.14)}${fluff(132, 58, 12, 10, 10, FUR, 0.14)}`;
const headSide = (cx, cy, down = false) => {
  const noseX = cx - 30, noseY = cy + (down ? 28 : 8);
  return `${fluff(cx, cy, 30, 28, 16, FUR, 0.07)}
  ${fluff(cx + 10, cy + 16, 12, 26, 12, FUR_SHADE, 0.12)}
  ${fluff(noseX + 12, noseY - 2, 16, 12, 10, FUR, 0.08)}
  <ellipse cx="${noseX}" cy="${noseY}" rx="6" ry="5" fill="${INK}"/>
  <circle cx="${cx - 10}" cy="${cy - 4 + (down ? 8 : 0)}" r="5" fill="${INK}"/><circle cx="${cx - 8}" cy="${cy - 6 + (down ? 8 : 0)}" r="1.7" fill="#ffffff"/>
  <path d="M${cx + 2} ${cy - 22} l-10 -8 l0 14 Z M${cx + 2} ${cy - 22} l10 -8 l0 14 Z" fill="${BOW}"/>`;
};

save("props/chloe/chloe_walk.svg", svg(170, 150, `  ${shadow(88, 142, 64, 7)}
  ${legs(6)}${sideBody()}${tail}
  ${headSide(40, 62)}
  <path d="M18 76 Q14 86 20 90" stroke="${PINK}" stroke-width="5" fill="none" stroke-linecap="round"/>`, "Chloé trotting, seen from the side, tail curled up."));

save("props/chloe/chloe_sniff.svg", svg(170, 150, `  ${shadow(88, 142, 64, 7)}
  ${legs(0)}${sideBody(4)}${tail}
  ${headSide(36, 84, true)}
  <path d="M-2 106 q4 -6 8 0 M-10 96 q4 -6 8 0" stroke="${FUR_DEEP}" stroke-width="3" fill="none" stroke-linecap="round"/>`, "Chloé with her nose down, sniffing."));

save("props/chloe/chloe_dig.svg", svg(190, 160, `  ${shadow(96, 150, 70, 8)}
  <ellipse cx="34" cy="138" rx="30" ry="10" fill="#6b4a36"/>
  ${[[10, 96], [26, 84], [48, 92], [4, 118]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="5" fill="#8a6446"/>`).join("")}
  ${fluff(112, 90, 50, 30, 22, FUR_SHADE, 0.07)}${fluff(110, 86, 46, 26, 22, FUR, 0.07)}
  ${fluff(150, 120, 11, 18, 10, FUR, 0.1)}${fluff(132, 122, 11, 18, 10, FUR, 0.1)}
  ${fluff(60, 128, 12, 14, 10, FUR, 0.1)}${fluff(78, 116, 12, 14, 10, FUR, 0.1)}
  ${fluff(160, 56, 16, 12, 10, FUR, 0.14)}
  ${headSide(56, 96, true)}`, "Chloé digging, bottom up, soil flying."));

save("props/chloe/chloe_sleep.svg", svg(170, 110, `  ${shadow(85, 100, 70, 8)}
  ${fluff(85, 70, 66, 34, 24, FUR_SHADE, 0.06)}${fluff(85, 66, 62, 30, 24, FUR, 0.06)}
  ${fluff(40, 60, 26, 22, 14, FUR, 0.08)}
  <path d="M28 60 Q34 64 40 60" stroke="${INK}" stroke-width="2.5" fill="none" stroke-linecap="round"/>
  <ellipse cx="22" cy="68" rx="5" ry="4" fill="${INK}"/>
  ${fluff(120, 50, 16, 12, 10, FUR_SHADE, 0.12)}
  <path d="M46 42 l-9 -6 l0 12 Z M46 42 l9 -6 l0 12 Z" fill="${BOW}"/>
  <path d="M120 30 q6 -8 12 0 M132 20 q5 -6 10 0" stroke="${FUR_DEEP}" stroke-width="3" fill="none" stroke-linecap="round"/>`, "Chloé asleep, curled up in a white ball."));

// Two eyes and a nose in the dark: Chloé hiding under the stairs.
save("props/chloe/chloe_peek.svg", svg(120, 90, `  <ellipse cx="60" cy="60" rx="54" ry="30" fill="${INK}" opacity="0.5"/>
  ${fluff(60, 56, 34, 26, 16, FUR_SHADE, 0.08)}
  <path d="M34 46 Q46 36 60 42 Q74 36 86 46 Q60 30 34 46 Z" fill="${FUR}"/>
  <circle cx="46" cy="56" r="7" fill="${INK}"/><circle cx="74" cy="56" r="7" fill="${INK}"/>
  <circle cx="48" cy="54" r="2.4" fill="#ffffff"/><circle cx="76" cy="54" r="2.4" fill="#ffffff"/>
  <ellipse cx="60" cy="70" rx="7" ry="5" fill="${INK}"/>`, "Chloé peeking out of a dark hiding place."));

// Portrait for the close-up.
save("props/chloe/chloe_portrait.svg", svg(240, 240, `  <circle cx="120" cy="120" r="112" fill="#fcd9b8"/>
  ${headFront(120, 116, 2.4)}`, "Chloé's face, for close-ups."));

// ---------------------------------------------------------------- her things (inventory items, 128x128)
const item = (name, body, note) => save(`items/${name}.svg`, svg(128, 128, body, note));
item("gaston", `  ${shadow(64, 116, 40, 6)}
  <path d="M24 70 C24 44 54 36 76 46 C96 54 104 74 96 92 C86 110 44 110 30 96 C24 88 22 80 24 70 Z" fill="#fffbf5"/>
  <path d="M60 60 C74 40 100 44 108 56 C94 56 80 62 70 72 Z" fill="#c9d0d6"/>
  <circle cx="40" cy="58" r="16" fill="#fffbf5"/><circle cx="36" cy="54" r="4" fill="${INK}"/>
  <path d="M22 60 L6 64 L22 68 Z" fill="#f6c453"/><path d="M8 64 L22 64" stroke="#e3ad3a" stroke-width="2"/>
  <path d="M50 108 L46 120 M62 110 L62 122" stroke="#f6c453" stroke-width="5" stroke-linecap="round"/>
  <path d="M40 84 q10 8 20 0 M52 92 q8 6 16 0" stroke="#c9d0d6" stroke-width="3" fill="none"/>`, "Gaston, Chloé's very chewed squeaky toy seagull.");
item("kibble", `  ${shadow(64, 118, 40, 6)}
  <path d="M26 30 L102 30 L108 114 L20 114 Z" fill="#e08e6d"/>
  <path d="M26 30 L102 30 L96 18 L32 18 Z" fill="#c8674a"/>
  <circle cx="64" cy="70" r="22" fill="#fffbf5"/>
  <path d="M52 66 q12 -14 24 0 q-12 18 -24 0 Z" fill="#c8674a"/>
  ${[[40, 100], [52, 104], [80, 102], [92, 98]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="5" fill="#a8744a"/>`).join("")}`, "A bag of Chloé's kibble.");
item("leash", `  <path d="M30 30 C10 60 30 100 70 100 C110 100 112 60 90 40" stroke="${BOW}" stroke-width="9" fill="none" stroke-linecap="round"/>
  <circle cx="30" cy="30" r="14" fill="none" stroke="#c95b52" stroke-width="8"/>
  <rect x="82" y="30" width="18" height="20" rx="4" fill="#d4a24c"/>`, "Chloé's coral leash.");
item("water_jug", `  ${shadow(64, 118, 36, 6)}
  <path d="M40 20 L88 20 L96 110 L32 110 Z" fill="#cfeeea" opacity="0.8"/>
  <path d="M42 52 L86 52 L94 108 L34 108 Z" fill="#6cc2be" opacity="0.8"/>
  <path d="M88 32 C112 36 112 70 92 76" stroke="#6cc2be" stroke-width="8" fill="none"/>
  <path d="M40 20 L88 20" stroke="#fffbf5" stroke-width="6"/>`, "A jug of fresh water.");
item("dog_brush", `  <rect x="20" y="40" width="70" height="36" rx="14" fill="#a8744a"/>
  ${Array.from({ length: 8 }, (_, i) => `<path d="M${28 + i * 8} 76 L${28 + i * 8} 94" stroke="#fffbf5" stroke-width="4" stroke-linecap="round"/>`).join("")}
  <rect x="84" y="50" width="34" height="16" rx="8" fill="#7a5134"/>`, "Chloé's brush. She pretends to hate it.");
item("mamie_glove", `  <path d="M40 110 L40 60 C40 50 50 48 52 58 L52 30 C52 20 64 20 64 30 L64 24 C64 14 76 14 76 24 L76 30 C76 20 88 20 88 30 L88 70 C98 60 106 66 100 76 L84 110 Z" fill="#9c8ac4"/>
  <rect x="38" y="100" width="50" height="16" rx="5" fill="#7c6ab0"/>`, "One of Mamie's gardening gloves. It still smells of her.");
item("henri_scarf", `  <path d="M20 30 C50 20 80 40 108 30 L104 50 C78 60 50 40 24 50 Z" fill="#3e3570"/>
  <path d="M84 44 L96 110 L78 112 L70 48 Z" fill="#3e3570"/>
  ${[0, 1, 2, 3].map((i) => `<path d="M${76 + i * 6} 110 L${76 + i * 6} 122" stroke="#3e3570" stroke-width="3"/>`).join("")}
  <path d="M28 38 L100 34" stroke="#f6c453" stroke-width="3"/>`, "Henri's old navy scarf.");
item("margot_teddy", `  ${shadow(64, 118, 36, 6)}
  <circle cx="64" cy="80" r="30" fill="#c99a6b"/><circle cx="64" cy="44" r="24" fill="#c99a6b"/>
  <circle cx="44" cy="26" r="10" fill="#c99a6b"/><circle cx="84" cy="26" r="10" fill="#c99a6b"/>
  <circle cx="44" cy="26" r="5" fill="#a8744a"/><circle cx="84" cy="26" r="5" fill="#a8744a"/>
  <circle cx="56" cy="42" r="3" fill="${INK}"/><circle cx="72" cy="42" r="3" fill="${INK}"/>
  <ellipse cx="64" cy="52" rx="8" ry="6" fill="#e3c39a"/><circle cx="64" cy="50" r="3" fill="${INK}"/>
  <path d="M50 70 L78 70" stroke="#ee7b6b" stroke-width="6" stroke-linecap="round"/>`, "Margot's old teddy bear, with one ear chewed.");

// Chloé's bowl (a prop for the care tasks).
save("props/chloe/bowl_empty.svg", svg(120, 60, `  ${shadow(60, 54, 50, 5)}
  <path d="M10 22 L110 22 L98 52 L22 52 Z" fill="${BOW}"/><ellipse cx="60" cy="22" rx="50" ry="10" fill="#c95b52"/>
  <path d="M40 38 q20 -12 40 0" stroke="#fffbf5" stroke-width="4" fill="none" opacity="0.7"/>`, "Chloé's empty bowl."));

console.log("chloe art written");
