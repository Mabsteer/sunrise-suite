// Shared helpers for drawing room backgrounds (2400x1440 viewBox "-240 -180 2400 1440"; stage 0..1920 x 0..1080).
import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

export const SPRITES = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "assets", "sprites");

export function save(relPath, content) {
  const full = join(SPRITES, relPath);
  mkdirSync(dirname(full), { recursive: true });
  writeFileSync(full, content);
}

export const svg = (w, h, body, note, viewBox = `0 0 ${w} ${h}`) =>
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${viewBox}" width="${w}" height="${h}">\n  <!-- ${note} -->\n${body}\n</svg>\n`;

export const roomSvg = (body, note) => svg(2400, 1440, body, note, "-240 -180 2400 1440");

// Deterministic pseudo-random numbers so re-running gives the same art.
export function rng(seed) {
  let s = seed;
  return () => ((s = (s * 16807) % 2147483647) / 2147483647);
}

// Perspective rows between y0 and y1 (rows get taller towards the viewer).
export function rows(y0, y1, count) {
  const out = [y0];
  let total = 0;
  const weights = [];
  for (let i = 0; i < count; i++) { const w = Math.pow(1.22, i); weights.push(w); total += w; }
  let y = y0;
  for (const w of weights) { y += ((y1 - y0) * w) / total; out.push(Math.round(y)); }
  return out;
}

export function woodFloor(y0, y1, tints, seam, seed = 7) {
  const r = rng(seed);
  const ys = rows(y0, y1, 11);
  const out = [];
  for (let i = 0; i < ys.length - 1; i++) {
    const y = ys[i], h = ys[i + 1] - y;
    out.push(`<rect x="-240" y="${y}" width="2400" height="${h}" fill="${tints[i % tints.length]}"/>`);
    out.push(`<rect x="-240" y="${y}" width="2400" height="${Math.max(2, Math.round(h * 0.12))}" fill="#fffbf5" opacity="0.10"/>`);
    out.push(`<rect x="-240" y="${y + h - 2}" width="2400" height="2" fill="${seam}" opacity="0.35"/>`);
    const plank = 300 + i * 40;
    let x = -240 + r() * plank;
    while (x < 2160) { out.push(`<rect x="${Math.round(x)}" y="${y}" width="2" height="${h}" fill="${seam}" opacity="0.28"/>`); x += plank * (0.8 + r() * 0.5); }
  }
  return out.join("\n  ");
}

export function checkerFloor(y0, y1, a, b, grout) {
  const ys = rows(y0, y1, 9);
  const out = [];
  for (let i = 0; i < ys.length - 1; i++) {
    const y = ys[i], h = ys[i + 1] - y;
    const w = Math.round(h * 2.2 + 40);
    let col = 0;
    for (let x = -240 - (i % 2) * (w / 2); x < 2160; x += w, col++) {
      out.push(`<rect x="${Math.round(x)}" y="${y}" width="${w}" height="${h}" fill="${(col + i) % 2 ? a : b}"/>`);
    }
    out.push(`<rect x="-240" y="${y + h - 2}" width="2400" height="3" fill="${grout}" opacity="0.5"/>`);
  }
  return out.join("\n  ");
}

// A wall rect with rectangular holes (windows / doors), using evenodd fill.
export function wallWithHoles(x0, y0, x1, y1, holes, fill) {
  const outer = `M${x0} ${y0} H${x1} V${y1} H${x0} Z`;
  const inner = holes.map(([x, y, w, h]) => `M${x} ${y} H${x + w} V${y + h} H${x} Z`).join(" ");
  return `<path fill="${fill}" fill-rule="evenodd" d="${outer} ${inner}"/>`;
}

// A frame around a hole: [x, y, w, h], frame width fw.
export function frame([x, y, w, h], fw, fill, shade = "#e9d6b8") {
  return `<path fill="#3b2e3a" opacity="0.07" fill-rule="evenodd" d="M${x - fw + 10} ${y - fw + 10} H${x + w + fw + 10} V${y + h + fw + 10} H${x - fw + 10} Z M${x} ${y} H${x + w} V${y + h} H${x} Z"/>
  <path fill="${fill}" fill-rule="evenodd" d="M${x - fw} ${y - fw} H${x + w + fw} V${y + h + fw} H${x - fw} Z M${x} ${y} H${x + w} V${y + h} H${x} Z"/>
  <rect x="${x + w - 3}" y="${y}" width="3" height="${h}" fill="${shade}"/>`;
}

export function glassReflections([x, y, w, h]) {
  return `<polygon points="${x + w * 0.1},${y} ${x + w * 0.24},${y} ${x},${y + h * 0.36} ${x},${y + h * 0.2}" fill="#fffbf5" opacity="0.13"/>
  <polygon points="${x + w * 0.72},${y} ${x + w * 0.8},${y} ${x + w * 0.46},${y + h * 0.6} ${x + w * 0.38},${y + h * 0.6}" fill="#fffbf5" opacity="0.08"/>`;
}

export function lightLayer(beams, pools, note) {
  const polys = beams.map(p => `<polygon points="${p}" fill="url(#beam)"/>`).join("\n  ");
  const ell = pools.map(([cx, cy, rx, ry, op]) => `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="url(#pool)" opacity="${op}"/>`).join("\n  ");
  return roomSvg(`  <defs>
    <linearGradient id="beam" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fbe3a0" stop-opacity="0.55"/><stop offset="1" stop-color="#fbe3a0" stop-opacity="0"/></linearGradient>
    <radialGradient id="pool" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#f9b98a" stop-opacity="0.5"/><stop offset="1" stop-color="#f9b98a" stop-opacity="0"/></radialGradient>
  </defs>
  ${polys}
  ${ell}`, note);
}
