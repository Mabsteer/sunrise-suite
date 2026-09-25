#!/usr/bin/env node
// Sunrise Suite — sound effect generator (jsfxr).
//
// Reads tools/sfx/sfx.json and writes one WAV per sound to assets/audio/sfx/<name>.wav,
// plus tools/sfx/LINKS.md with an sfxr.me link per sound for tweaking in a browser.
//
// Usage:
//   npm run sfx                      generate every sound
//   npm run sfx -- --only lock_open  generate one (or a comma-separated list of) sound(s)
//   npm run sfx -- --list            list sounds with duration / peak level, write nothing
//
// A sound entry in sfx.json is one of:
//   { "preset": "pickupCoin", "seed": 7, "overrides": { "wave_type": 2 } }   preset rolled with a fixed seed
//   { "overrides": { ... } }                                              start from jsfxr defaults
//   { "b58": "..." }                                                      pasted from an sfxr.me link (text after '#')
// Optional per sound: "volume" (0..1, replaces defaults.sound_vol), "note" (free text).
// The same entry always produces the same WAV (Math.random is seeded while generating).

import { sfxr, jsfxr } from "jsfxr";
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(HERE, "..", "..");
const DEFS_PATH = join(HERE, "sfx.json");
const OUT_DIR = join(ROOT, "assets", "audio", "sfx");
const LINKS_PATH = join(HERE, "LINKS.md");

const PRESETS = ["pickupCoin", "laserShoot", "explosion", "powerUp", "hitHurt", "jump",
  "blipSelect", "synth", "tone", "click", "random"];
const WAVE_NAMES = ["square", "sawtooth", "sine", "noise"];
const PARAM_KEYS = new Set(Object.keys(new jsfxr.Params()));

// ---------- helpers ----------

function fail(msg) {
  console.error(`sfx: ${msg}`);
  process.exit(1);
}

