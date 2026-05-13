class_name schaap
extends CharacterBody3D

@export var herder_scene: Node3D
@export var debug_mode : bool = true 
@export var cam: Camera3D
@export var debug_label : Label3D
@export var gras_manager: Node3D

@export var debug_kubus: MeshInstance3D

var debug_text = []
var debug_sphere : MeshInstance3D

@onready var body : MeshInstance3D = $"schaap model/schaap skelet/Skeleton3D/schaap"
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var mondje: MeshInstance3D = $mondje
@onready var animation_tree: AnimationTree = $"schaap animation tree"

var state_machine: AnimationNodeStateMachinePlayback

### Schaap movement ###
var speed : float
var looking_direction: float
var interesse: float = 0.0
var interesse_angle: float = 0.0
@export var max_speed : float = 30
@export var turn_speed : float = 1
@export var head_turn_speed: float = 3
@export var schaap_acceleration: float = 1
@export var schaap_deceleration: float = 3
var read_velocity: Vector3 # this is only for reading velocity from inspector. shouldnt be used in logic
var voeding_doel: Vector3 = Vector3.ZERO
var recalculate_voeding_doel: int = 0

@export var minimum_behoefte: float = 0.01

@export var honger_increment: float = 0.001 # 0.001 = 0.1% per second
var maag1 = 0 #part of temporary eating logic

@export var behoefte_persoonlijke_ruimte_falloff: float = 0.5
@export var irritatie_afstanden = {
	"herder_rust": 4,
	"herder_lopend": 2.5,
	"schaap_rust": 2,
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
enum animation_state {idle, verplaatsing, grazend}
var my_animation_state = animation_state.idle
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
# set "loner" value
# set "minimale kudde grote

var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_machine = animation_tree.get("parameters/playback")
	
	honger_increment = honger_increment * rng.randf_range(0.75, 1.0)
	
	if(herder_scene != null):
		mijn_herder = herder_scene.find_child("herder")
	
	if debug_mode and cam != null:
		debug_sphere = get_parent().get_parent().find_child("Debug_sphere")

func _physics_process(delta: float) -> void:
	animation_tree.set("parameters/walking/move speed/scale", Vector2(velocity.x, velocity.z).length() * 2.0) #SCHAAP MOVES 0.5M in 32 FRAMES! IE  ONE FULL WALK CYCLE
	
	if(velocity.length() > 0.05):
		my_animation_state = animation_state.verplaatsing
	
	read_velocity = velocity
	move_and_slide()
	if(!is_on_floor() and velocity.y <= 0): # this is an ugly and unreliable fix to a bug where sheep get stuck on small ledges
		velocity += Vector3.DOWN * delta * 15 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	update_waargenomen_schapen()
	
	# behoeftes updaten
	update_behoefte_voeding(delta)
	update_behoefte_persoonlijke_ruimte()
	update_behoefte_gezelligheid(delta)
	
	if debug_mode:
		update_debug_panel()
	if debug_sphere and !Input.is_action_pressed("nudge"):
		look_towards(delta, debug_sphere.global_position)
	if debug_sphere and Input.is_action_pressed("nudge"):
		verplaatsen_doel(debug_sphere.global_position, 0.1, delta)
		return
	
	match [minimum_behoefte, behoefte_voeding, behoefte_persoonlijke_ruimte, behoefte_gezelligheid].max() : 
		behoefte_voeding : voeding_logica(delta)
		behoefte_persoonlijke_ruimte : persoonlijke_ruimte_logica(delta)
		behoefte_gezelligheid : gezelligheid_logica(delta)
		minimum_behoefte: 
			idle_logica(delta)

# welke schapen neemt het schaap waar. hoeft mss niet elk frame.
func update_waargenomen_schapen() -> void:
	waargenomen_schapen = []
	var space = get_world_3d().direct_space_state
	for schaapje in alle_schapen:
		# near 360 degree vision so no view cone.
		if schaapje == self: continue
		
		var target_coordinates = schaapje.global_position + Vector3.UP * 0.8
		var hit = space.intersect_ray(
			PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.8, target_coordinates, 0x0002))
		if !hit or hit.collider == schaapje:
			waargenomen_schapen.append(schaapje)

# bepaalt de dringendheid van de behoefte
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
	irritatie_totaal = (irritatiebronnen.map(func(bron): return bron.irritatie).max() if irritatiebronnen.size() > 0 else 0) + 0.1 * irritatie_totaal
	var goal_behoefte_persoonlijke_ruimte = 1 - 1 / sqrt(behoefte_persoonlijke_ruimte_falloff * irritatie_totaal + 1)
	behoefte_persoonlijke_ruimte += (goal_behoefte_persoonlijke_ruimte - behoefte_persoonlijke_ruimte) * (0.005 if goal_behoefte_persoonlijke_ruimte > behoefte_persoonlijke_ruimte and behoefte_persoonlijke_ruimte < 0.02 else 0.2)

