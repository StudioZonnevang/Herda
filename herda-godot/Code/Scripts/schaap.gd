class_name schaap
extends Node3D

@export var herder_scene: Node3D
@export var show_debug_material : bool = true 
@export var cam: Camera3D

@onready var body : MeshInstance3D = find_child("Body")

### Schaap movement ###
var speed : float
@export var max_speed : float = 30
@export var turn_speed : float = 1

@export var behoefte_persoonlijke_ruimte_falloff: float = 0.5
@export var irritatie_afstanden = {
	"herder_rust": 6,
	"herder_lopend": 5,
	"schaap_rust": 3,
	"schaap_lopend": 1
}

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
var mijn_herder: CharacterBody3D
var waargenomen_schapen = []
var irritatiebronnen = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if(herder_scene != null):
		mijn_herder = herder_scene.find_child("herder")
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	update_waargenomen_schapen()
	
	# behoeftes updaten
	update_behoefte_voeding()
	update_behoefte_persoonlijke_ruimte()
	update_behoefte_gezelligheid()
	
	match [behoefte_voeding, behoefte_persoonlijke_ruimte, behoefte_gezelligheid].max() : 
		behoefte_voeding : voeding_logica()
		behoefte_persoonlijke_ruimte : persoonlijke_ruimte_logica(delta)
		behoefte_gezelligheid : gezelligheid_logica()

# welke schapen neemt het schaap waar. hoeft mss niet elk frame.
func update_waargenomen_schapen() -> void:
	waargenomen_schapen = []
	var space = get_world_3d().direct_space_state
	for schaapje in alle_schapen:
		#near 360 degree vision so no view cone.
		if schaapje == self: continue
		
		var target_coordinates = schaapje.global_position
		var hit = space.intersect_ray(
			PhysicsRayQueryParameters3D.create(global_position, target_coordinates))
		if !hit or hit.collider == schaapje:
			waargenomen_schapen.append(schaapje)

# bepaald de dringendheid van de behoefte
func update_behoefte_voeding() -> void:
	pass

func update_behoefte_persoonlijke_ruimte() -> void:
	irritatiebronnen = []
	var bronnen_totaal = waargenomen_schapen
	if mijn_herder != null: bronnen_totaal += [mijn_herder]
	var irritatie_totaal = 0
	for irritatiebron in bronnen_totaal:
		var irritatie = get_irritatie(irritatiebron)
		if irritatie == 0: continue
		irritatiebronnen.append({"bron": irritatiebron, "irritatie": irritatie})
		irritatie_totaal += irritatie
	behoefte_persoonlijke_ruimte = 1 - 1 / sqrt(behoefte_persoonlijke_ruimte_falloff * irritatie_totaal + 1)

func update_behoefte_gezelligheid() -> void:
	pass

# bepaald de manier waarop de behoefte vervuld wordt
func voeding_logica() -> void:
	pass

func persoonlijke_ruimte_logica(delta) -> void:
	var run_direction = Vector2(0,0)
	for irritatiebron in irritatiebronnen:
		var dir = (global_position - irritatiebron.bron.global_position) * irritatiebron.irritatie
		run_direction += Vector2(dir.x, dir.z)
	run_direction = run_direction.normalized()
	
	# this can then feed into the verplaatsing function which also looks at other movement goals.
	# for now im just making them turn straight away and run
	
	schaap_orienteren(global_position + Vector3(run_direction.x, 0, run_direction.y), delta)
	schaap_verplaatsen(delta)

func gezelligheid_logica() -> void:
	pass

### Utilities ###

func get_irritatie(irritatiebron) -> float:
	var afstand = global_position.distance_squared_to(irritatiebron.global_position)
	var irritatie_afstand = irritatie_afstanden[irritatiebron.get_script().get_global_name() + "_" + kudde_staat.keys()[waargenomen_kudde_staat]]
	return 0 if afstand > irritatie_afstand else (irritatie_afstand - afstand) / irritatie_afstand

func calculate_speed() -> float:
	# takes group speed 
	var new_speed : float = speed + 0.01
	new_speed = clampf(new_speed, 0, max_speed)
	return new_speed

func schaap_verplaatsen(delta) -> void:
	# We need speed, direction, correct orientation
	global_position += transform.basis.z * -max_speed * delta * [behoefte_voeding, behoefte_persoonlijke_ruimte, behoefte_gezelligheid].max()

func schaap_orienteren(target : Vector3, delta : float) -> void: 
	var vector_to_target = target - global_position
	var angle_to_target = Vector2(vector_to_target.x, vector_to_target.z).angle() + 0.5*PI
	var atc =  -angle_to_target - global_rotation.y#deg_to_rad(direction.y)
	if abs(atc) > PI: atc = atc + (2*PI if atc < 0 else -2*PI)
	rotation.y += atc * turn_speed * delta

func schaap_kleuren(measured_variable, max_variable = 1) -> void:
	var material = body.get_active_material(0)
	var debug_red_value = remap(measured_variable, 0, max_variable, 0, 1)
	material.albedo_color = Color(debug_red_value, 0.5, 0.5)
	body.set_surface_override_material(0, material)
