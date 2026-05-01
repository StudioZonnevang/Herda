
extends Node3D

const GRAS_MAP_PATH = "user://gras_map.png"
const GAUSSIAN_PATH = "user://gaussian.png"

var image : Image
var white_image : Image
var graas_image : Image
var texture : ImageTexture
var gras_shader : ShaderMaterial
var time : float = 0.0
var current_delta: float = 1.0

@export var grond_mesh: MeshInstance3D
@export var tex_size = Vector2i(1024,1024)
@export var graas_size = Vector2i(32,32)
@export var gras_mesh: Node3D
@export var bake_map: bool = false

var img_rect = Rect2i(Vector2i.ZERO, tex_size)
var graas_rect = Rect2i(Vector2i.ZERO, tex_size)

# deze jongen spawnt gras voor de schaapjes om te chappen
# we willen dit wss met een soort texture doen die we als input voor de grond mesh shader gebruiken en die kan dan 3D gras spawnen op basis daarvan. wordt crazy
# maar voor nu kunnen we het ook gewoon als groenheids waarde gebruiken ofzo.

func _ready() -> void:
	gras_shader = grond_mesh.mesh.surface_get_material(0)
	
	if bake_map:
		# take noise map as base image
		image = gras_shader.get_shader_parameter("gras_map").noise.get_image(tex_size.x, tex_size.y)
		image.convert(Image.FORMAT_LA8)
		call_deferred("purge_grass")
		
		graas_image = Image.create_empty(graas_size.x, graas_size.y, false, Image.FORMAT_LA8)
		graas_image.fill(Color.BLACK)
		for x in range(0, graas_size.x):
			for y in range(0,graas_size.y):
				#gaussian
				var val_x = 1 / ((graas_size.x*0.1) * sqrt(2*PI)) * pow(exp(1), -0.5 * pow((float(x) - graas_size.x * 0.5)/(graas_size.x*0.1), 2)) * 6
				var val_y = 1 / ((graas_size.y*0.1) * sqrt(2*PI)) * pow(exp(1), -0.5 * pow((float(y) - graas_size.y * 0.5)/(graas_size.y*0.1), 2)) * 6
				graas_image.set_pixel(x, y, Color(0,0,0, val_x * val_y * 0.5))
		graas_image.save_png(GAUSSIAN_PATH)
		
		print("Baked new maps to ", GRAS_MAP_PATH, " and ", GAUSSIAN_PATH)
	
	else:
		image = Image.new()
		graas_image = Image.new()
		image.load(GRAS_MAP_PATH)
		graas_image.load(GAUSSIAN_PATH)
	
	white_image = Image.create_empty(tex_size.x, tex_size.y, false, Image.FORMAT_LA8)
	white_image.fill(Color(1, 1, 1, 0.02))
	
	texture = ImageTexture.create_from_image(image)
	gras_shader.set_shader_parameter("gras_map", texture)
	gras_mesh.initialize_gras(texture, grond_mesh.mesh.get_aabb().size.x, gras_shader)
	

func _process(delta: float) -> void:
	current_delta = delta
	time += delta
	if(time > 1.0):
		time -= 1.0
		# dit is om gras automatisch terug te laten groeien
		#image.blend_rect(white_image, img_rect, Vector2i.ZERO)
		#RenderingServer.texture_2d_update(texture.get_rid(), image, 0)

func purge_grass() -> void:
	#eradicate all unreachable areas:
	var space = get_world_3d().direct_space_state
	for x in range(0, tex_size.x):
		for y in range(0,tex_size.y):
			var coord = tex_to_world_coord(Vector2i(x,y))
			if coord.x > 25 or coord.z > 25 or coord.x < -25 or coord.z < -25:
				image.set_pixel(x, y, Color(0,0,0,1)) #outside navigatie gebiedsw
			var hit = space.intersect_ray(
				PhysicsRayQueryParameters3D.create(coord + Vector3.UP * 100, coord + Vector3.DOWN * 100))
			if hit and hit.collider.name != "grond" and !hit.collider.name.begins_with("Schaap"):
				image.set_pixel(x, y, Color(0,0,0,1))
	RenderingServer.texture_2d_update(texture.get_rid(), image, 0)
	image.save_png(GRAS_MAP_PATH)

func eat_gras(world_coord: Vector3) -> void:
	# my issue is this goes too fast but im having a hard time slowing it down. this works for now.
	#if(fmod(time, 0.2) > current_delta):
		#return
	image.blend_rect(graas_image, graas_rect, world_to_tex_coord(world_coord) - Vector2i(graas_size/2.0))
	RenderingServer.texture_2d_update(texture.get_rid(), image, 0)

func sample_gras(world_coord: Vector3) -> float:
	var tex_coord = world_to_tex_coord(world_coord)
	return image.get_pixel(tex_coord.x, tex_coord.y).r
	
func world_to_tex_coord(world_coord: Vector3) -> Vector2i:
	var mesh_top_left = Vector2(grond_mesh.global_position.x, grond_mesh.global_position.z) - grond_mesh.mesh.size*0.5
	return Vector2(tex_size) * (Vector2(world_coord.x, world_coord.z) - mesh_top_left) / grond_mesh.mesh.size

func tex_to_world_coord(tex_coord: Vector2i) -> Vector3:
	var mesh_top_left = Vector2(grond_mesh.global_position.x, grond_mesh.global_position.z) - grond_mesh.mesh.size*0.5
	var world_coord_v2 = mesh_top_left + (Vector2(tex_coord) / Vector2(tex_size)) * grond_mesh.mesh.size
	return Vector3(world_coord_v2.x, 0, world_coord_v2.y)
	
