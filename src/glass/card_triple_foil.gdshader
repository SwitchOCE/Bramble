shader_type canvas_item;

uniform float travel;
uniform float spacing;
uniform float slope;
uniform float band_width;
uniform float strength;
uniform float stat_feather;
uniform float colour_diagonal_rate;
uniform float colour_x_rate;
uniform vec4 colour_a : source_color;
uniform vec4 colour_b : source_color;
uniform vec2 card_units;
uniform vec3 attack_disc;
uniform vec3 health_disc;

void fragment() {
	float contour = texture(TEXTURE, UV).a;
	vec2 at = UV * card_units;
	float safe_attack = smoothstep(attack_disc.z, attack_disc.z + stat_feather, distance(at, attack_disc.xy));
	float safe_health = smoothstep(health_disc.z, health_disc.z + stat_feather, distance(at, health_disc.xy));
	float diagonal = UV.y + UV.x * slope - travel;
	float centre = abs(fract(diagonal / spacing) - 0.5) * spacing;
	float band = 1.0 - smoothstep(0.0, band_width, centre);
	float rainbow = 0.5 + 0.5 * sin(diagonal * colour_diagonal_rate + UV.x * colour_x_rate);
	vec3 tint = mix(colour_a.rgb, colour_b.rgb, rainbow);
	tint = mix(tint, vec3(1.0), band * band);
	COLOR = vec4(tint, contour * safe_attack * safe_health * band * strength);
}
