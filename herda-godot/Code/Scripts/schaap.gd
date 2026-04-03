extends Node3D

@export var show_debug_material : bool = true 
@export var cam: Camera3D

@onready var body : MeshInstance3D = find_child("Body")

### Schaap movement ###
var speed : float
@export var max_speed : float = 30
@export var turn_speed : float = 6

var separation : float #=high when high hunger, low speed
var alignment : float #=high when high energy, low hunger, high speed
var cohesion : float #=high when large distance, high speed

### Schaap behoeftes ###
var behoefte_voeding : float
var behoefte_persoonlijke_ruimte : float
var behoefte_gezelligheid : float

### Schaap eigenschap ###
enum kudde_staat {bewegend, rust}
enum sekse {jonge_ooi, volwassen_ooi, jonge_ram, volwassen_ram}
var waargenomen_kudde_staat = kudde_staat.rust
var gebroken : bool
var wolligheid : float
var pensvolheid : float
var eigen_sekse
var ziektes = []

### Schapen array
@onready var alle_schapen = get_parent().get_children()
var waargenomen_schapen = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	update_waargenomen_schapen()
	
	# behoeftes updaten
	update_behoefte_voeding()
	update_behoefte_persoonlijke_ruimte()
	update_behoefte_gezelligheid()
	
	# FOR DEBUGGING
	behoefte_persoonlijke_ruimte = 1.0
	
	match [behoefte_voeding, behoefte_persoonlijke_ruimte, behoefte_gezelligheid].max() : 
		behoefte_voeding : voeding_logica()
		behoefte_persoonlijke_ruimte : persoonlijke_ruimte_logica()
		behoefte_gezelligheid : gezelligheid_logica()

# welke schapen neemt het schaap waar. hoeft mss niet elk frame.
func update_waargenomen_schapen() -> void:
	waargenomen_schapen = []
	var space = get_world_3d().direct_space_state
	for schaap in alle_schapen:
		#near 360 degree vision so no view cone.
		if schaap == self: continue
		
		var target_coordinates = schaap.global_position
		var hit = space.intersect_ray(
			PhysicsRayQueryParameters3D.create(global_position, target_coordinates))
		if !hit or hit.collider == schaap:
			waargenomen_schapen.append(schaap)

# bepaald de dringendheid van de behoefte
func update_behoefte_voeding() -> void:
	pass

func update_behoefte_persoonlijke_ruimte() -> void:
	var irritatiebronnen = []

func update_behoefte_gezelligheid() -> void:
	pass

# bepaald de manier waarop de behoefte vervuld wordt
func voeding_logica() -> void:
	pass

func persoonlijke_ruimte_logica() -> void:
	pass

func gezelligheid_logica() -> void:
	pass

### Utilities ###

func calculate_speed() -> float:
	# takes group speed 
	var new_speed : float = speed + 0.01
	new_speed = clampf(new_speed, 0, max_speed)
	return new_speed

func schaap_verplaatsen(direction) -> void:
	# We need speed, direction, correct orientation
	return

func schaap_orienteren(target : Vector3, delta : float) -> void: 
	var vector_to_target = target - global_position
	var angle_to_target = Vector2(vector_to_target.x, vector_to_target.z).angle() + 0.5*PI
	var atc =  -angle_to_target - global_rotation.y#deg_to_rad(direction.y)
	if abs(atc) > PI: atc = atc + (2*PI if atc < 0 else -2*PI)
	rotation.y += atc * turn_speed * delta
	print(atc)

func schaap_kleuren(measured_variable, max_variable = 1) -> void:
	var material = body.get_active_material(0)
	var debug_red_value = remap(measured_variable, 0, max_variable, 0, 1)
	material.albedo_color = Color(debug_red_value, 0.5, 0.5)
	body.set_surface_override_material(0, material)
