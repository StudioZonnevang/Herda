extends Camera3D

@export var target_coordinate : Vector3
@export var debug_sphere : MeshInstance3D
@export var gras_manager:Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var motion = Input.get_axis("walk backwards", "walk forward")
	if motion != 0:
		position = position.rotated(Vector3.BACK, motion * 2.0 * delta)
		look_at(Vector3.ZERO)
	
	var space = get_world_3d().direct_space_state
	var target_coordinates = project_ray_normal(get_viewport().get_mouse_position())
	var hit = space.intersect_ray(
		PhysicsRayQueryParameters3D.create(position, target_coordinates * 1000))
	
	if hit:
		target_coordinate = hit.position
		debug_sphere.global_position = hit.position
	if hit and Input.is_action_pressed("nudge"):
		gras_manager.eat_gras(hit.position)
