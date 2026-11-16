// card.css's drop-shadow(0 6px 8px rgba(0,0,0,.6)) for a GlassCard: the frame's alpha,
// Gaussian-blurred and tinted. The quad is larger than the card so the blur has room.
shader_type canvas_item;

uniform vec2 uv_scale = vec2(1.0);
uniform vec2 uv_offset = vec2(0.0);
uniform vec2 sigma_uv = vec2(0.01);
uniform vec4 shadow_colour : source_color = vec4(0.0, 0.0, 0.0, 0.6);

float alpha_at(sampler2D tex, vec2 uv) {
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return 0.0;
	}
	return texture(tex, uv).a;
}

void fragment() {
	vec2 uv = UV * uv_scale + uv_offset;
	float total = 0.0;
	float weights = 0.0;
	for (int y = -4; y <= 4; y++) {
		for (int x = -4; x <= 4; x++) {
			vec2 step = vec2(float(x), float(y)) * 0.75;
			float w = exp(-0.5 * dot(step, step));
			total += w * alpha_at(TEXTURE, uv + step * sigma_uv);
			weights += w;
		}
	}
	COLOR = vec4(shadow_colour.rgb, shadow_colour.a * total / weights);
}
