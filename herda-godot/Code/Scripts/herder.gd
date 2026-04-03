class_name herder
extends CharacterBody3D

const MOUSE_SENSITIVITY: float = 0.003
const CAMERA_X_ROT_MIN: float = deg_to_rad(-79.9) 
const CAMERA_X_ROT_MAX: float = deg_to_rad(110.0) 
const TURN_SPEED: float = 6

@export var v_walk: float = 1.5
@export var v_backwards: float = 1

@export var cam: Camera3D
@export var cam_base: Node3D
@export var cam_rot: Node3D

@export var animation_tree: AnimationTree
var state_machine: AnimationNodeStateMachinePlayback
var looking = 0.0

@onready var player: AnimationPlayer = find_child("AnimationPlayer")

var walk_vector = Vector3(0,0,0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	state_machine = animation_tree.get("parameters/animation states/playback")

func _physics_process(_delta: float) -> void:
	set_velocity(Vector3(walk_vector.x, walk_vector.y, walk_vector.z)) # can add gravity etc here
	move_and_slide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var motion = Input.get_axis("walk backwards", "walk forward")
	if motion != 0:
		# move in the facing direction
		walk_vector = Quaternion(Vector3.UP, 1*PI) * cam_base.transform.basis.z * motion * (v_walk if motion > 0 else v_backwards) 
		
		#align the character with the camera
		var atc = cam_base.rotation.y - rotation.y # angle to camera
		if abs(atc) > PI: atc = atc + (2*PI if atc < 0 else -2*PI)
		rotation.y += atc * TURN_SPEED * delta
	else:
		walk_vector = Vector3(0.0,0.0,0.0)
	
	#look around
	var atc_anim = cam_base.rotation.y - rotation.y # angle to camera
	if abs(atc_anim) > PI: atc_anim = atc_anim + (2*PI if atc_anim < 0 else -2*PI)
	looking += (clampf(atc_anim, -2.1, 2.1) - looking) * delta * 10
	animation_tree.set("parameters/looking around/blend_position", looking)
	
	cam_base.global_position = global_position + Vector3.UP * 1.5

# camera controls
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var camera_speed_this_frame = MOUSE_SENSITIVITY
		rotate_camera(event.screen_relative * camera_speed_this_frame)
	if Input.is_action_just_pressed("nudge") and velocity.length() == 0:
		state_machine.travel("shove")
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()

func rotate_camera(move: Vector2) -> void:
	cam_base.rotate_y(-move.x)
	cam_base.orthonormalize()
	cam_rot.rotation.x = clampf(cam_rot.rotation.x - move.y, CAMERA_X_ROT_MIN, CAMERA_X_ROT_MAX)