var afstand_tot_kudde_centrum : float = 0
var aantal_waargenomen_schapen : int = 0
var afstand_tot_dichtstbijzijnde_schapen : float
var laatste_locatie_schapen = Vector3.ZERO
var eenzame_tijd_verstreken : float = 0
var minimale_kudde_hoeveelheid : int = 5
var ervaren_afstand_dichtstbijzijnde_schapen : float
var eenzaamheid_increment : float
var eenzaamheid : float = 0
var debug_val
#afhankelijk van een soort "loner" / "volgzaamheid" variable?

func update_behoefte_gezelligheid(delta) -> void:
	# benodigde drijfveren voor gezelligheid
	#var aantal_waargenomen_schapen : int = waargenomen_schapen.size()
	#var afstand_tot_kudde_centrum : float = 0
	#var gemiddelde_afstand_dichtstbijzijnde_schapen : float = 0
	#var eenzame_tijd_verstreken : float
	aantal_waargenomen_schapen = waargenomen_schapen.size()
	
	# ondersteunende variabelen
	var dichtstbijzijnde_schapen = []
	var waargenomen_kudde_centrum = Vector3.ZERO
	
	for schaapje in waargenomen_schapen:
		var afstand = position.distance_to(schaapje.position)
		dichtstbijzijnde_schapen.append({
			"object": schaapje, 
			"afstand": afstand})
		afstand_tot_kudde_centrum += afstand
		waargenomen_kudde_centrum += schaapje.position
	afstand_tot_kudde_centrum = position.distance_to(waargenomen_kudde_centrum/aantal_waargenomen_schapen)
	
	dichtstbijzijnde_schapen.sort_custom(func(a, b): return a["afstand"] < b["afstand"])
	var aantal_schapen_dichtbij: int = min(minimale_kudde_hoeveelheid, dichtstbijzijnde_schapen.size())
	var max_gezichtveld_schaap: float = 35.0
	var gemiddelde_dichtstbijzijnde_schapen_positie = Vector3.ZERO
	if aantal_schapen_dichtbij > 0:
		for i in range(0, aantal_schapen_dichtbij):
			gemiddelde_dichtstbijzijnde_schapen_positie += dichtstbijzijnde_schapen[i]["object"].global_position
		laatste_locatie_schapen = gemiddelde_dichtstbijzijnde_schapen_positie/aantal_schapen_dichtbij
		afstand_tot_dichtstbijzijnde_schapen = position.distance_to(laatste_locatie_schapen)
		ervaren_afstand_dichtstbijzijnde_schapen = (
			afstand_tot_dichtstbijzijnde_schapen + 
			max_gezichtveld_schaap * 
			(minimale_kudde_hoeveelheid - aantal_schapen_dichtbij))
	else:
		ervaren_afstand_dichtstbijzijnde_schapen = max_gezichtveld_schaap * minimale_kudde_hoeveelheid
	
	var hoeveelheid_gewicht : float = 10.0 / 35.0
	var afstand_tot_kudde_gewicht : float = 10.0 / 35.0
	var afstand_tot_minimale_kudde_gewicht : float = 15.0 / 35.0
	var max_minimale_kudde_afstand = 35.0
	
	var hoeveelheid_increment = hoeveelheid_gewicht * ((-0.5 * min(aantal_waargenomen_schapen, 20.0) / minimale_kudde_hoeveelheid) + 1.0)
	var afstand_tot_kudde_increment = afstand_tot_kudde_gewicht * ((2 * min(max_gezichtveld_schaap, afstand_tot_kudde_centrum) / max_gezichtveld_schaap) - 1.0)
	var afstand_tot_minimale_kudde_increment = afstand_tot_minimale_kudde_gewicht * (2 * (ervaren_afstand_dichtstbijzijnde_schapen / max_minimale_kudde_afstand) - 1.0)
	var behoefte_voor_gezelligheid_increment = hoeveelheid_increment + afstand_tot_kudde_increment + afstand_tot_minimale_kudde_increment
	
	var toeneem_duratie = 300
	var afloop_duratie = 50
	if (behoefte_voor_gezelligheid_increment > 0):
		behoefte_gezelligheid += delta * behoefte_voor_gezelligheid_increment / toeneem_duratie
	else: 
		behoefte_gezelligheid += delta * behoefte_voor_gezelligheid_increment / afloop_duratie
	behoefte_gezelligheid = min(max(0.0, behoefte_gezelligheid), 1.0)
	
	# schaap_kleuren(behoefte_gezelligheid)
	debug_kubus.global_position = Vector3(laatste_locatie_schapen.x, debug_kubus.global_position.y, laatste_locatie_schapen.z)
	
	#add_to_debug_panel("laatste_locatie_schapen: ", laatste_locatie_schapen)
	#add_to_debug_panel("afstand_tot_dichtstbijzijnde_schapen: ", afstand_tot_dichtstbijzijnde_schapen)
	#add_to_debug_panel("ervaren_afstand_dichtstbijzijnde_schapen: ", ervaren_afstand_dichtstbijzijnde_schapen)
	#add_to_debug_panel("hoeveelheid_increment: ", hoeveelheid_increment)
	#add_to_debug_panel("afstand_tot_kudde_increment: ", afstand_tot_kudde_increment)
	#add_to_debug_panel("afstand_tot_minimale_kudde_increment: ", afstand_tot_minimale_kudde_increment)
	#add_to_debug_panel("behoefte_voor_gezelligheid_increment: ", behoefte_voor_gezelligheid_increment)
	add_to_debug_panel("aantal_waargenomen_schapen: ", aantal_waargenomen_schapen)
	add_to_debug_panel("behoefte_gezelligheid: ", behoefte_gezelligheid)
	Debug_tools.print_object_variabele(name, "behoefte_gezelligheid: \t", behoefte_gezelligheid)
	Debug_tools.print_object_variabele(name, "behoefte_voeding: \t\t", behoefte_voeding)
	
