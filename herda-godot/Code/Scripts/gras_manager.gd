extends Node3D
var image : Image
var white_image : Image
var graas_image : Image
var texture : ImageTexture
var gras_shader : ShaderMaterial
var time : float = 0.0
var current_delta: float = 1.0

var rng = RandomNumberGenerator.new()

@export var gras_mesh: MeshInstance3D
@export var tex_size = Vector2i(1024,1024)
@export var graas_size = Vector2i(32,32)

var img_rect = Rect2i(Vector2i.ZERO, tex_size)
var graas_rect = Rect2i(Vector2i.ZERO, tex_size)

# deze jongen spawnt gras voor de schaapjes om te chappen
# we willen dit wss met een soort texture doen die we als input voor de grond mesh shader gebruiken en die kan dan 3D gras spawnen op basis daarvan. wordt crazy
# maar voor nu kunnen we het ook gewoon als groenheids texture gebruiken ofzo.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gras_shader = gras_mesh.mesh.surface_get_material(0)
	image = gras_shader.get_shader_parameter("gras_map").noise.get_image(tex_size.x, tex_size.y)
	image.convert(Image.FORMAT_LA8)
	
	white_image = Image.create_empty(tex_size.x, tex_size.y, false, Image.FORMAT_LA8)
	white_image.fill(Color(1, 1, 1, 0.02))
	
	graas_image = Image.create_empty(graas_size.x, graas_size.y, false, Image.FORMAT_LA8)
	graas_image.fill(Color.BLACK)
	for x in range(0, graas_size.x):
		for y in range(0,graas_size.y):
			#gaussian
			var val_x = 1 / ((graas_size.x*0.1) * sqrt(2*PI)) * pow(exp(1), -0.5 * pow((float(x) - graas_size.x * 0.5)/(graas_size.x*0.1), 2)) * 6
			var val_y = 1 / ((graas_size.y*0.1) * sqrt(2*PI)) * pow(exp(1), -0.5 * pow((float(y) - graas_size.y * 0.5)/(graas_size.y*0.1), 2)) * 6
			graas_image.set_pixel(x, y, Color(0,0,0, val_x * val_y * 0.5))
	
	texture = ImageTexture.create_from_image(image)
	
	gras_shader.set_shader_parameter("gras_map", texture)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	current_delta = delta
	time += delta
	if(time > 1.0):
		time -= 1.0
		image.blend_rect(white_image, img_rect, Vector2i.ZERO)
		RenderingServer.texture_2d_update(texture.get_rid(), image, 0)

func eat_gras(world_coord: Vector3) -> void:
	#my issue is this goes too fast but im having a hard time slowing it down. this works for now.
	if(fmod(time, 0.2) > current_delta):
		return
	image.blend_rect(graas_image, graas_rect, world_to_tex_coord(world_coord) - graas_size/2)
	RenderingServer.texture_2d_update(texture.get_rid(), image, 0)

func sample_gras(world_coord: Vector3) -> float:
	var tex_coord = world_to_tex_coord(world_coord)
	return image.get_pixel(tex_coord.x, tex_coord.y).r
	
func world_to_tex_coord(world_coord: Vector3) -> Vector2i:
	var mesh_top_left = Vector2(gras_mesh.global_position.x, gras_mesh.global_position.z) - gras_mesh.mesh.size*0.5
	return Vector2(tex_size) * (Vector2(world_coord.x, world_coord.z) - mesh_top_left) / gras_mesh.mesh.size
	
