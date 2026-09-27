#!/usr/bin/env node
// Sunrise Suite — room ambience generator (no dependencies).
//
// Writes one loopable mono WAV per room to assets/audio/ambience/<room>.wav: soft background sound
// until the Suno music exists (and quietly under it afterwards). Everything is synthesised from a
// seeded random generator, so the same recipe always gives the same file.
//
// Usage:
//   npm run ambience                 all rooms
//   npm run ambience -- --only hall  one (or a comma-separated list of) room(s)
//
// A room's recipe is a list of layers (see ROOMS below): sea, gulls, birds, tick, hum, creak, wind,
// fly, murmur, bees, rustle. Each layer has a gain. The loop is seamless: periodic sounds fit a whole
// number of times into the loop, and the noise beds are crossfaded across the loop point. The WAV
// carries a "smpl" loop chunk, so Godot loops it by itself.

import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const OUT_DIR = resolve(HERE, "..", "..", "assets", "audio", "ambience");
const SR = 22050;
const SECONDS = 14;
const N = SR * SECONDS;
const FADE = SR; // one second crossfade over the loop point
const PEAK = 0.5;

const ROOMS = {
  kitchen: [["hum", 0.05], ["tick", 0.05, { every: 1, pitch: 2600 }], ["gulls", 0.08, { count: 2 }], ["sea", 0.1]],
  hall: [["tick", 0.12, { every: 1, pitch: 1500, tock: 1200 }], ["creak", 0.1, { count: 2 }], ["sea", 0.05]],
  bedroom: [["sea", 0.22], ["rustle", 0.06, { count: 2 }], ["gulls", 0.04, { count: 1 }]],
  lounge: [["sea", 0.26], ["wind", 0.06], ["creak", 0.05, { count: 1 }]],
  garden: [["birds", 0.1, { count: 9 }], ["bees", 0.03], ["sea", 0.14]],
  shed: [["wind", 0.12], ["creak", 0.12, { count: 3 }], ["fly", 0.035]],
  front_garden: [["birds", 0.09, { count: 7 }], ["murmur", 0.05], ["sea", 0.1], ["gulls", 0.05, { count: 1 }]],
};

