// A golden card's twinkle (buy-screen-l1.md §9, G3): a small four-point star at the card's upper
// right shoulder, shown for a moment each time the glint running along the gilt passes it. It is
// timed by the shader's own clock with the same period, sweep and phase as the card face's glint.
shader_type canvas_item;
render_mode blend_add;

uniform vec4 core : source_color = vec4(1.0, 0.984, 0.91, 1.0);
uniform vec4 glow : source_color = vec4(1.0, 0.878, 0.541, 1.0);
// period (s), when in the period the star peaks (s), how long it shows (s), phase (share)
uniform vec4 timing = vec4(5.0, 0.9, 0.22, 0.0);

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float t = mod(TIME / timing.x + timing.w, 1.0) * timing.x;
	float shown = exp(-pow((t - timing.y) / max(timing.z, 0.01), 2.0));
	float turn = (t - timing.y) * 0.8;
	mat2 spin = mat2(vec2(cos(turn), sin(turn)), vec2(-sin(turn), cos(turn)));
	vec2 q = abs(spin * p);
	float rays = exp(-q.y * 14.0) * max(1.0 - q.x, 0.0) + exp(-q.x * 14.0) * max(1.0 - q.y, 0.0);
	float centre = exp(-dot(p, p) * 30.0);
	float halo = exp(-dot(p, p) * 5.0) * 0.35;
	vec3 light = core.rgb * (centre + rays * 0.8) + glow.rgb * halo;
	// COLOR comes in as the vertex colour times the inherited modulate: keep it, so the twinkle
	// fades with its card (blend_add scales the colour by alpha).
	// Limit the peak before tint, so dimming also scales the bright centre.
	COLOR = vec4(min(light * shown, vec3(1.0)) * COLOR.rgb, COLOR.a);
}
