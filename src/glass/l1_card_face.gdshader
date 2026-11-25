// The clipped art, lead and solid glass edge of an L1 unit card or hand spell.
shader_type canvas_item;

uniform vec2 face_size;
uniform float face_scale;
uniform vec2 slopes;
uniform bool circle;
uniform float lead_width;
uniform vec2 lead_direction;
uniform sampler2D lead_ramp : source_color, filter_linear, repeat_disable;
uniform bool has_art;
uniform sampler2D art : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 crop;
uniform vec2 bevel_stops;
uniform vec2 bevel_alpha;
uniform vec4 edge_top : source_color;
uniform vec4 edge_bottom : source_color;
uniform vec4 edge_line : source_color;
uniform vec2 edge_offsets;
// A golden card's glint along its gilt (buy-screen-l1.md §9, G3): period (s), sweep (s), width (a
// share of the way round), phase (a share of the period). The colour's alpha is its strength; 0
// draws none. Only the lead takes it, never the art.
uniform vec4 glint = vec4(5.0, 1.4, 0.05, 0.0);
uniform vec4 glint_colour : source_color = vec4(0.0);

varying vec2 local;
varying vec4 tint;

void vertex() {
	local = VERTEX / face_scale;
	tint = COLOR;
}

// Signed distance to the closest side's line inside the hexagon, or to the circle.
float outline(vec2 at) {
	vec2 half_size = face_size * 0.5;
	vec2 p = abs(at - half_size);
	if (circle) {
		return length(p) - half_size.x;
	}
	return max(p.x - half_size.x, dot(vec2(p.x, p.y - half_size.y), slopes));
}

float coverage(float d, float half_pixel) {
	return 1.0 - smoothstep(-half_pixel, half_pixel, d);
}

void fragment() {
	float half_pixel = max(length(vec2(dFdx(local.x), dFdy(local.x))) * 0.5, 0.001);
	float d = outline(local);
	float face = coverage(d, half_pixel);
	float window = coverage(d + lead_width, half_pixel);
	float axis = dot(abs(lead_direction), face_size);
	float t = 0.5 + dot(local - face_size * 0.5, lead_direction) / axis;
	vec3 lead = texture(lead_ramp, vec2(t, 0.5)).rgb;
	if (glint_colour.a > 0.0) {
		// the way round the outline, clockwise on screen from the bottom point
		vec2 c = (local - face_size * 0.5) / (face_size * 0.5);
		float way = fract((atan(c.y, c.x) - PI * 0.5) / TAU);
		float head = mod(TIME / glint.x + glint.w, 1.0) * glint.x / glint.y;
		float behind = head - way;
		float band = behind >= 0.0 ? exp(-pow(behind / glint.z, 2.0)) : exp(-pow(behind / (glint.z * 0.4), 2.0));
		band *= step(head, 1.3);
		lead += glint_colour.rgb * glint_colour.a * band;
	}
	vec3 glass = vec3(14.0, 18.0, 17.0) / 255.0;
	vec2 at = local / face_size;
	if (window > 0.0 && has_art) {
		vec2 art_at = circle ? (local - lead_width) / (face_size - 2.0 * lead_width) : at;
		vec4 picture = texture(art, crop.xy + art_at * crop.zw);
		glass = mix(glass, picture.rgb, picture.a);
	}
	if (!circle) {
		float shade = bevel_alpha.x * (1.0 - clamp(at.y / bevel_stops.x, 0.0, 1.0));
		float shine = bevel_alpha.y * clamp((at.y - bevel_stops.y) / (1.0 - bevel_stops.y), 0.0, 1.0);
		glass = mix(glass * (1.0 - shade), vec3(1.0, 240.0 / 255.0, 210.0 / 255.0), shine);
	}
	vec3 front = mix(lead, glass, window);
	float edge = coverage(outline(local - vec2(0.0, edge_offsets.x)), half_pixel);
	float line = coverage(outline(local - vec2(0.0, edge_offsets.y)), half_pixel);
	float edge_y = clamp((local.y - edge_offsets.x) / face_size.y, 0.0, 1.0);
	vec3 slab = mix(mix(edge_top.rgb, edge_bottom.rgb, edge_y), edge_line.rgb, line * edge_line.a);
	float behind = edge * (1.0 - face);
	float alpha = face + behind;
	vec3 surface = (front * face + slab * behind) / max(alpha, 0.001);
	// Limit the glint to the display range before multiplying by the card's tint.
	COLOR = tint * vec4(min(surface, vec3(1.0)), alpha);
}
