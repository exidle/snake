extends CharacterBody2D

## The player's movement speed (in pixels per second).
const MOTION_SPEED = 90.0
@export var synced_position := Vector2()
@export var synced_rotation := 0.0

@onready var inputs: Node = $Inputs

func _ready() -> void:
	position = synced_position
	if str(name).is_valid_int():
		$"Inputs/InputsSync".set_multiplayer_authority(str(name).to_int())

func _physics_process(delta):
	if multiplayer.multiplayer_peer == null or str(multiplayer.get_unique_id()) == str(name):
		# The client which this player represent will update the controls state, and notify it to everyone.
		inputs.update(global_position, rotation)
	
	if multiplayer.multiplayer_peer == null or is_multiplayer_authority():
		# The server updates the position that will be notified to the clients.
		synced_position = global_position
		synced_rotation = rotation
	else:
		# The client simply updates the position to the last known one.
		position = synced_position
		rotation = synced_rotation
	
	# Everybody runs physics. i.e. clients try to predict where they will be during the next frame.
	rotation = inputs.angle
	velocity = inputs.motion * MOTION_SPEED
	move_and_slide()

@rpc("call_local")
func set_player_name(value: String) -> void:
	$label.text = value
	# Assign a random color to the player based on its name.
	$label.modulate = gamestate.get_player_color(value)
	$sprite.modulate = Color(0.5, 0.5, 0.5) + gamestate.get_player_color(value)