// ---------- seeded randomness ----------
function mulberry32(seed) {
  return () => {
    seed |= 0; seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const hash = (s) => [...s].reduce((h, c) => (Math.imul(h, 31) + c.charCodeAt(0)) | 0, 7);

// ---------- building blocks (each returns a Float32Array of N samples) ----------

// Noise, low-passed (one pole) and made loop-seamless by crossfading its tail into its head.
function noiseBed(rnd, cutoff, len = N) {
  const total = len + FADE;
  const a = Math.exp((-2 * Math.PI * cutoff) / SR);
  const buf = new Float32Array(total);
  let y = 0;
  for (let i = 0; i < total; i++) { y = (1 - a) * (rnd() * 2 - 1) + a * y; buf[i] = y; }
  const out = new Float32Array(len);
  for (let i = 0; i < len; i++) out[i] = buf[i];
  for (let i = 0; i < FADE; i++) { const k = i / FADE; out[i] = buf[i] * k + buf[len + i] * (1 - k); }
  return normalize(out);
}
// Band: high-pass a low-passed bed (the difference of two one-pole filters).
function band(rnd, lo, hi) {
  const a = noiseBed(rnd, hi), b = noiseBed(mulberry32(Math.floor(rnd() * 1e9)), lo);
  const out = new Float32Array(N);
  for (let i = 0; i < N; i++) out[i] = a[i] - b[i] * 0.8;
  return normalize(out);
}
// A slow swell that fits a whole number of times into the loop.
const swell = (i, cycles, phase = 0) => 0.5 + 0.5 * Math.sin((2 * Math.PI * cycles * i) / N + phase);
function normalize(x) {
  let m = 0;
  for (const v of x) m = Math.max(m, Math.abs(v));
  if (m > 0) for (let i = 0; i < x.length; i++) x[i] /= m;
  return x;
}
// Places short events at seeded times, away from the loop point.
function scatter(rnd, count, make) {
  const out = new Float32Array(N);
  for (let e = 0; e < count; e++) {
    const start = Math.floor(FADE + rnd() * (N - 3 * FADE));
    const ev = make(rnd);
    for (let i = 0; i < ev.length && start + i < N; i++) out[start + i] += ev[i];
  }
  return out;
}
const env = (i, len, attack, release) => Math.min(1, i / attack, (len - i) / release);

const LAYERS = {
  // Waves on the beach: low noise with slow swells (3 and 2 per loop).
  sea(rnd) {
    const bed = noiseBed(rnd, 420);
    const hiss = band(rnd, 900, 3200);
    const out = new Float32Array(N);
    const p = rnd() * 6;
    for (let i = 0; i < N; i++) {
      const s = 0.35 + 0.65 * swell(i, 3, p) * (0.7 + 0.3 * swell(i, 2, p * 2));
      out[i] = bed[i] * s + hiss[i] * 0.25 * s * s;
    }
    return out;
  },
  // Far-off gulls: falling cries with a wobble.
  gulls(rnd, o) {
    return scatter(rnd, o.count ?? 2, (r) => {
      const calls = 2 + Math.floor(r() * 3), out = [];
      for (let c = 0; c < calls; c++) {
        const len = Math.floor(SR * (0.22 + r() * 0.12)), f0 = 1500 + r() * 400;
        let ph = 0;
        for (let i = 0; i < len; i++) {
          const t = i / len, f = f0 * (1 - 0.35 * t) * (1 + 0.03 * Math.sin(i / 60));
          ph += (2 * Math.PI * f) / SR;
          out.push(Math.sin(ph) * (Math.sin(Math.PI * t) ** 1.5) * 0.8 + Math.sin(ph * 2) * 0.15 * Math.sin(Math.PI * t));
        }
        for (let i = 0; i < SR * 0.12; i++) out.push(0);
      }
      return out;
    });
  },
  // Little birds: quick high trills.
  birds(rnd, o) {
    return scatter(rnd, o.count ?? 6, (r) => {
      const notes = 3 + Math.floor(r() * 5), out = [], f0 = 2800 + r() * 1600;
      let ph = 0;
      for (let n = 0; n < notes; n++) {
        const len = Math.floor(SR * (0.05 + r() * 0.05)), df = (r() - 0.3) * 1500;
        for (let i = 0; i < len; i++) {
          const t = i / len;
          ph += (2 * Math.PI * (f0 + df * t)) / SR;
          out.push(Math.sin(ph) * Math.sin(Math.PI * t));
        }
        for (let i = 0; i < SR * 0.03; i++) out.push(0);
      }
      return out;
    });
  },
  // A clock: a short woody click every `every` seconds (tick, tock).
  tick(rnd, o) {
    const out = new Float32Array(N), every = Math.floor(SR * (o.every ?? 1));
    for (let s = 0, k = 0; s < N; s += every, k++) {
      const f = k % 2 && o.tock ? o.tock : (o.pitch ?? 1500), len = Math.floor(SR * 0.03);
      for (let i = 0; i < len && s + i < N; i++) {
        out[s + i] += Math.sin((2 * Math.PI * f * i) / SR) * Math.exp(-i / (SR * 0.004)) + (rnd() * 2 - 1) * 0.3 * Math.exp(-i / (SR * 0.002));
      }
    }
    return out;
  },
  // The old fridge: a low hum with a slow wobble (whole cycles per loop).
  hum() {
    const out = new Float32Array(N);
    for (let i = 0; i < N; i++) {
      const t = i / SR;
      out[i] = (Math.sin(2 * Math.PI * 50 * t) * 0.6 + Math.sin(2 * Math.PI * 100 * t) * 0.3 + Math.sin(2 * Math.PI * 150 * t) * 0.1) * (0.8 + 0.2 * swell(i, 1));
    }
    return out;
  },
  // Old wood settling: a slow, rough, low groan.
  creak(rnd, o) {
    return scatter(rnd, o.count ?? 2, (r) => {
      const len = Math.floor(SR * (0.4 + r() * 0.5)), f0 = 90 + r() * 90, out = [];
      let ph = 0;
      for (let i = 0; i < len; i++) {
        const t = i / len, f = f0 * (1 + 0.5 * t) * (1 + 0.15 * (r() - 0.5));
        ph += (2 * Math.PI * f) / SR;
        const saw = ((ph / (2 * Math.PI)) % 1) * 2 - 1;
        out.push(saw * env(i, len, SR * 0.05, SR * 0.2) * (0.6 + 0.4 * Math.sin(i / 30)));
      }
      return out;
    });
  },
  // Wind through the gaps: mid noise, gently gusting.
  wind(rnd) {
    const bed = band(rnd, 300, 1400), out = new Float32Array(N), p = rnd() * 6;
    for (let i = 0; i < N; i++) out[i] = bed[i] * (0.3 + 0.7 * swell(i, 2, p) * swell(i, 5, p * 3));
    return out;
  },
  // A fly buzzing about, now and then.
  fly(rnd) {
    const out = new Float32Array(N);
    let ph = 0;
    for (let i = 0; i < N; i++) {
      const f = 190 + 25 * Math.sin((2 * Math.PI * 3 * i) / N) + 8 * Math.sin(i / 700);
      ph += (2 * Math.PI * f) / SR;
      const saw = ((ph / (2 * Math.PI)) % 1) * 2 - 1;
      out[i] = saw * Math.max(0, Math.sin((2 * Math.PI * 2 * i) / N + 1)) ** 3;
    }
    return out;
  },
  // Bees near the flowers: a soft warm drone.
  bees() {
    const out = new Float32Array(N);
    for (let i = 0; i < N; i++) {
      const t = i / SR;
      out[i] = (Math.sin(2 * Math.PI * 220 * t + Math.sin(2 * Math.PI * 7 * t)) * 0.6 + Math.sin(2 * Math.PI * 330 * t) * 0.2) * swell(i, 4, 1.3) ** 2;
    }
    return out;
  },
  // The market around the corner: far-off voices (speech-band noise with syllable-like bursts).
  murmur(rnd) {
    const bed = band(rnd, 250, 1100), out = new Float32Array(N);
    const syll = noiseBed(mulberry32(Math.floor(rnd() * 1e9)), 5);
    for (let i = 0; i < N; i++) out[i] = bed[i] * (0.5 + 0.5 * Math.abs(syll[i]));
    return out;
  },
  // A curtain or a page stirring in the breeze.
  rustle(rnd, o) {
    return scatter(rnd, o.count ?? 2, (r) => {
      const len = Math.floor(SR * (0.6 + r() * 0.6)), out = [];
      let y = 0;
      for (let i = 0; i < len; i++) { y = 0.7 * y + 0.3 * (r() * 2 - 1); out.push((r() * 2 - 1 - y) * env(i, len, SR * 0.2, SR * 0.3) * 0.7); }
      return out;
    });
  },
};

// ---------- WAV writing (16-bit mono PCM with a "smpl" loop chunk) ----------
function wav(samples) {
  const data = Buffer.alloc(N * 2);
  for (let i = 0; i < N; i++) data.writeInt16LE(Math.max(-32767, Math.min(32767, Math.round(samples[i] * 32767))), i * 2);
  const smpl = Buffer.alloc(8 + 36 + 24);
  smpl.write("smpl", 0); smpl.writeUInt32LE(36 + 24, 4);
  smpl.writeUInt32LE(Math.round(1e9 / SR), 8 + 8); // sample period (ns)
  smpl.writeUInt32LE(60, 8 + 12); // MIDI unity note
  smpl.writeUInt32LE(1, 8 + 28); // one loop
  smpl.writeUInt32LE(0, 8 + 36); // cue id
  smpl.writeUInt32LE(0, 8 + 40); // forward loop
  smpl.writeUInt32LE(0, 8 + 44); // start
  smpl.writeUInt32LE(N - 1, 8 + 48); // end (inclusive)
  const fmt = Buffer.alloc(8 + 16);
  fmt.write("fmt ", 0); fmt.writeUInt32LE(16, 4); fmt.writeUInt16LE(1, 8); fmt.writeUInt16LE(1, 10);
  fmt.writeUInt32LE(SR, 12); fmt.writeUInt32LE(SR * 2, 16); fmt.writeUInt16LE(2, 20); fmt.writeUInt16LE(16, 22);
  const dataHead = Buffer.alloc(8); dataHead.write("data", 0); dataHead.writeUInt32LE(data.length, 4);
  const body = Buffer.concat([fmt, dataHead, data, smpl]);
  const head = Buffer.alloc(12); head.write("RIFF", 0); head.writeUInt32LE(4 + body.length, 4); head.write("WAVE", 8);
  return Buffer.concat([head, body]);
}

// ---------- main ----------
const onlyArg = process.argv.indexOf("--only");
const only = onlyArg > 0 ? new Set(process.argv[onlyArg + 1].split(",")) : null;
mkdirSync(OUT_DIR, { recursive: true });
for (const [room, layers] of Object.entries(ROOMS)) {
  if (only && !only.has(room)) continue;
  const mix = new Float32Array(N);
  for (const [name, gain, opts] of layers) {
    const rnd = mulberry32(hash(room + ":" + name));
    const layer = normalize(LAYERS[name](rnd, opts ?? {}));
    for (let i = 0; i < N; i++) mix[i] += layer[i] * gain;
  }
  let m = 0;
  for (const v of mix) m = Math.max(m, Math.abs(v));
  for (let i = 0; i < N; i++) mix[i] *= PEAK / (m || 1);
  const path = join(OUT_DIR, room + ".wav");
  writeFileSync(path, wav(mix));
  console.log(`ambience: ${room}.wav (${SECONDS}s, ${layers.map((l) => l[0]).join(" + ")})`);
}
