shader_type spatial;
//render_mode cull_disabled;
uniform sampler2D gras_map;
uniform sampler2D random_noise;

uniform float random_noise_strength = 0.1;
uniform float gras_strength = 0.5;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// placeholder. just do greenness + noise. 
	float random_noise_value = texture(random_noise, UV.xy).x * random_noise_strength - 0.5 * random_noise_strength;
	float green = texture(gras_map, UV.xy).x * gras_strength;
	ALBEDO = vec3(0.2, green, 0.02) + random_noise_value;
}

//void light() {
	//// COMMENT THIS LATER
	//// Called for every pixel for every light affecting the material.
	//// Uncomment to replace the default light processing function with this one.
//}