// Small deterministic PRNG (mulberry32).
function mulberry32(seed) {
  let a = seed >>> 0;
  return function () {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// Run fn with Math.random replaced by a seeded PRNG (jsfxr uses Math.random for presets and noise).
function withSeed(seed, fn) {
  const original = Math.random;
  Math.random = mulberry32(seed);
  try {
    return fn();
  } finally {
    Math.random = original;
  }
}

function hashName(name) {
  let h = 2166136261;
  for (const ch of name) h = Math.imul(h ^ ch.charCodeAt(0), 16777619);
  return h >>> 0;
}

function buildParams(name, entry, defaults) {
  const p = new jsfxr.Params();
  if (entry.b58) {
    p.fromB58(String(entry.b58).replace(/^.*#/, ""));
  } else if (entry.preset) {
    if (!PRESETS.includes(entry.preset)) {
      fail(`"${name}": unknown preset "${entry.preset}". Use one of: ${PRESETS.join(", ")}`);
    }
    p[entry.preset]();
  }
  const overrides = { ...(defaults.overrides || {}), ...(entry.overrides || {}) };
  if (entry.b58) delete overrides.wave_type; // a pasted sfxr.me sound is used as-is
  for (const [key, value] of Object.entries(overrides)) {
    if (!PARAM_KEYS.has(key)) fail(`"${name}": unknown parameter "${key}"`);
    if (typeof value !== "number") fail(`"${name}": parameter "${key}" must be a number`);
    p[key] = value;
  }
  p.sound_vol = entry.volume ?? defaults.sound_vol ?? 0.25;
  p.sample_rate = defaults.sample_rate ?? 44100;
  p.sample_size = defaults.sample_size ?? 16;
  return p;
}

function renderWav(params, seed) {
  const wave = withSeed(seed, () => sfxr.toWave(params));
  const match = /^data:audio\/wav;base64,(.*)$/.exec(wave.dataURI);
  if (!match) fail("jsfxr did not return a WAV data URI");
  return Buffer.from(match[1], "base64");
}

// Duration (s) and peak (0..1) of a 16-bit or 8-bit mono PCM WAV buffer.
function describeWav(buf) {
  const sampleRate = buf.readUInt32LE(24);
  const bits = buf.readUInt16LE(34);
  let offset = 12;
  while (offset + 8 <= buf.length && buf.toString("ascii", offset, offset + 4) !== "data") {
    offset += 8 + buf.readUInt32LE(offset + 4);
  }
  const dataStart = offset + 8;
  const bytes = Math.min(buf.readUInt32LE(offset + 4), buf.length - dataStart);
  let peak = 0;
  if (bits === 16) {
    for (let i = 0; i + 1 < bytes; i += 2) peak = Math.max(peak, Math.abs(buf.readInt16LE(dataStart + i)) / 32768);
  } else {
    for (let i = 0; i < bytes; i++) peak = Math.max(peak, Math.abs(buf.readUInt8(dataStart + i) - 128) / 128);
  }
  return { seconds: bytes / (bits / 8) / sampleRate, peak };
}

// ---------- main ----------

const args = process.argv.slice(2);
const listOnly = args.includes("--list");
const onlyIdx = args.indexOf("--only");
const only = onlyIdx >= 0 ? new Set((args[onlyIdx + 1] || "").split(",").filter(Boolean)) : null;
if (onlyIdx >= 0 && (!only || only.size === 0)) fail("--only needs a sound name, e.g. --only lock_open");

if (!existsSync(DEFS_PATH)) fail(`missing ${DEFS_PATH}`);
let defs;
try {
  defs = JSON.parse(readFileSync(DEFS_PATH, "utf8"));
} catch (e) {
  fail(`sfx.json is not valid JSON: ${e.message}`);
}
const defaults = defs.defaults || {};
const sounds = defs.sounds || {};
const names = Object.keys(sounds).filter((n) => !n.startsWith("_"));

if (only) {
  for (const n of only) if (!sounds[n]) fail(`no sound named "${n}" in sfx.json`);
}

mkdirSync(OUT_DIR, { recursive: true });
const links = [
  "# Sound effect edit links",
  "",
  "Generated by `npm run sfx` — do not edit by hand.",
  "",
  "To tweak a sound: open its link, adjust it on sfxr.me, copy the new link, and paste the part",
  "after `#` into that sound's `\"b58\"` field in `tools/sfx/sfx.json` (remove `preset`, `seed` and",
  "`overrides`). Then run `npm run sfx` again.",
  "",
  "| Sound | Wave | Length | Peak | Edit |",
  "|---|---|---|---|---|",
];

let written = 0;
for (const name of names) {
  const entry = sounds[name];
  const seed = entry.seed ?? hashName(name);
  const params = withSeed(seed, () => buildParams(name, entry, defaults));
  const wav = renderWav(params, seed);
  const { seconds, peak } = describeWav(wav);
  const b58 = params.toB58();
  const wave = WAVE_NAMES[params.wave_type] ?? String(params.wave_type);
  links.push(`| \`${name}\` | ${wave} | ${seconds.toFixed(2)} s | ${Math.round(peak * 100)}% | [sfxr.me](https://sfxr.me/#${b58}) |`);

  if (peak < 0.01) console.warn(`sfx: warning — "${name}" is (almost) silent`);
  if (listOnly) {
    console.log(`${name.padEnd(18)} ${wave.padEnd(9)} ${seconds.toFixed(2)}s  peak ${Math.round(peak * 100)}%`);
    continue;
  }
  if (only && !only.has(name)) continue;
  writeFileSync(join(OUT_DIR, `${name}.wav`), wav);
  written++;
  console.log(`sfx: ${name}.wav  (${seconds.toFixed(2)}s, peak ${Math.round(peak * 100)}%)`);
}

if (!listOnly) {
  writeFileSync(LINKS_PATH, links.join("\n") + "\n");
  console.log(`sfx: wrote ${written} file(s) to assets/audio/sfx/ and updated tools/sfx/LINKS.md`);
}
