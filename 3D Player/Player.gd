extends CharacterBody3D

var speed
const WALK_SPEED = 4.8
const SPRINT_SPEED = 6.7
const JUMP_VELOCITY = 4.5
const Sensitivity = 0.002
var can_sprint

#Head Sway Variables
const HEAD_SWAY_MAX = 5
var t_sway = 0.5
const HEAD_SWAY_AMP = 0.02
const HEAD_SWAY_FREQ = 1
var head_sway_1 = 0.0
var head_sway_2 = 0.0

#Head Bob Variables
const BOB_FREQ = 2
const BOB_AMP = 0.11
var t_bob = 0.0

#FOV Variables
const BASE_FOV = 75.0
const FOV_CHANGE = 2.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = 9.8

@onready var head = $Head
@onready var head_sway = $Head/HeadSway
@onready var camera = $Head/HeadSway/Camera3D
@onready var stamina = $"../Stamina"
@onready var label = $"../Label"

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * Sensitivity)
		camera.rotate_x(-event.relative.y * Sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	stamina.value = stamina.max_value

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	#Handle Sprint.
	if Input.is_action_pressed("sprint"):
		if can_sprint:
			if stamina.value > 0.01:
				speed = SPRINT_SPEED
				stamina.value -= delta * 1.5
			else:
				can_sprint = false
				speed = WALK_SPEED
		else:
			stamina.value += delta * 0.5
			if stamina.value > 1:
				can_sprint = true
	else:
		speed = WALK_SPEED
		stamina.value += delta * 0.5

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 4)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 4)
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 2.5)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 2.5)

	#Head Bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	#FOV Change
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 10.0)
	
	#Head Sway
	t_sway += delta * velocity.length() * float(is_on_floor())
	_headsway(t_sway)
	
	
	move_and_slide()
	
	
func _headsway(time):
	if Input.is_action_pressed("left"):
		head_sway_1 += (Input.get_action_strength("left")/250)
	elif Input.is_action_pressed("right"):
		head_sway_1 -= (Input.get_action_strength("right")/250)
	else:
		#head_sway_1 = lerp(head_sway_1, deg_to_rad(0), 5)
		head_sway_1 = head_sway_1 * 0.9
		pass
	head_sway_1 = clamp(head_sway_1, deg_to_rad(-HEAD_SWAY_MAX), deg_to_rad(HEAD_SWAY_MAX))
	#head_sway.rotation.z = sin(time* (HEAD_SWAY_FREQ + ((velocity.y * HEAD_SWAY_AMP)/60))) * (HEAD_SWAY_AMP + ((velocity.y * HEAD_SWAY_AMP)/60))
	head_sway_2 = sin(time* (HEAD_SWAY_FREQ + ((velocity.y * HEAD_SWAY_AMP)/60))) * (HEAD_SWAY_AMP + ((velocity.y * HEAD_SWAY_AMP)/60))
	
	head_sway.rotation.z = head_sway_1 + head_sway_2
	#head_sway.rotation.z = clamp(head_sway.rotation.z, deg_to_rad(-HEAD_SWAY_MAX), deg_to_rad(HEAD_SWAY_MAX))


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time* BOB_FREQ) * (BOB_AMP + ((velocity.y * BOB_AMP)/40))
	pos.x = cos(time* BOB_FREQ / 2) * (BOB_AMP + ((velocity.x * BOB_AMP)/40))
	return pos

func _process(delta: float) -> void:
	label.text = str(velocity.length())
