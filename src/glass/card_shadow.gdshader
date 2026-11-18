// card.css's drop-shadow(0 6px 8px rgba(0,0,0,.6)) for a GlassCard: the frame's alpha,
// Gaussian-blurred and tinted. The quad is larger than the card so the blur has room.
shader_type canvas_item;

uniform vec2 uv_scale = vec2(1.0);
uniform vec2 uv_offset = vec2(0.0);
uniform vec2 sigma_uv = vec2(0.01);
// Explicit duplicate-layer opacity: default 1 keeps all existing card shadows unchanged.
// Incoming fragment COLOR already includes the sampled frame alpha, which would clip the blur.
uniform float shadow_opacity = 1.0;
uniform vec4 shadow_colour : source_color = vec4(0.0, 0.0, 0.0, 0.6);

// TEXTURE is read here in fragment() itself: passed to a function as a sampler2D argument, it
// fails to compile on the Compatibility renderer ("custom_samplers ... tex_builtin").
void fragment() {
	vec2 uv = UV * uv_scale + uv_offset;
	float total = 0.0;
	float weights = 0.0;
	for (int y = -4; y <= 4; y++) {
		for (int x = -4; x <= 4; x++) {
			vec2 step = vec2(float(x), float(y)) * 0.75;
			float w = exp(-0.5 * dot(step, step));
			vec2 at = uv + step * sigma_uv;
			bool inside = at.x >= 0.0 && at.y >= 0.0 && at.x <= 1.0 && at.y <= 1.0;
			total += inside ? w * texture(TEXTURE, at).a : 0.0;
			weights += w;
		}
	}
	COLOR = vec4(shadow_colour.rgb, shadow_colour.a * total / weights * shadow_opacity);
}
