extends Node2D

# Heads position
@export var synced_position := Vector2(500, 500)
# Heads rotation
@export var synced_rotation := 0.0

@onready var snake_head = $snake_blocks/head
@onready var inputs = $Inputs

@onready var BlockScene = preload("res://scenes/block.tscn")

func _ready():
	if str(name).is_valid_int():
		$"Inputs/InputsSync".set_multiplayer_authority(str(name).to_int())
	snake_head.name = name
	for block in $snake_blocks.get_children():
		block.global_position = synced_position
	snake_head.inputs = inputs

func _physics_process(_delta):
	if multiplayer.multiplayer_peer == null or str(multiplayer.get_unique_id()) == str(name):
		# The client which this player represent will update the controls state, and notify it to everyone.
		inputs.update(snake_head.global_position, snake_head.rotation)
	
	#if inputs.motion_enabled:
	if multiplayer.multiplayer_peer == null or is_multiplayer_authority():
		# The server updates the position that will be notified to the clients.
		synced_position = snake_head.global_position
		synced_rotation = snake_head.rotation
	else:
		# The client simply updates the position to the last known one.
		snake_head.position = synced_position
		snake_head.rotation = synced_rotation

@rpc("call_local")
func set_player_name(value: String) -> void:
	snake_head.set_player_name(value)

func add_player_block() -> void:
	var block = BlockScene.instantiate()
	var block_parent = $snake_blocks.get_child($snake_blocks.get_child_count() - 1)
	block.global_position = block_parent.global_position
	block.rotation = block_parent.rotation
	block.parent_block = block_parent
	block.snake = self
	$snake_blocks.add_child(block)
