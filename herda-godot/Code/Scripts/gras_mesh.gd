@tool
extends Node3D

# so this is only responsible for rendering the 3d grass. maybe this could be part of gras_manager,
# but i get a good feeling about splitting it

@export_enum("quads", "individual meshes") var gras_mode: String
@export var grond: MeshInstance3D
@export var gras_individual_mesh: ArrayMesh
@export var gras_quad_mesh: ArrayMesh
@export var chunk_size: float = 10.0 # chunk size in m. chunks are square
@export var gras_individual_density: float = 40.0 # gras meshes spawned per meter. (10 per m -> 100 per m2)
@export var gras_quad_density: float = 6.0 # gras meshes spawned per meter. (10 per m -> 100 per m2)

var chunk_count: Vector2i
var chunks: Array = Array()
var gras_mesh: ArrayMesh
var gras_density: float
var gras_mesh_scale: float

var rng = RandomNumberGenerator.new()

func initialize_gras(texture: ImageTexture, grond_size: float, grond_shader: ShaderMaterial) -> void:
	if !visible:
		return
	
	var wind_noise = grond_shader.get_shader_parameter("wind_noise")
	
	match gras_mode:
		"individual meshes":
			gras_mesh = gras_individual_mesh
			gras_density = gras_individual_density
			gras_mesh_scale = 1.0
		"quads":
			gras_mesh = gras_quad_mesh
			gras_density = gras_quad_density
			gras_mesh_scale = 2.0
	
	# chop the terrain up into chunks and spawn some multimeshes to allow frustum culling and dynamic detail
	var gras_mat: ShaderMaterial = gras_mesh.surface_get_material(0)
	gras_mat.set_shader_parameter("gras_map", texture)
	gras_mat.set_shader_parameter("grond_size", grond_size)
	gras_mat.set_shader_parameter("inv_grond_size", 1.0 / grond_size)
	gras_mat.set_shader_parameter("wind_noise", wind_noise)
	
	var grond_bb = grond.mesh.get_aabb()
	chunk_count = Vector2i(ceil(grond_bb.size.x/chunk_size), ceil(grond_bb.size.z/chunk_size)) # chop x and z
	
	# spawn da chonks
	var amount_per_chunk = pow(chunk_size * gras_density, 2) # density should be variable based on grassiness of the texture
	
	var dist_per_gras = 1.0 / gras_density
	for x in range(chunk_count.x):
		chunks.append(Array())
		for y in range(chunk_count.y):
			var mm = MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = gras_mesh
			mm.custom_aabb = AABB(
				Vector3(grond_bb.position.x + x*chunk_size, 0, grond_bb.position.z + y*chunk_size), 
				Vector3(chunk_size, 1.0, chunk_size))
			mm.instance_count = amount_per_chunk # this is gonna fuck up the edges if bb.x % chunk_size != 0
			
			# compute shader should handle this bullshit
			for i in range(mm.instance_count):
				var mesh_basis = Basis(Vector3.UP, rng.randf_range(0.0,2*PI))
				var tx = Transform3D(mesh_basis, Vector3(
					mm.custom_aabb.position.x + fmod(i, chunk_size * gras_density) * dist_per_gras + rng.randf_range(-0.5*dist_per_gras, 0.5*dist_per_gras), 
					0.0, 
					mm.custom_aabb.position.z + floor(i/(chunk_size * gras_density)) * dist_per_gras + rng.randf_range(-0.5*dist_per_gras, 0.5*dist_per_gras)
				)).scaled_local(Vector3.ONE * gras_mesh_scale)
				mm.set_instance_transform(i, tx)

			var mm_instance = MultiMeshInstance3D.new()
			mm_instance.multimesh = mm
			add_child(mm_instance)
			#mm_instance.owner = get_tree().edited_scene_root
			
			#chunks[x].append[mm]w
