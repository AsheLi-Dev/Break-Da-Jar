shader_type canvas_item;

uniform float pixel_size : hint_range(1.0, 8.0, 1.0) = 3.0;
uniform float color_steps : hint_range(2.0, 12.0, 1.0) = 6.0;
uniform float saturation : hint_range(0.0, 1.5, 0.01) = 0.62;
uniform float brightness : hint_range(0.2, 1.5, 0.01) = 0.78;
uniform float contrast : hint_range(0.5, 2.0, 0.01) = 1.14;
uniform float outline_strength : hint_range(0.0, 1.0, 0.01) = 0.45;
uniform vec4 outline_color : source_color = vec4(0.07, 0.045, 0.025, 1.0);


vec3 adjust_saturation(vec3 color, float amount) {
	float luminance = dot(color, vec3(0.299, 0.587, 0.114));
	return mix(vec3(luminance), color, amount);
}


void fragment() {
	vec2 texel_size = TEXTURE_PIXEL_SIZE * pixel_size;
	vec2 pixel_uv = (floor(UV / texel_size) + vec2(0.5)) * texel_size;
	vec4 color = texture(TEXTURE, pixel_uv);

	vec3 graded = adjust_saturation(color.rgb, saturation);
	graded = (graded - vec3(0.5)) * contrast + vec3(0.5);
	graded *= brightness;
	graded = floor(clamp(graded, vec3(0.0), vec3(1.0)) * color_steps) / color_steps;

	float neighbor_alpha = 0.0;
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, pixel_uv + vec2(texel_size.x, 0.0)).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, pixel_uv + vec2(-texel_size.x, 0.0)).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, pixel_uv + vec2(0.0, texel_size.y)).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, pixel_uv + vec2(0.0, -texel_size.y)).a);
	float outline_alpha = max(neighbor_alpha - color.a, 0.0) * outline_strength;

	vec4 filtered = vec4(graded, color.a);
	COLOR = mix(filtered, outline_color, outline_alpha);
	COLOR.a = max(color.a, outline_alpha * outline_color.a);
}
