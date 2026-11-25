// A CSS box as the mock-ups' stage.css draws one, for GlassBox: a rounded rectangle (a circle when
// its radii are half its size) or a convex polygon, a solid border, up to three background layers
// (a radial gradient on top, an image, and a colour or a second radial gradient at the bottom, the
// image blended normally or with multiply), an inset ring and up to three outer box-shadows.
// Positions are in the box's own pixels, its border box starting at (0, 0).
shader_type canvas_item;

const int MAX_STOPS = 10;
const int MAX_POLY = 8;
const int MAX_SHADOWS = 3;

uniform vec2 box_size = vec2(100.0);
// 0: rounded rectangle with corner radii (top left, top right, bottom right, bottom left); 1: polygon
uniform int shape = 0;
uniform vec4 radii = vec4(0.0);
uniform int poly_count = 0;
uniform vec2 poly_outer[MAX_POLY];
uniform vec2 poly_inner[MAX_POLY];
// the padding box, inside the border; the background's gradients and image are placed in it
uniform vec4 padding_rect = vec4(0.0, 0.0, 100.0, 100.0);
uniform float border_width = 0.0;
uniform vec4 border_colour : source_color = vec4(0.0);

uniform bool has_top = false;
uniform vec2 top_centre = vec2(0.0);
uniform vec2 top_radii = vec2(1.0);
uniform int top_count = 0;
uniform vec4 top_colours[MAX_STOPS];
uniform float top_stops[MAX_STOPS];

uniform bool has_image = false;
uniform sampler2D image : source_color, repeat_enable, filter_linear_mipmap;
uniform vec4 image_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform bool image_multiply = false;
uniform bool image_grayscale = false;

uniform vec4 base_colour : source_color = vec4(0.0);
uniform bool has_bottom = false;
uniform vec2 bottom_centre = vec2(0.0);
uniform vec2 bottom_radii = vec2(1.0);
uniform int bottom_count = 0;
uniform vec4 bottom_colours[MAX_STOPS];
uniform float bottom_stops[MAX_STOPS];

uniform float inset_spread = 0.0;
uniform vec4 inset_colour : source_color = vec4(0.0);

uniform int shadow_count = 0;
// x, y, blur, spread
uniform vec4 shadow_geom[MAX_SHADOWS];
uniform vec4 shadow_colours[MAX_SHADOWS] : source_color;

varying vec2 local;

void vertex() {
	local = VERTEX;
}

float sd_round_box(vec2 p, vec2 half_size, vec4 r) {
	// r: top left, top right, bottom right, bottom left
	float rad = p.x < 0.0 ? (p.y < 0.0 ? r.x : r.w) : (p.y < 0.0 ? r.y : r.z);
	rad = min(rad, min(half_size.x, half_size.y));
	vec2 q = abs(p) - half_size + vec2(rad);
	return min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0))) - rad;
}

float sd_poly(vec2 p, bool inner) {
	float d = -1e9;
	for (int i = 0; i < MAX_POLY; i++) {
		if (i >= poly_count) {
			break;
		}
		vec2 a = inner ? poly_inner[i] : poly_outer[i];
		vec2 b = inner ? poly_inner[(i + 1) % poly_count] : poly_outer[(i + 1) % poly_count];
		vec2 e = normalize(b - a);
		// clockwise in screen space (y down): the outside is to the left of each edge
		vec2 n = vec2(e.y, -e.x);
		d = max(d, dot(p - a, n));
	}
	return d;
}

float sd_outer(vec2 p) {
	if (shape == 1) {
		return sd_poly(p, false);
	}
	return sd_round_box(p - box_size / 2.0, box_size / 2.0, radii);
}

float sd_inner(vec2 p) {
	if (shape == 1) {
		return sd_poly(p, true);
	}
	vec2 half_pad = padding_rect.zw / 2.0;
	vec4 r = max(radii - vec4(border_width), vec4(0.0));
	return sd_round_box(p - padding_rect.xy - half_pad, half_pad, r);
}

vec4 over(vec4 top, vec4 bottom) {
	// non-premultiplied source-over
	float a = top.a + bottom.a * (1.0 - top.a);
	if (a <= 0.0) {
		return vec4(0.0);
	}
	vec3 c = (top.rgb * top.a + bottom.rgb * bottom.a * (1.0 - top.a)) / a;
	return vec4(c, a);
}

