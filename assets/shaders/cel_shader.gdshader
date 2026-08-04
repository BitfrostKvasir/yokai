// Complete Cel Shader for Godot 4
// Flat-shaded toon look with hard shadow steps and ink outline.
shader_type spatial;
render_mode cull_back, diffuse_toon, specular_toon;

uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_texture = false;

uniform float cel_steps : hint_range(1.0, 8.0, 1.0) = 3.0;
uniform float specular_shininess : hint_range(0.0, 256.0) = 32.0;
uniform vec4 shadow_color : source_color = vec4(0.2, 0.2, 0.35, 1.0);

uniform float outline_width : hint_range(0.0, 10.0) = 1.5;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float rim_width : hint_range(0.0, 1.0) = 0.0;
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

varying vec3 v_world_normal;
varying vec3 v_world_vertex;

void vertex() {
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Outline pass: push vertices along normals in clip space
	if (outline_width > 0.0) {
		vec4 clip_pos = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
		vec3 clip_normal = normalize((PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
		clip_pos.xy += clip_normal.xy * outline_width * 0.001 * clip_pos.w;
		POSITION = clip_pos;
	}
}

void fragment() {
	vec4 base_color = albedo;
	if (use_texture) {
		base_color *= texture(texture_albedo, UV);
	}

	// Stepped diffuse (cel shading)
	float ndotl = max(dot(v_world_normal, normalize(vec3(0.5, 1.0, 0.3))), 0.0);
	float stepped = floor(ndotl * cel_steps) / cel_steps;
	vec3 lit = mix(shadow_color.rgb, base_color.rgb, stepped);

	// Rim lighting (optional)
	vec3 view_dir = normalize(CAMERA_POSITION_WORLD - v_world_vertex);
	float rim = 1.0 - max(dot(view_dir, v_world_normal), 0.0);
	rim = pow(rim, 3.0);
	lit = mix(lit, rim_color.rgb, rim * rim_width);

	ALBEDO = lit;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
