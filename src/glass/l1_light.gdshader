// A soft coloured light round a shape, drawn at run time: an L1 card, a circle, a shop arch or a
// flat ellipse. Two blurred, grown copies of the shape (near and far) give the glow; a shape may
// also be filled inside with a dark base and a radial light (the shop arch's recess). The light
// can breathe slowly and flicker a little, from the shader's own clock.
shader_type canvas_item;
render_mode blend_premul_alpha;

// 0 the L1 card hexagon, 1 a circle, 2 a pointed shop arch, 3 an ellipse
uniform int shape = 0;
// the shape's box in the node's pixels: x, y, w, h
uniform vec4 shape_rect = vec4(0.0, 0.0, 140.0, 250.0);
// hexagon: sin and cos of the point angle
uniform vec2 slopes = vec2(0.5, 0.866);
// arch: each side arc's radius and the springing line's depth from the top
uniform vec2 arch = vec2(105.3, 104.7);
uniform vec4 colour : source_color = vec4(1.0);
// grow (px), blur (px, CSS: twice the Gaussian's sigma), opacity
uniform vec3 near = vec3(0.0, 8.0, 0.0);
uniform vec3 far = vec3(0.0, 20.0, 0.0);
// how much of the light adds to what is under it (1) rather than covering it (0)
uniform float additive = 0.5;
// inside the shape: a solid base colour (alpha 0 for none) grown by fill_grow px ...
uniform vec4 base : source_color = vec4(0.0);
uniform float fill_grow = 0.0;
// ... lit by a radial ellipse: centre and radii as shares of the shape's box ...
uniform vec4 fill_ellipse = vec4(0.5, 0.5, 0.5, 0.5);
// ... with opacities at its centre, at mid_stop, and at and beyond its rim (x, y, z; w mid_stop)
uniform vec4 fill = vec4(0.0, 0.0, 0.0, 0.5);
// period (s), depth of the slow breath, phase (share of a period), flicker depth
uniform vec4 motion = vec4(6.0, 0.0, 0.0, 0.0);
// extra opacity on top of everything, for a flash (0 none)
uniform float boost = 0.0;

varying vec2 local;

void vertex() {
	local = VERTEX;
}

float hexagon(vec2 p) {
	vec2 half_size = shape_rect.zw * 0.5;
	vec2 q = abs(p - shape_rect.xy - half_size);
	return max(q.x - half_size.x, dot(vec2(q.x, q.y - half_size.y), slopes));
}

float pointed_arch(vec2 p) {
	vec2 at = p - shape_rect.xy;
	float w = shape_rect.z;
	if (at.y < arch.y) {
		float left = length(at - vec2(arch.x, arch.y)) - arch.x;
		float right = length(at - vec2(w - arch.x, arch.y)) - arch.x;
		return max(left, right);
	}
	return max(abs(at.x - w * 0.5) - w * 0.5, at.y - shape_rect.w);
}

// Signed distance in pixels, negative inside (exact enough for a soft light).
float distance_to_shape(vec2 p) {
	if (shape == 1) {
		return length(p - shape_rect.xy - shape_rect.zw * 0.5) - shape_rect.z * 0.5;
	}
	if (shape == 2) {
		return pointed_arch(p);
	}
	if (shape == 3) {
		vec2 radii = shape_rect.zw * 0.5;
		vec2 q = (p - shape_rect.xy - radii) / radii;
		return (length(q) - 1.0) * min(radii.x, radii.y);
	}
	return hexagon(p);
}

// A blurred edge: the share of a Gaussian of this blur lying inside a line d pixels away.
float soft(float d, float blur) {
	float sigma = max(blur * 0.5, 0.5);
	return 1.0 / (1.0 + exp(1.702 * d / sigma));
}

void fragment() {
	float d = distance_to_shape(local);
	float pulse = 1.0;
	if (motion.y > 0.0) {
		pulse += motion.y * sin(TAU * (TIME / motion.x + motion.z));
	}
	if (motion.w > 0.0) {
		float seed = motion.z * 37.0;
		pulse += motion.w * (0.6 * sin(TIME * 7.3 + seed) + 0.4 * sin(TIME * 12.9 + seed * 1.7));
	}
	float glow = near.z * soft(d - near.x, near.y) + far.z * soft(d - far.x, far.y);
	glow = clamp(glow * pulse + boost, 0.0, 1.0);
	vec4 light = vec4(colour.rgb * glow, glow * (1.0 - additive));
	if (base.a > 0.0 || fill.x > 0.0) {
		vec2 box = shape_rect.zw;
		vec2 q = (local - shape_rect.xy - fill_ellipse.xy * box) / (fill_ellipse.zw * box);
		float r = length(q);
		float lit = r < fill.w
			? mix(fill.x, fill.y, r / fill.w)
			: mix(fill.y, fill.z, clamp((r - fill.w) / (1.0 - fill.w), 0.0, 1.0));
		lit = clamp(lit * pulse, 0.0, 1.0);
		vec3 inside = mix(base.rgb, colour.rgb, lit);
		float half_pixel = 0.5;
		float cover = 1.0 - smoothstep(-half_pixel, half_pixel, d - fill_grow);
		light = mix(light, vec4(inside, 1.0) * max(base.a, lit), cover);
	}
	COLOR = light;
}
