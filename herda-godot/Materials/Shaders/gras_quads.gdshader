shader_type spatial;
render_mode world_vertex_coords;
render_mode cull_disabled;
render_mode depth_prepass_alpha;

uniform sampler2D gras_map;
uniform sampler2D gras_quads_texture;
uniform sampler2D wind_noise;
uniform float gras_strength = 0.75;
uniform float grond_size;
uniform float inv_grond_size;

varying vec3 world_pos;
varying float tex_val;
varying float wind_effect;

void vertex() {
	// little wind and height effect
	tex_val = texture(gras_map, (VERTEX.xz + grond_size * 0.5) * inv_grond_size).x;
	world_pos = VERTEX;
	world_pos.y = VERTEX.y - 0.4 + tex_val * 0.5;
	
	// should try to optimize here. throw away triangles below the surface
	
	wind_effect = texture(wind_noise, (VERTEX.xz + grond_size * 0.5) * inv_grond_size + TIME*0.03).r;
	VERTEX.x += (0.5 - wind_effect) * world_pos.y;
	VERTEX.z += world_pos.y * (0.5 - texture(wind_noise, (VERTEX.xz + grond_size * 0.2) * inv_grond_size + TIME*0.043).r);
	VERTEX.y = world_pos.y;
}

void fragment() {
	vec4 sample_tex = texture(gras_quads_texture, UV);
	ALBEDO = (vec3(0.2, tex_val * gras_strength, 0.02) + world_pos.y * 0.5) * (0.5 + 0.5 * sample_tex.r);
	// im fading them out if they align too much with the camera.
	ALPHA = sample_tex.a * (0.4 + 0.6 * smoothstep(0.1, 0.5, length(normalize(CAMERA_POSITION_WORLD - world_pos) + vec3(0.0,-1.0,0.0))));
}

void light() {
	DIFFUSE_LIGHT = vec3(0.5 + 0.5 * wind_effect);
}
