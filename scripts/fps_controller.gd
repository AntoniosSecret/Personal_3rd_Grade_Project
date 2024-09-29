class_name Player

extends CharacterBody3D

# CAMERA MOVEMENT
@export var MOUSE_SENSITIVITY : float = 0.5
@export var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(90.0)
@export var CAMERA_CONTROLLER : Camera3D
var _mouse_input : bool = false
var _rotation_input : float
var _tilt_input : float
var _mouse_rotation : Vector3
var _player_rotation : Vector3
var _camera_rotation : Vector3

# Later assigned as _rotation_input in _update_camera func
var _current_rotation : float

var is_fullscreen : bool = false

# Base animation player for all animations
@export var ANIMATION_PLAYER : AnimationPlayer

# Custom gravity for RigidBody
var gravity = 12.0


func _unhandled_input(event: InputEvent) -> void:
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_rotation_input = -event.relative.x * MOUSE_SENSITIVITY
		_tilt_input = -event.relative.y * MOUSE_SENSITIVITY


func _input(event: InputEvent) -> void:
	# exit = ESC
	if event.is_action_pressed("exit") and !is_fullscreen:
		get_tree().quit()
	elif event.is_action_pressed("exit"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		is_fullscreen = !is_fullscreen
	
	# toggle_fullscreen = F11
	if event.is_action_pressed("toggle_fullscreen") and !is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		is_fullscreen = !is_fullscreen


func _update_camera(delta):
	_current_rotation = _rotation_input
	
	# Rotates camera using euler rotation
	_mouse_rotation.x += _tilt_input * delta
	_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	_mouse_rotation.y += _rotation_input * delta
	
	_player_rotation = Vector3(0.0,_mouse_rotation.y,0.0)
	_camera_rotation = Vector3(_mouse_rotation.x,0.0,0.0)
	
	CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation)
	global_transform.basis = Basis.from_euler(_player_rotation)
	
	CAMERA_CONTROLLER.rotation.z = 0.0
	
	_rotation_input = 0.0
	_tilt_input = 0.0

# On start func
func _ready() -> void:
	Global.player = self
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# _process func runs at user framerate
func _process(delta: float) -> void:
	_update_camera(delta)

# _physics_process runs faster than user framerate
func _physics_process(delta: float) -> void:
	# while vsync is on, fps stay at monitor refresh rate
	var frames_per_second : String = "%.0f" % (1.0/delta)
	var round_mouse = [snapped(_mouse_rotation.x, 0.001), snapped(_mouse_rotation.y, 0.001)]
	
	# Displays these properties in debug screen (~)
	Global.debug.add_property("FPS", frames_per_second, 0)
	Global.debug.add_property("Mouse_Rotation", round_mouse, 1)
	Global.debug.add_property("Movement_Velocity", snapped(velocity.length(), 0.01), 2)

# For PlayerStateMachines:
func update_gravity(delta) -> void:
	velocity.y -= gravity * delta

# For PlayerStateMachines:
func update_input(speed: float, acceleration: float, deceleration: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = lerp(velocity.x, direction.x * speed, acceleration)
		velocity.z = lerp(velocity.z, direction.z * speed, acceleration)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration)
		velocity.z = move_toward(velocity.z, 0, deceleration)

# For PlayerStateMachines:
func update_velocity() -> void:
	move_and_slide()
