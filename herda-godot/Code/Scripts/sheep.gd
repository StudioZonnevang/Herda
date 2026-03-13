extends Node3D

@export var show_debug_material : bool = true 

@onready var body : MeshInstance3D = find_child("Body")

var speed : float
var max_speed : float = 30
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
		debug_colouring()
	pass

func debug_colouring() -> void:
	var material = body.get_active_material(0)
	# red corresponds with speed
	var debug_red_value = remap(speed, 0, max_speed, 0, 1)
	material.albedo_color = Color(debug_red_value, 0.5, 0.5)
	body.set_surface_override_material(0, material)
