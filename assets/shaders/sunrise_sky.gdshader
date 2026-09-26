shader_type canvas_item;
// Sunrise sky + sea backdrop. One parameter drives everything: sunrise_t (0 = before dawn, 1 = sun just cleared the horizon).
// Values above 1 keep the sun rising (used for the celebration after the balcony door opens).

uniform float sunrise_t : hint_range(0.0, 1.3) = 0.5;
uniform float aspect = 1.7778;          // rect width / height, set by script
uniform float horizon = 0.55;           // horizon height as a fraction of the rect (0 = top)
uniform float gradient_top = 0.0;       // where the sky gradient starts (fraction of the rect); above it the sky stays "top" coloured
uniform float sun_x = 0.5;              // sun position as a fraction of the rect width
uniform float sun_radius = 0.055;       // in rect-height units
uniform float motion = 1.0;             // 0 when "reduce motion" is on

// Sky colours: before dawn, mid-sunrise, sunrise.
uniform vec4 top_night : source_color = vec4(0.094, 0.078, 0.216, 1.0);
uniform vec4 top_mid : source_color = vec4(0.243, 0.208, 0.439, 1.0);
uniform vec4 top_day : source_color = vec4(0.561, 0.686, 0.863, 1.0);
uniform vec4 mid_night : source_color = vec4(0.212, 0.169, 0.380, 1.0);
uniform vec4 mid_mid : source_color = vec4(0.612, 0.541, 0.769, 1.0);
uniform vec4 mid_day : source_color = vec4(0.984, 0.800, 0.720, 1.0);
uniform vec4 low_night : source_color = vec4(0.478, 0.341, 0.525, 1.0);
uniform vec4 low_mid : source_color = vec4(0.976, 0.600, 0.490, 1.0);
uniform vec4 low_day : source_color = vec4(0.980, 0.800, 0.620, 1.0);
// Sea colours.
uniform vec4 sea_far_night : source_color = vec4(0.169, 0.200, 0.345, 1.0);
uniform vec4 sea_far_mid : source_color = vec4(0.380, 0.380, 0.620, 1.0);
uniform vec4 sea_far_day : source_color = vec4(0.424, 0.714, 0.722, 1.0);
uniform vec4 sea_near_night : source_color = vec4(0.078, 0.137, 0.227, 1.0);
uniform vec4 sea_near_mid : source_color = vec4(0.160, 0.200, 0.400, 1.0);
uniform vec4 sea_near_day : source_color = vec4(0.122, 0.373, 0.420, 1.0);
// Sun.
uniform vec4 sun_low : source_color = vec4(0.980, 0.470, 0.360, 1.0);
uniform vec4 sun_high : source_color = vec4(0.992, 0.820, 0.430, 1.0);

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

vec3 ramp3(vec3 a, vec3 b, vec3 c, float t) {
	return mix(mix(a, b, clamp(t * 2.0, 0.0, 1.0)), c, clamp(t * 2.0 - 1.0, 0.0, 1.0));
}

