shader_type spatial;

uniform sampler2D wind_noise;
uniform sampler2D gras_map;
uniform sampler2D random_noise;

uniform float random_noise_strength = 0.1;
uniform float gras_strength = 0.5;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// placeholder. just do greenness + noise. 
	float random_noise_value = texture(random_noise, UV.xy * 40.0).x * random_noise_strength - 0.5 * random_noise_strength;
	float green = texture(gras_map, UV.xy).x * gras_strength;
	ALBEDO = vec3(0.2, green, 0.02) + random_noise_value;
}

void light() {
	DIFFUSE_LIGHT = vec3(0.8);
}
