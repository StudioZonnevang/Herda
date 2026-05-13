extends Node3D

const GRAS_MAP_PATH = "user://gras_map.png"
const HEIGHT_MAP_PATH = "user://height_map.png"
const GAUSSIAN_PATH = "user://gaussian.png"

var local_gras_image : Image
var world_height_image : Image
var world_gras_image : Image

var white_image : Image
var graas_image : Image
var gras_texture : ImageTexture
var gras_shader : ShaderMaterial
var time : float = 0.0
var current_delta: float = 1.0

@export var current_region := Rect2i(0, 0, 50, 50)

@export var grond_mesh: MeshInstance3D
@export var world_image_size = Vector2i(1024,1024)
@export var tex_size = Vector2i(1024,1024)
@export var graas_size = Vector2i(32,32)
@export var gras_mesh: Node3D
@export var bake_map: bool = false
@export var world_noise_generator: FastNoiseLite
@export var local_noise_generator: FastNoiseLite

var img_rect = Rect2i(Vector2i.ZERO, tex_size)
var graas_rect = Rect2i(Vector2i.ZERO, tex_size)

# deze jongen spawnt gras voor de schaapjes om te chappen
# we willen dit wss met een soort texture doen die we als input voor de grond mesh shader gebruiken en die kan dan 3D gras spawnen op basis daarvan. wordt crazy
# maar voor nu kunnen we het ook gewoon als groenheids waarde gebruiken ofzo.

func _ready() -> void:
	gras_shader = grond_mesh.mesh.surface_get_material(0)	
	if bake_map:
		# update: were gonna generate a height & grass texture for the whole world.
		# rn were doing ~10 px/m which is nice for a high detail world
		# i think 1 px/m is cool for the world map
		# so 1 km2 we can do a 1024 texture. that seems good. we can stitch those together if we want
		
		#were not really using the height map now, but probably it should affect the grass map
		world_height_image = world_noise_generator.get_image(world_image_size.x, world_image_size.y)
		world_height_image.convert(Image.FORMAT_LA8)
		world_height_image.save_png(HEIGHT_MAP_PATH)
		
		world_gras_image = world_noise_generator.get_image(world_image_size.x, world_image_size.y)
		world_gras_image.convert(Image.FORMAT_LA8)
		world_gras_image.save_png(GRAS_MAP_PATH)
		
		graas_image = Image.create_empty(graas_size.x, graas_size.y, false, Image.FORMAT_LA8)
		graas_image.fill(Color.BLACK)
		for x in range(0, graas_size.x):
			for y in range(0,graas_size.y):
				#gaussian
				var val_x = 1 / ((graas_size.x*0.1) * sqrt(2*PI)) * pow(exp(1), -0.5 * pow((float(x) - graas_size.x * 0.5)/(graas_size.x*0.1), 2)) * 6
				var val_y = 1 / ((graas_size.y*0.1) * sqrt(2*PI)) * pow(exp(1), -0.5 * pow((float(y) - graas_size.y * 0.5)/(graas_size.y*0.1), 2)) * 6
				graas_image.set_pixel(x, y, Color(0,0,0, val_x * val_y * 0.5))
		graas_image.save_png(GAUSSIAN_PATH)
		
		print("Baked new maps to ", GRAS_MAP_PATH, ", ", HEIGHT_MAP_PATH, " and ", GAUSSIAN_PATH)
		
	else:
		world_gras_image = Image.new()
		world_height_image = Image.new()
		graas_image = Image.new()
		world_gras_image.load(GRAS_MAP_PATH)
		world_height_image.load(HEIGHT_MAP_PATH)
		graas_image.load(GAUSSIAN_PATH)
	
	var gras_map_region = world_gras_image.get_region(current_region)
	apply_alpha_to_image(gras_map_region, 0.75)
	gras_map_region.resize(tex_size.x, tex_size.y, 2)
	var height_map_region = world_height_image.get_region(current_region) # maybe use this to hard offset the ground vertices idk
	
	# take noise map as base image
	#local_gras_image = Image.create_empty(tex_size.x, tex_size.y, false, Image.FORMAT_LA8)
	local_gras_image = local_noise_generator.get_image(tex_size.x, tex_size.y)
	local_gras_image.convert(Image.FORMAT_LA8)
	#local_gras_image.blend_rect(local_noise_generator.get_image(tex_size.x, tex_size.y), img_rect, Vector2i.ZERO)
	local_gras_image.blend_rect(gras_map_region, img_rect, Vector2i.ZERO)
	
	white_image = Image.create_empty(tex_size.x, tex_size.y, false, Image.FORMAT_LA8)
	white_image.fill(Color(1, 1, 1, 0.02))
	
	gras_texture = ImageTexture.create_from_image(local_gras_image)
	gras_shader.set_shader_parameter("gras_map", gras_texture)
	gras_mesh.initialize_gras(gras_texture, grond_mesh.mesh.get_aabb().size.x, gras_shader)
	RenderingServer.texture_2d_update(gras_texture.get_rid(), local_gras_image, 0)

func _process(delta: float) -> void:
	current_delta = delta
	time += delta
	if(time > 1.0):
		time -= 1.0
		# dit is om gras automatisch terug te laten groeien
		#image.blend_rect(white_image, img_rect, Vector2i.ZERO)
		#RenderingServer.texture_2d_update(texture.get_rid(), image, 0)

func apply_alpha_to_image(img: Image, alpha: float) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c = img.get_pixel(x, y)
			c.a = alpha
			img.set_pixel(x, y, c)

func eat_gras(world_coord: Vector3) -> void:
	# my issue is this goes too fast but im having a hard time slowing it down. this works for now.
	#if(fmod(time, 0.2) > current_delta):
		#return
	local_gras_image.blend_rect(graas_image, graas_rect, world_to_tex_coord(world_coord) - Vector2i(graas_size/2.0))
	RenderingServer.texture_2d_update(gras_texture.get_rid(), local_gras_image, 0)

func override_pixel(world_coord: Vector3) -> void:
	var tex_coord = world_to_tex_coord(world_coord)
	if(tex_coord.x < 0 or tex_coord.x > local_gras_image.get_width() or tex_coord.y < 0 or tex_coord.y > local_gras_image.get_height()):
		return
	local_gras_image.set_pixel(tex_coord.x, tex_coord.y, Color(0,0,0,1)) #outside navigatie gebied

func sample_gras(world_coord: Vector3) -> float:
	var tex_coord = world_to_tex_coord(world_coord)
	if(tex_coord.x < 0 or tex_coord.x > local_gras_image.get_width() or tex_coord.y < 0 or tex_coord.y > local_gras_image.get_height()):
		return 0.0
	return local_gras_image.get_pixel(tex_coord.x, tex_coord.y).r
	
func world_to_tex_coord(world_coord: Vector3) -> Vector2i:
	var mesh_top_left = Vector2(grond_mesh.global_position.x, grond_mesh.global_position.z) - grond_mesh.mesh.size*0.5
	return Vector2(tex_size) * (Vector2(world_coord.x, world_coord.z) - mesh_top_left) / grond_mesh.mesh.size

func tex_to_world_coord(tex_coord: Vector2i) -> Vector3:
	var mesh_top_left = Vector2(grond_mesh.global_position.x, grond_mesh.global_position.z) - grond_mesh.mesh.size*0.5
	var world_coord_v2 = mesh_top_left + (Vector2(tex_coord) / Vector2(tex_size)) * grond_mesh.mesh.size
	return Vector3(world_coord_v2.x, 0, world_coord_v2.y)
	
