class_name schaap
extends CharacterBody3D

@export var herder_scene: Node3D
@export var debug_mode : bool = true 
@export var cam: Camera3D
@export var debug_label : Label3D
var debug_text = []

@onready var body : MeshInstance3D = find_child("Body")

### Schaap movement ###
var speed : float
@export var max_speed : float = 30
@export var turn_speed : float = 1
@export var schaap_acceleration: float = 1

@export var minimum_behoefte: float = 0.01

@export var honger_increment: float = 0.001 # 0.001 = 0.1% per second

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

func _physics_process(delta: float) -> void:
	move_and_slide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	update_waargenomen_schapen()
	
	# behoeftes updaten
	update_behoefte_voeding(delta)
	update_behoefte_persoonlijke_ruimte()
	update_behoefte_gezelligheid()
	
	match [minimum_behoefte, behoefte_voeding, behoefte_persoonlijke_ruimte, behoefte_gezelligheid].max() : 
		behoefte_voeding : voeding_logica()
		behoefte_persoonlijke_ruimte : persoonlijke_ruimte_logica(delta)
		behoefte_gezelligheid : gezelligheid_logica(delta)
		minimum_behoefte: verplaatsen_gebied(delta)
	
	if debug_mode:
		update_debug_panel()

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
func update_behoefte_voeding(delta) -> void:
	if (behoefte_voeding < 1):
		behoefte_voeding += delta * honger_increment
	else:
		# schaap gaat dood
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
	# benodigde drijfveren voor gezelligheid
	var aantal_waargenomen_schapen : int = waargenomen_schapen.size()
	var afstand_tot_kudde_centrum : float = 0
	var gemiddelde_afstand_dichtstbijzijnde_schapen : float = 0
	#var eenzame_tijd_verstreken : float
	
	# ondersteunende variabelen
	var dichtstbijzijnde_schapen = []
	var waargenomen_kudde_centrum : Vector3
	for i in waargenomen_schapen:
		var afstand = position.distance_to(i.position)
		dichtstbijzijnde_schapen.append([i, afstand])
		afstand_tot_kudde_centrum += afstand
		waargenomen_kudde_centrum.x += i.position.x
		waargenomen_kudde_centrum.y += i.position.y
		waargenomen_kudde_centrum.z += i.position.z
	waargenomen_kudde_centrum.x = waargenomen_kudde_centrum.x / waargenomen_schapen.size()
	waargenomen_kudde_centrum.y = waargenomen_kudde_centrum.y / waargenomen_schapen.size()
	waargenomen_kudde_centrum.z = waargenomen_kudde_centrum.z / waargenomen_schapen.size()
	
	afstand_tot_kudde_centrum = afstand_tot_kudde_centrum / waargenomen_schapen.size()#position.distance_to(waargenomen_kudde_centrum)
	
	dichtstbijzijnde_schapen.sort_custom(func(a, b): return a[1] > b[1])
	var minimale_kudde_hoeveelheid: int = 5 #afhankelijk van een soort "loner" / "volgzaamheid" variable?
	var aantal_schapen_dichtbij: int = min(minimale_kudde_hoeveelheid, dichtstbijzijnde_schapen.size())
	var max_gezichtveld_schaap: float = 100.0
	for i in aantal_schapen_dichtbij:
		gemiddelde_afstand_dichtstbijzijnde_schapen += position.distance_to(dichtstbijzijnde_schapen[i][0].position)
	gemiddelde_afstand_dichtstbijzijnde_schapen = gemiddelde_afstand_dichtstbijzijnde_schapen / aantal_schapen_dichtbij
	var ervaren_afstand_dichtstbijzijnde_schapen = (
			gemiddelde_afstand_dichtstbijzijnde_schapen + 
			max_gezichtveld_schaap * 
			(minimale_kudde_hoeveelheid - aantal_schapen_dichtbij))
	
	add_to_debug_panel("Waargenomen schapen: ", aantal_waargenomen_schapen)
	add_to_debug_panel("Ervaren afstand tot dichtstbijzijnde schapen: ", ervaren_afstand_dichtstbijzijnde_schapen)
	add_to_debug_panel("Afstand tot waargenomen kudde centrum: ", afstand_tot_kudde_centrum)

# bepaald de manier waarop de behoefte vervuld wordt
func voeding_logica() -> void:
	# GRAZEN PLACEHOLDER:
	behoefte_voeding = 0

func persoonlijke_ruimte_logica(delta) -> void:
	# is just a redirection now. movement logic is called from verplaatsen_gebied
	# keep for now because i think we will need logic here later
	verplaatsen_gebied(delta)

func persoonlijke_ruimte_verplaatsing() -> Vector2:
	if behoefte_persoonlijke_ruimte < minimum_behoefte: return Vector2(0,0)
	
	var run_direction = Vector2(0,0)
	for irritatiebron in irritatiebronnen:
		var dir = (global_position - irritatiebron.bron.global_position) * irritatiebron.irritatie
		run_direction += Vector2(dir.x, dir.z)
	return run_direction

func gezelligheid_logica(delta) -> void:
	# is just a redirection now. see persoonlijke_ruimte_logica
	verplaatsen_gebied(delta)

func gezelligheid_verplaatsing() -> Vector2:
	return Vector2(0,0)

### Verplaatsing ###

func verplaatsen_gebied(delta) -> void:
	# General movement function: optimize position for different goals
	var run_goal = Vector2(0,0)
	
	run_goal += persoonlijke_ruimte_verplaatsing()
	run_goal += gezelligheid_verplaatsing()
	
	run_goal = run_goal.normalized()
	
	run_goal = Vector3(run_goal.x, 0, run_goal.y)
	if(run_goal.length_squared() > 0):
		schaap_orienteren(global_position - run_goal, delta)
	velocity += (run_goal * max_speed * [behoefte_voeding, behoefte_persoonlijke_ruimte, behoefte_gezelligheid].max() - velocity) * delta * schaap_acceleration

func verplaatsen_doel(goal, delta) -> void:
	# We need speed, direction, correct orientation
	global_position += transform.basis.z * -max_speed * delta * [behoefte_voeding, behoefte_persoonlijke_ruimte, behoefte_gezelligheid].max()

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

func schaap_orienteren(target : Vector3, delta : float) -> void: 
	var vector_to_target = target - global_position
	var angle_to_target = Vector2(vector_to_target.x, vector_to_target.z).angle() + 0.5*PI
	var atc =  -angle_to_target - global_rotation.y#deg_to_rad(direction.y)
	if abs(atc) > PI: atc = atc + (2*PI if atc < 0 else -2*PI)
	rotation.y += atc * turn_speed * delta

### Debugging ###

func schaap_kleuren(measured_variable, max_variable = 1) -> void:
	var material = body.get_active_material(0)
	var debug_red_value = remap(measured_variable, 0, max_variable, 0, 1)
	material.albedo_color = Color(debug_red_value, 0.5, 0.5)
	body.set_surface_override_material(0, material)

func add_to_debug_panel(variabel_naam : String, variabel_waarde) -> void:
	var regel : String = variabel_naam + str(variabel_waarde)
	debug_text.append(regel)

func update_debug_panel() -> void:
	var text : String = ""
	#if debug_text: text = debug_text[1]
	for i in debug_text.size():
		text = text + "\n" + str(debug_text[i])
	debug_label.text = text
	debug_text.clear()
