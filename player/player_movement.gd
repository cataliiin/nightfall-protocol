extends CharacterBody3D

enum PlayerState {
	walking,
	running,
	crouching
}

var state: PlayerState

@export_category("Player")

@export_group("Movement")

@export_group("Movement/General")
@export_range(1, 60, 0.1) var walk_movement_speed: float = 4
@export_range(0.1, 30, 0.1) var gravity: float = 15.5

@export_group("Movement/Acceleration")
@export_range(0.1, 60, 0.1) var horizontal_air_acceleration: float = 3
@export_range(0.1, 60, 0.1) var horizontal_normal_acceleration: float = 6
@export_range(0.1, 60, 0.1) var horizontal_air_deceleration: float = 3
@export_range(0.1, 60, 0.1) var horizontal_normal_deceleration: float = 8

@export_group("Movement/Run")
@export var running: bool = true
@export_range(1, 60, 0.1) var run_movement_speed: float = 6
@export_group("Movement/Run/DynamicFov")
@export var dymanic_fov: bool = true
@export_range(1, 100, 1) var fov_lerp_speed: float = 4 
@export_range(50, 120, 1) var default_fov: float = 75
@export_range(50, 120, 1) var running_fov: float = 80

@export_group("Movement/Crouch")
@export var crouching: bool = true
@export_range(1, 60, 0.1) var crouch_movement_speed: float = 2
@export_range(0.1, 50, 0.1) var crouch_speed: float = 12
@export_range(0.1, 10, 0.1) var crouching_player_height: float = 1.0

@export_group("Movement/Jump")
@export var jumping: bool = true
@export_range(0.1, 30, 0.1) var jump_force: float = 5.7

# FOR OTHER SCRIPTS
@export_group("Mouse")
@export_range(0.01, 1, 0.01) var mouse_sensitivity: float = 0.09

@export_group("HeadBoobing")
@export var headbob: bool = true
@export_range(0.1, 30, 0.1) var hb_lerp_speed = 10.0
@export_group("HeadBoobing/speed")
@export_range(0.1, 30, 0.1) var hb_running_speed = 18.0 
@export_range(0.1, 30, 0.1) var hb_walking_speed = 14.0
@export_range(0.1, 30, 0.1) var hb_crouching_speed = 10.0
@export_group("HeadBoobing/intensity")
@export_range(0.1, 30, 0.1) var hb_running_intensity = 0.12
@export_range(0.1, 30, 0.1) var hb_walking_intensity = 0.05
@export_range(0.1, 30, 0.1) var hb_crouching_intensity = 0.05

var movement_speed
var horizontal_acceleration
var horizontal_deceleration

var initial_player_height: float
var initial_head_height: float

var direction: Vector3
var horizontal_velocity = Vector3()
var gravity_vector = Vector3()

func _ready():
	initial_player_height = player_collision_shape.shape.height
	initial_head_height = player_head.position.y

func _physics_process(delta):
	
	var input_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	direction = (transform.basis * Vector3(input_direction.x, 0,input_direction.y )).normalized()
	
	if not is_on_floor():
		gravity_vector += Vector3.DOWN * gravity * delta
		horizontal_acceleration = horizontal_air_acceleration
		horizontal_deceleration = horizontal_air_deceleration
	else:
		gravity_vector = -get_floor_normal()
		horizontal_acceleration = horizontal_normal_acceleration
		horizontal_deceleration = horizontal_normal_deceleration
	
	if is_on_ceiling():
		gravity_vector = Vector3(0,-0.1,0)
	
	if jumping:
		if Input.is_action_just_pressed("jump") and is_on_floor():
			gravity_vector = Vector3.UP * jump_force
	
	if running:
		if Input.is_action_pressed("run"):
			movement_speed = run_movement_speed
			state = PlayerState.running
		else:
			movement_speed = walk_movement_speed
			state = PlayerState.walking
	else: 
		movement_speed = walk_movement_speed
		state = PlayerState.walking
	
	if crouching:
		crouch(delta)
	
	direction = direction.normalized()
	if direction != Vector3.ZERO:
		horizontal_velocity = horizontal_velocity.lerp(direction * movement_speed, horizontal_acceleration * delta)
	else:
		horizontal_velocity = horizontal_velocity.lerp(direction * movement_speed, horizontal_deceleration * delta)
	velocity.z = horizontal_velocity.z + gravity_vector.z
	velocity.x = horizontal_velocity.x + gravity_vector.x
	velocity.y = gravity_vector.y
	
	move_and_slide()

@onready var player_collision_shape = $CollisionShape3D
@onready var player_head = $Head

@onready var head_raycast = $HeadRayCast

func crouch(delta):
	
	if Input.is_action_pressed("crouch"):
		state = PlayerState.crouching
		movement_speed = crouch_movement_speed
		
		player_collision_shape.shape.height = lerp(player_collision_shape.shape.height, crouching_player_height, delta * crouch_speed)
		player_head.position.y = lerp(player_head.position.y, (initial_player_height-crouching_player_height) / 2 + (crouching_player_height / 4) * 3, delta * crouch_speed)
		head_raycast.position.y = lerp(head_raycast.position.y, (initial_player_height-crouching_player_height) / 2 + crouching_player_height, delta * crouch_speed)
	elif !head_raycast.is_colliding():
		player_collision_shape.shape.height = lerp(player_collision_shape.shape.height, initial_player_height, delta * crouch_speed)
		player_head.position.y = lerp(player_head.position.y, initial_head_height, delta * crouch_speed)
		head_raycast.position.y = lerp(head_raycast.position.y, initial_player_height, delta * crouch_speed)
	
	if head_raycast.is_colliding() and is_on_floor():
		state = PlayerState.crouching
		movement_speed = crouch_movement_speed
