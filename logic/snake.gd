extends Node2D

# Heads position
@export var synced_position := Vector2(500, 500)
# Heads rotation
@export var synced_rotation := 0.0

@onready var snake_head = $snake_blocks/head
@onready var inputs = $Inputs

@onready var BlockScene = preload("res://scenes/block.tscn")

@onready var blocks = [snake_head]

const ChainDoubleStartTimeout = 0.5
var chain_double_idx = -1

func _ready():
	if str(name).is_valid_int():
		$"Inputs/InputsSync".set_multiplayer_authority(str(name).to_int())
	snake_head.name = name
	for block in $snake_blocks.get_children():
		block.global_position = synced_position
		if block != snake_head:
			blocks.append(block)
	snake_head.inputs = inputs
	$ChainDoublingTimer.wait_time = ChainDoubleStartTimeout

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
		snake_head.global_position = synced_position
		snake_head.rotation = synced_rotation

@rpc("call_local")
func set_player_name(value: String) -> void:
	snake_head.set_player_name(value)

func add_player_block(value: int) -> void:
	var block = BlockScene.instantiate()
	block.value = value
	var parent_pos = find_parent_block(value)
	gamestate.ms_log("add_player_block parent idx = %d" % parent_pos)
	var parent_block = blocks[parent_pos]
	parent_block.stored_positions.clear()
	blocks.insert(parent_pos + 1, block)
	$snake_blocks.add_child(block)
	block.block_init(parent_block, value)

func get_parent_block(block):
	var idx = blocks.find(block)
	assert(idx >= 1, "Block is not valid!")
	return blocks[idx - 1]

func has_parent_block(block):
	return block != snake_head

## Returns index for the rightmost element such that it's value >= value 
## Example: 8 4 (4) 2 2 find_parent_block(4) returns 2
func find_parent_block(value) -> int:
	assert(value <= snake_head.value, "Wrong value")
	for idx in range(blocks.size() - 1, 0, -1):
		var block = blocks[idx]
		if block.value >= value: return idx
	return 0

func verify_doubling(block):
	var idx = blocks.find(block)
	assert(idx != -1, "Block is not present in blocks!")
	if check_doubling(idx):
		print("CD - True")
		$ChainDoublingTimer.wait_time = ChainDoubleStartTimeout
		perform_doubling(idx)
	else:
		print("No doubling")

func perform_doubling(idx):
	gamestate.ms_log("Perform doubling, idx = %d" % idx)
	assert(idx > 0, "Cant initiate doubing from head!")
	var block = blocks[idx - 1]
	block.value += 1
	block.update_text_label()
	# Remove initiator block
	var initiator_block = blocks[idx]
	initiator_block.queue_free()
	blocks.remove_at(idx)
	if blocks.size() == 1: snake_head.stored_positions.clear()
	if check_doubling(idx - 1) and $ChainDoublingTimer.is_stopped(): 
		chain_double_idx = idx - 1
		$ChainDoublingTimer.start()

## Returns true if a block before one with index idx has same value
func check_doubling(idx: int):
	return idx > 0 and blocks[idx - 1].value == blocks[idx].value

func _on_chain_doubling_timer_timeout():
	$ChainDoublingTimer.wait_time /= 2.0
	if check_doubling(chain_double_idx): 
		perform_doubling(chain_double_idx)
	else:
		chain_double_idx = -1

func collide_with_other_snake(body) -> void:
	# Body is not a head
	gamestate.ms_log("Will aquire block")
	#if body.has_parent():
		##aquire_block(body)
	## Body is head
	#else:
		##aquire_block(body)

func aquire_block(body):
	add_player_block(2)

func game_over():
	queue_free()

func is_movement_enabled() -> bool:
	return inputs.motion_enabled
