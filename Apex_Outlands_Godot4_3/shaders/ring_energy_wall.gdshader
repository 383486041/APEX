shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

uniform vec4 ring_color : source_color = vec4(1.0, 0.33, 0.0, 0.32);

void fragment() {
	float wave = sin(UV.y * 60.0 - TIME * 4.0) * 0.5 + 0.5;
	ALBEDO = ring_color.rgb * (0.8 + wave * 0.6);
	ALPHA = ring_color.a * (0.65 + wave * 0.35);
}