void fragment() {
	float t = clamp(sunrise_t, 0.0, 1.0);
	float rise = sunrise_t;
	float tm = TIME * motion;
	vec2 uv = UV;
	vec2 p = vec2(uv.x * aspect, uv.y);

	// Sun path: hidden below the horizon at t=0, just cleared at t=1.
	float sun_y = horizon + sun_radius * 1.6 - rise * sun_radius * 2.75;
	vec2 sun_p = vec2(sun_x * aspect, sun_y);
	float d_sun = length(p - sun_p);
	vec3 sun_col = mix(sun_low.rgb, sun_high.rgb, smoothstep(0.2, 1.1, rise));

	vec3 top = ramp3(top_night.rgb, top_mid.rgb, top_day.rgb, t);
	vec3 mid = ramp3(mid_night.rgb, mid_mid.rgb, mid_day.rgb, t);
	vec3 low = ramp3(low_night.rgb, low_mid.rgb, low_day.rgb, t);

	vec3 col;
	if (uv.y < horizon) {
		// ---- Sky ----
		float s = clamp((uv.y - gradient_top) / max(horizon - gradient_top, 0.001), 0.0, 1.0);
		col = mix(top, mid, smoothstep(0.0, 0.62, s));
		col = mix(col, low, smoothstep(0.55, 1.0, s));

		// Warm glow around the sun, stronger as it rises.
		float glow = exp(-d_sun * mix(9.0, 6.0, t)) * mix(0.35, 0.7, t);
		col += sun_col * glow * 0.45;
		col = mix(col, low * 1.08, exp(-(horizon - uv.y) * 22.0) * 0.35 * (0.4 + t));

		// Stars fade out as dawn breaks.
		vec2 grid = p * 70.0;
		vec2 cell = floor(grid);
		float dot_mask = smoothstep(0.16, 0.02, length(fract(grid) - 0.5));
		float star = step(0.975, hash(cell)) * dot_mask * (1.0 - s * 0.8);
		float twinkle = 0.6 + 0.4 * sin(tm * 2.0 + hash(cell + 3.1) * 40.0);
		col += vec3(1.0, 0.95, 0.9) * star * twinkle * (1.0 - smoothstep(0.0, 0.45, t)) * 0.8;

		// Long soft cloud bands, lit from below by the sun.
		float band = smoothstep(0.18, 0.4, s) * (1.0 - smoothstep(0.78, 0.97, s));
		float c = fbm(vec2(p.x * 1.6 + tm * 0.012, uv.y * 9.0));
		float cloud = smoothstep(0.52, 0.78, c) * band;
		vec3 cloud_dark = mix(mid_night.rgb * 0.9, mid_mid.rgb * 0.95, t);
		vec3 cloud_lit = mix(low_mid.rgb, vec3(1.0, 0.86, 0.78), t);
		float lit = clamp(0.25 + s * 0.6 + glow * 0.8, 0.0, 1.0);
		col = mix(col, mix(cloud_dark, cloud_lit, lit), cloud * 0.75);

		// Sun disc (drawn last, only above the horizon).
		float halo = smoothstep(sun_radius * 1.7, sun_radius, d_sun) * smoothstep(0.0, 0.4, rise);
		col = mix(col, sun_col, halo * 0.18);
		float disc = smoothstep(sun_radius, sun_radius - 0.004, d_sun);
		col = mix(col, sun_col, disc);
		col = mix(col, vec3(1.0, 0.97, 0.86), disc * smoothstep(sun_radius, 0.0, d_sun) * 0.55);
	} else {
		// ---- Sea ----
		float s2 = (uv.y - horizon) / max(1.0 - horizon, 0.001);
		vec3 far = ramp3(sea_far_night.rgb, sea_far_mid.rgb, sea_far_day.rgb, t);
		vec3 near = ramp3(sea_near_night.rgb, sea_near_mid.rgb, sea_near_day.rgb, t);
		col = mix(far, near, pow(s2, 0.7));
		col = mix(col, mix(mid, low, 0.6), (1.0 - s2) * 0.42);

		// Gentle wave bands.
		float wave = sin(pow(s2, 0.55) * 150.0 - tm * 1.1 + noise(vec2(p.x * 3.0, s2 * 20.0)) * 4.0);
		col *= 0.965 + 0.035 * wave;

		// Sparkling path of sunlight under the sun.
		float width = 0.05 + s2 * 0.35;
		float dx = abs(p.x - sun_p.x) / width;
		float column = exp(-dx * dx * 2.2);
		float glint = smoothstep(0.62, 0.92, noise(vec2(p.x * 26.0 / (0.25 + s2), pow(s2, 0.5) * 90.0 + tm * 0.8)));
		float strength = smoothstep(0.1, 0.9, rise) * 0.95;
		col += sun_col * column * glint * strength;
		col += sun_col * column * 0.12 * strength;

		// Bright haze right at the horizon line.
		col = mix(col, low * 1.05, exp(-s2 * 60.0) * 0.5);
	}

	COLOR = vec4(col, 1.0);
}
