extends Node3D

@export_node_path("Node3D") var head_nodepath
@export_node_path("CharacterBody3D") var player_nodepath
var mouse_sensitivity
var mouse_smoothness

var camera_input : Vector2
var rotation_velocity : Vector2

@onready var head = get_node(head_nodepath)
@onready var player = get_node(player_nodepath)

func _ready():
	# MOUSE
	mouse_sensitivity = player.mouse_sensitivity
	mouse_smoothness = remap(player.mouse_sensitivity, 0,10,0, 1.0)
	
	# HEAD BOOBING
	hb_lerp_speed = player.hb_lerp_speed
	hb_running_speed = player.hb_running_speed
	hb_walking_speed = player.hb_walking_speed
	hb_crouching_speed = player.hb_crouching_speed
	
	hb_running_intensity = player.hb_running_intensity
	hb_walking_intensity = player.hb_walking_intensity
	hb_crouching_intensity = player.hb_crouching_intensity
	
	# DYNAMIC FOV
	fov_lerp_speed = player.fov_lerp_speed
	default_fov = player.default_fov
	running_fov = player.running_fov

func _input(event):
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			camera_input = event.relative
	if Input.is_action_just_pressed("toggle_mouse"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event is InputEventMouseMotion:
		player.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta):
	if player.headbob:
		head_boobing(delta)
	if player.dymanic_fov:
		dynamic_fov(delta)

# HEAD BOOBING

var hb_lerp_speed = 10.0

var hb_running_speed = 18.0 
var hb_walking_speed = 14.0
var hb_crouching_speed = 10.0

var hb_running_intensity = 0.12
var hb_walking_intensity = 0.05
var hb_crouching_intensity = 0.05

var hb_vector = Vector3.ZERO
var hb_index = 0.0
var hb_current_intensity = 0.0

@onready var player_eyes = $".."

func head_boobing(delta):

	match player.state:
		player.PlayerState.running:
			hb_current_intensity = hb_running_intensity
			hb_index += hb_running_speed * delta
		player.PlayerState.walking:
			hb_current_intensity = hb_walking_intensity
			hb_index += hb_walking_speed * delta
		player.PlayerState.crouching:
			hb_current_intensity = hb_crouching_intensity
			hb_index += hb_crouching_speed * delta
	
	if player.is_on_floor() and player.direction != Vector3.ZERO:
		hb_vector.x = sin(hb_index/2)+0.5
		hb_vector.y = sin(hb_index)
		hb_vector.z = sin(hb_index/2)*0.1
		
		player_eyes.position.x = lerp(player_eyes.position.x, hb_vector.x * hb_current_intensity, delta * hb_lerp_speed)
		player_eyes.position.y = lerp(player_eyes.position.y, hb_vector.y * (hb_current_intensity/2), delta * hb_lerp_speed)
		player_eyes.rotation.z = lerp(player_eyes.rotation.z, hb_vector.z * hb_current_intensity, delta * hb_lerp_speed)
	else:
		player_eyes.position.x = lerp(player_eyes.position.x,0.0 , delta * hb_lerp_speed)
		player_eyes.position.y = lerp(player_eyes.position.y,0.0 , delta * hb_lerp_speed)
		player_eyes.rotation.z = lerp(player_eyes.rotation.z, 0.0, delta * hb_lerp_speed)

# DYNAMIC FOV

var fov_lerp_speed

var default_fov
var running_fov

func dynamic_fov(delta):
	if player.state == player.PlayerState.running and player.direction != Vector3.ZERO and self.fov != running_fov:
		self.fov = lerp(self.fov, running_fov, delta * fov_lerp_speed)
	elif self.fov != default_fov:
		self.fov = lerp(self.fov, default_fov, delta * fov_lerp_speed)






