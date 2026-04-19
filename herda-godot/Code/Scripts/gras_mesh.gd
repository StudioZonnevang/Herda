@tool
extends Node3D

# so this is only responsible for rendering the 3d grass. maybe this could be part of gras_manager,
# but i get a good feeling about splitting it
 
@export var grond: MeshInstance3D
@export var gras_mesh: ArrayMesh
@export var chunk_size: float = 10.0 # chunk size in m. chunks are square
@export var gras_density: float = 10.0 # gras meshes spawned per meter. (10 per m -> 100 per m2)

var chunk_count: Vector2i
var chunks: Array = Array()

var rng = RandomNumberGenerator.new()

func initialize_gras(texture: ImageTexture, grond_size: float) -> void:
	if !visible:
		return
	# chop the terrain up into chunks and spawn some multimeshes to allow frustum culling and dynamic detail
	var gras_mat: ShaderMaterial = gras_mesh.surface_get_material(0)
	gras_mat.set_shader_parameter("gras_map", texture)
	gras_mat.set_shader_parameter("grond_size", grond_size)
	gras_mat.set_shader_parameter("inv_grond_size", 1.0 / grond_size)
	
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
				var basis = Basis(Vector3.UP, rng.randf_range(0.0,2*PI))
				var tx = Transform3D(basis, Vector3(
					mm.custom_aabb.position.x + fmod(i, chunk_size * gras_density) * dist_per_gras + rng.randf_range(-0.5*dist_per_gras, 0.5*dist_per_gras), 
					0.0, 
					mm.custom_aabb.position.z + floor(i/(chunk_size * gras_density)) * dist_per_gras + rng.randf_range(-0.5*dist_per_gras, 0.5*dist_per_gras)
				))
				mm.set_instance_transform(i, tx)

			var mm_instance = MultiMeshInstance3D.new()
			mm_instance.multimesh = mm
			add_child(mm_instance)
			#mm_instance.owner = get_tree().edited_scene_root
			
			#chunks[x].append[mm]w