# rood schaap gezelligheid
# gezelligheid plummet harder
# wereld kaart beinvloed micro kaart

# bepaalt de manier waarop de behoefte vervuld wordt
func voeding_logica(delta) -> void:
	# GRAZEN NAVIGATIE
	# hier moet hij naar een plekje met genoeg gras navigeren en als die op is doorgaan
	
	# gaat nu best redelijk maar nog een paar nodige bugfixes:
	# - ze gaan wel soms vechten om een plekje en dan komen ze er niet meer uit
		# ze moeten soms kunnen evalueren of ze wel de juiste richting hebben gekozen
		# ze moeten niet allemaal dezelfde kant opgaan
	# - ze blijven soms hangen als ze denken dat het eten op is
	recalculate_voeding_doel += 1
	
	if gras_manager.sample_gras(mondje.global_position) > 0.4:
		voeding_doel = Vector3.ZERO
	elif voeding_doel == Vector3.ZERO or recalculate_voeding_doel > 100 or gras_manager.sample_gras(voeding_doel) < 0.5:
		# check da area. gaat nu in een spiraal naar buiten vanuit het schaap
		# dit is prima maar het houdt geen rekening met het gezichtveld van het schaap. en dat is misschien oke.
		var goal = {base = Vector2(global_basis.z.x, global_basis.z.z), rot = rng.randf_range(-0.3, 0.3), coord = Vector2.ZERO, value = 0.0}
		
		var space = get_world_3d().direct_space_state
		var grond = gras_manager.get_parent()
		while goal.value < 0.5 and goal.coord.length() < 50:
			goal.base = goal.base * 1.01
			goal.coord = goal.base.rotated(goal.rot)
			var hit = space.intersect_ray(
				PhysicsRayQueryParameters3D.create(mondje.global_position, global_position + Vector3(goal.coord.x, 0.0, goal.coord.y) + Vector3(goal.coord.x, 0.0, goal.coord.y).normalized() * 0.25)) # y should be grond level. im doing the normalized vector thing so its less likely to try getting to unreachable places
			if hit and hit.collider != grond:
				goal.value = 0.0
			else:
				goal.value = gras_manager.sample_gras(global_position + Vector3(goal.coord.x, 0.0, goal.coord.y))
			goal.rot = -goal.rot - 0.1 * sign(goal.rot)
		if goal.value > 0.5:
			voeding_doel = global_position + Vector3(goal.coord.x, 0.0, goal.coord.y)
			recalculate_voeding_doel = 0
	if voeding_doel != Vector3.ZERO:
		verplaatsen_doel(voeding_doel, behoefte_voeding, delta)
		#if(!navigation_agent.is_target_reachable()):
			#gras_manager.override_pixel(voeding_doel)
		if voeding_doel.distance_squared_to(global_position) > 1.5:
			return
	elif gras_manager.sample_gras(mondje.global_position) < 0.4:
		# schaap gaat in exploration modus. hebben we nog niet
		print("eten is op :(")
		return
	
	if velocity.length() > 0.04:
		lerp_velocity(Vector3.ZERO, delta)
		if velocity.length() < 0.02:
			velocity = Vector3.ZERO
		else:
			return
	
	# GRAZEN
	my_animation_state = animation_state.grazend
	
	# im gonna do some cursed animation based logic.
	
	if state_machine.get_current_node() == "eat" and state_machine.get_current_play_position() + delta > state_machine.get_current_length():
		maag1 += 1.0
		gras_manager.eat_gras(mondje.global_position)
	
	if(maag1 > 3.0):
		maag1 = 0
		behoefte_voeding = 0

