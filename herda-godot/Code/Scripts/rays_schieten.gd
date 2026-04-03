extends Camera3D

@export var target_coordinate : Vector3
@export var debug_sphere : MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var space = get_world_3d().direct_space_state
	var target_coordinates = project_ray_normal(get_viewport().get_mouse_position())
	var hit = space.intersect_ray(
		PhysicsRayQueryParameters3D.create(position, target_coordinates * 1000))
	
	if hit:
		target_coordinate = hit.position
		debug_sphere.global_position = hit.position
	
	# sphere spawnen

#func guide_sheep() -> void:
	
