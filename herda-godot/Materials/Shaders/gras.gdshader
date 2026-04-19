shader_type spatial;
render_mode world_vertex_coords;

uniform sampler2D gras_map;
uniform float gras_strength = 0.5;
uniform float grond_size;
uniform float inv_grond_size;

varying float world_y;
varying float tex_val;

void vertex() {
	// little wind and height effect
	tex_val = texture(gras_map, (VERTEX.xz + grond_size * 0.5) * inv_grond_size).x;
	//tex_val = texture(gras_map, (VERTEX.xz + 100.0) * 0.005).x;
	world_y = VERTEX.y - (0.25 - tex_val * 0.35);
	
	// should try to optimize here. throw away triangles below the surface
	
	VERTEX.x += sin(TIME + 0.1 * VERTEX.x + 0.25 * VERTEX.z) * world_y * 0.1;
	VERTEX.y = world_y;
}

void fragment() {
	ALBEDO = vec3(0.2, tex_val * gras_strength, 0.02) + world_y;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
