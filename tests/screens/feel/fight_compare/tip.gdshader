// The attacker's tip for CB9 "tip" (best_timeline.gd ROTATIONS): the card's leading end tips
// away from the viewer, drawn as a true perspective keystone. Each vertex goes through the
// projection of a card tipped about its own horizontal axis (the leading edge `keystone` times
// the trailing edge's width), and the texture is sampled perspective-correct: fragment() divides
// UV x q by q, so the frame's lead lines stay straight and the art stays registered with the
// frame (plain affine sampling bends them along each triangle's diagonal; research/rotation.md).
// The shortening along the card's length is the node's scale.y, not this shader. One shader
// covers the art, the frame, the stat settings and the numbers, since it re-samples TEXTURE
// itself (plain fonts, no MSDF). The card's shadow children stay flat.
// Exploratory (ideation/fight-animation): kept beside the fixture, not used by the game.
shader_type canvas_item;

// The card's own size (GlassCard.size), in its local pixels.
uniform vec2 card_size = vec2(216.0, 250.0);
// Leading edge width / trailing edge width: 1 is flat.
uniform float keystone : hint_range(0.5, 1.0) = 1.0;
// 1: the top edge leads (tips away); -1: the bottom edge.
uniform float lead = 1.0;

varying vec2 uv_q;
varying float q;
varying vec4 tint;

void vertex() {
	vec2 c = card_size * 0.5;
	vec2 p = VERTEX - c;
	// depth share: +1 at the leading edge, -1 at the trailing edge; m = (1 - k) / (1 + k)
	float m = (1.0 - keystone) / (1.0 + keystone);
	float d = 1.0 + m * (-lead * p.y / c.y);
	VERTEX = c + p / d;
	q = 1.0 / d;
	uv_q = UV * q;
	tint = COLOR;
}

void fragment() {
	COLOR = tint * texture(TEXTURE, uv_q / q);
}
