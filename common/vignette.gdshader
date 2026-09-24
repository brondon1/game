shader_type canvas_item;
// 屏幕四周压暗，让视线集中在中间。

uniform float strength : hint_range(0.0, 1.0) = 0.6;
uniform vec4 tint : source_color = vec4(0.03, 0.02, 0.07, 1.0);

void fragment() {
	vec2 uv = UV - 0.5;
	float d = length(uv * vec2(1.0, 0.85));
	COLOR = vec4(tint.rgb, smoothstep(0.32, 0.78, d) * strength);
}
