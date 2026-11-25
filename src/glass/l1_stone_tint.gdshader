// The painted shop arch, its stone tinted in its card's tier colour by a soft-light blend
// (buy-screen-l1.md §9, S1 "stone tint"). Only where the texture is drawn: never the opening.
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.5, 0.5, 0.5, 1.0);
// share of the soft-light result over the plain stone (0: untinted)
uniform float amount = 0.0;
// period (s), depth, phase (share of a period): the same slow breath as the arch's light
uniform vec3 motion = vec3(6.0, 0.0, 0.0);

vec3 soft_light(vec3 b, vec3 s) {
	vec3 d = mix(sqrt(b), ((16.0 * b - 12.0) * b + 4.0) * b, step(b, vec3(0.25)));
	vec3 dark = b - (1.0 - 2.0 * s) * b * (1.0 - b);
	vec3 light = b + (2.0 * s - 1.0) * (d - b);
	return mix(light, dark, step(s, vec3(0.5)));
}

void fragment() {
	vec4 stone = texture(TEXTURE, UV) * COLOR;
	float breath = 1.0 + motion.y * sin(TAU * (TIME / max(motion.x, 0.01) + motion.z));
	float share = clamp(amount * breath, 0.0, 1.0);
	COLOR = vec4(mix(stone.rgb, soft_light(stone.rgb, tint.rgb), share), stone.a);
}