vec4 premul_mix(vec4 a, vec4 b, float f) {
	// CSS interpolates gradient colours with premultiplied alpha
	vec4 m = mix(vec4(a.rgb * a.a, a.a), vec4(b.rgb * b.a, b.a), f);
	return m.a > 0.0 ? vec4(m.rgb / m.a, m.a) : vec4(0.0);
}

vec4 ramp_top(float t) {
	if (t <= top_stops[0]) {
		return top_colours[0];
	}
	for (int i = 1; i < MAX_STOPS; i++) {
		if (i >= top_count) {
			break;
		}
		if (t <= top_stops[i]) {
			float span = top_stops[i] - top_stops[i - 1];
			return premul_mix(top_colours[i - 1], top_colours[i], span > 0.0 ? (t - top_stops[i - 1]) / span : 1.0);
		}
	}
	return top_colours[top_count - 1];
}

vec4 ramp_bottom(float t) {
	if (t <= bottom_stops[0]) {
		return bottom_colours[0];
	}
	for (int i = 1; i < MAX_STOPS; i++) {
		if (i >= bottom_count) {
			break;
		}
		if (t <= bottom_stops[i]) {
			float span = bottom_stops[i] - bottom_stops[i - 1];
			return premul_mix(
				bottom_colours[i - 1], bottom_colours[i], span > 0.0 ? (t - bottom_stops[i - 1]) / span : 1.0
			);
		}
	}
	return bottom_colours[bottom_count - 1];
}

float coverage(float sd) {
	return clamp(0.5 - sd, 0.0, 1.0);
}

float erf_approx(float x) {
	// Winitzki's approximation, within 2e-4
	float x2 = x * x;
	float a = 0.147;
	return sign(x) * sqrt(1.0 - exp(-x2 * (1.2732395 + a * x2) / (1.0 + a * x2)));
}

// A Gaussian-blurred edge: the share of the shape at signed distance d, for standard deviation sigma.
float soft(float d, float sigma) {
	if (sigma <= 0.0) {
		return coverage(d);
	}
	return 0.5 - 0.5 * erf_approx(d / (sigma * 1.4142136));
}

void fragment() {
	vec2 p = local;
	float outer = sd_outer(p);
	vec4 colour = vec4(0.0);

	// the box itself
	if (outer < 1.0) {
		vec4 bg = base_colour;
		if (has_bottom) {
			bg = ramp_bottom(length((p - bottom_centre) / bottom_radii));
		}
		if (has_image) {
			vec4 img = texture(image, (p - image_rect.xy) / image_rect.zw);
			if (image_grayscale) {
				img.rgb = vec3(dot(img.rgb, vec3(0.2126, 0.7152, 0.0722)));
			}
			if (image_multiply) {
				bg = vec4(mix(bg.rgb, bg.rgb * img.rgb, img.a * bg.a) + img.rgb * img.a * (1.0 - bg.a), max(bg.a, img.a));
			} else {
				bg = over(img, bg);
			}
		}
		if (has_top) {
			bg = over(ramp_top(length((p - top_centre) / top_radii)), bg);
		}
		float inner = sd_inner(p);
		if (inset_spread > 0.0) {
			bg = over(vec4(inset_colour.rgb, inset_colour.a * clamp(inner + inset_spread + 0.5, 0.0, 1.0)), bg);
		}
		vec4 border = border_colour;
		border.a *= clamp(inner + 0.5, 0.0, 1.0);
		if (border_width <= 0.0 && shape == 0) {
			border.a = 0.0;
		}
		colour = over(border, bg);
		colour.a *= coverage(outer);
	}

	// outer shadows, under the box; the first listed is on top
	vec4 shadow = vec4(0.0);
	for (int i = MAX_SHADOWS - 1; i >= 0; i--) {
		if (i >= shadow_count) {
			continue;
		}
		vec4 g = shadow_geom[i];
		float d = sd_outer(p - g.xy) - g.w;
		vec4 s = shadow_colours[i];
		s.a *= soft(d, g.z / 2.0);
		shadow = over(s, shadow);
	}
	// COLOR comes in as the vertex colour times the node's modulate: keep it, so a box can be dimmed
	COLOR = over(colour, shadow) * COLOR;
}
