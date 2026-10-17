shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled, unshaded;

uniform vec4 shield_color : source_color = vec4(0.22, 0.74, 0.97, 0.45);
uniform float pulse_speed = 3.2;

void fragment() {
	float grid = abs(sin(UV.x * 48.0) * sin(UV.y * 48.0));
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
	float pulse = 0.65 + 0.35 * sin(TIME * pulse_speed + UV.y * 12.0);
	ALBEDO = shield_color.rgb * (rim * 1.8 + step(0.85, grid) * 0.6) * pulse;
	ALPHA = clamp((rim + step(0.85, grid) * 0.35) * shield_color.a, 0.0, 0.9);
}
