extends Node3D

@export var show_debug_material : bool = true 
@export var cam: Camera3D

@onready var body : MeshInstance3D = find_child("Body")

var speed : float
@export var max_speed : float = 30
@export var TURN_SPEED : float = 6

var separation : float #=high when high hunger, low speed
var alignment : float #=high when high energy, low hunger, high speed
var cohesion : float #=high when large distance, high speed

var energy : float
var hunger : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	speed += 0.01
	if (show_debug_material):
		colour_sheep(speed, max_speed)
		orient_sheep(Vector3(20,20,20), delta)
	pass

func calculate_speed() -> float:
	# takes group speed 
	var new_speed : float = speed + 0.01
	new_speed = clampf(new_speed, 0, max_speed)
	return new_speed

func move_sheep() -> void:
	# We need speed, direction, correct orientation
	return

func calculate_new_orientation(direction) -> float:
	# take direction 
	# take current orientation
	# calculate difference = target
	var target_rotation : float = 180
	return target_rotation

func orient_sheep(direction, delta) -> void:
	# We need the current orientation and target orientation
	# get_parent_node_3d().rotation.y = lerp(0, 180, delta * 0.2)
	
	var vector_to_target = cam.target_coordinate - global_position
	var angle_to_target = Vector2(vector_to_target.x, vector_to_target.z).angle() + 0.5*PI
	var atc =  -angle_to_target - global_rotation.y#deg_to_rad(direction.y)
	if abs(atc) > PI: atc = atc + (2*PI if atc < 0 else -2*PI)
	rotation.y += atc * TURN_SPEED * delta
	print(atc)

func colour_sheep(measured_variable, max_variable = 1) -> void:
	var material = body.get_active_material(0)
	# red corresponds with speed
	var debug_red_value = remap(measured_variable, 0, max_variable, 0, 1)
	material.albedo_color = Color(debug_red_value, 0.5, 0.5)
	body.set_surface_override_material(0, material)
