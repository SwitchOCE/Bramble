// stage.css #field: the picture through the window's panes, with filter: brightness() saturate().
// CSS applies the two in sRGB, in order; the saturate matrix is the Filter Effects one.
shader_type canvas_item;

uniform float brightness = 1.0;
uniform float saturation = 1.0;

void fragment() {
	vec3 c = texture(TEXTURE, UV).rgb * brightness;
	float s = saturation;
	mat3 m = mat3(
		vec3(0.213 + 0.787 * s, 0.213 - 0.213 * s, 0.213 - 0.213 * s),
		vec3(0.715 - 0.715 * s, 0.715 + 0.285 * s, 0.715 - 0.715 * s),
		vec3(0.072 - 0.072 * s, 0.072 - 0.072 * s, 0.072 + 0.928 * s)
	);
	COLOR = vec4(clamp(m * clamp(c, 0.0, 1.0), 0.0, 1.0), 1.0);
}