func persoonlijke_ruimte_logica(delta) -> void:
	# is just a redirection now. movement logic is called from verplaatsen_gebied
	# keep for now because i think we will need logic here later
	verplaatsen_gebied(delta)

func gezelligheid_logica(delta) -> void:
	# is just a redirection now. see persoonlijke_ruimte_logica
	verplaatsen_gebied(delta)

func idle_logica(delta) -> void:
	# stand still
	my_animation_state = animation_state.idle
	lerp_velocity(Vector3.ZERO, delta)
	
	#look around a bit
	if interesse <= 0:
		interesse = rng.randf_range(2.0, 3.0)
		interesse_angle = rng.randf_range(-1.0,1.0)
	interesse -= 0.5 * delta
	look_towards(delta, null, interesse_angle)

### Verplaatsing ###

func persoonlijke_ruimte_verplaatsing() -> Vector2:
	if behoefte_persoonlijke_ruimte < minimum_behoefte: return Vector2(0,0)
	
	var run_direction = Vector2(0,0)
	for irritatiebron in irritatiebronnen:
		var dir = (global_position - irritatiebron.bron.global_position) * irritatiebron.irritatie
		run_direction += Vector2(dir.x, dir.z)
	return run_direction

func gezelligheid_verplaatsing() -> Vector2:
	#var nav_locatie = laatste_locatie_schapen * 4 * behoefte_gezelligheid + global_position * (1-behoefte_gezelligheid) / 4
	var nav_locatie = laatste_locatie_schapen
	navigation_agent.set_target_position(nav_locatie)
	var nav_goal = navigation_agent.get_next_path_position() - global_position
	return Vector2(nav_goal.x, nav_goal.z)

func verplaatsen_gebied(delta) -> void:
	# General movement function: optimize position for different goals
	var run_goal = Vector2(0,0)
	
	run_goal += persoonlijke_ruimte_verplaatsing().normalized() * behoefte_persoonlijke_ruimte
	run_goal += gezelligheid_verplaatsing().normalized() * behoefte_gezelligheid
	
	run_goal = run_goal.normalized()
	
	run_goal = Vector3(run_goal.x, 0, run_goal.y)
	if(run_goal.length_squared() > 0):
		verplaatsen_doel(global_position + run_goal, [behoefte_persoonlijke_ruimte, behoefte_gezelligheid].max(), delta)
	else:
		lerp_velocity(Vector3.ZERO, delta)

func verplaatsen_doel(goal, behoefte, delta) -> void:
	navigation_agent.set_target_position(goal)
	var nav_goal = navigation_agent.get_next_path_position()
	var run_goal = global_position.direction_to(nav_goal) * max_speed * behoefte
	schaap_orienteren(nav_goal, delta)
	lerp_velocity(run_goal, delta)

func lerp_velocity(goal, delta) -> void:
	velocity += (goal - velocity) * delta * (schaap_acceleration if goal.length() > velocity.length() else schaap_deceleration)

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
	var angle_to_target = Vector2(vector_to_target.x, vector_to_target.z).angle() - 0.5*PI
	var atc =  -angle_to_target - global_rotation.y
	if abs(atc) > PI: atc = atc + (2*PI if atc < 0 else -2*PI)
	rotation.y += atc * turn_speed * delta
	look_towards(delta, null, atc)

func look_towards(delta : float, target = null, atc = null) -> void:
	if atc == null and target != null:
		var vector_to_target = target - global_position
		var angle_to_target = Vector2(vector_to_target.x, vector_to_target.z).angle() - 0.5*PI
		atc =  -angle_to_target - global_rotation.y
		if abs(atc) > PI: atc = atc + (2*PI if atc < 0 else -2*PI)
	looking_direction += (-atc - looking_direction) * head_turn_speed * delta
	animation_tree.set("parameters/view dir/blend_position", looking_direction*0.7)
	animation_tree.set("parameters/walking/view dir/blend_position", looking_direction*0.7)

### Debugging ###

func schaap_kleuren(measured_variable, max_variable = 1) -> void:
	var material = body.get_active_material(0)
	var debug_red_value = remap(measured_variable, 0, max_variable, 0, 1)
	material.albedo_color = Color(debug_red_value, 0.5, 0.5)
	body.set_surface_override_material(0, material)

#func console_printer(variabel_naam : String, variabel_waarde) -> void:
	#var framecount = Engine.get_frames_drawn()
	#if (fmod(framecount, 600) == 0):
		#var boodschap : String = variabel_naam + str(variabel_waarde)
		#print(boodschap)

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
