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
@onready var motion_multiplier = 1.0

signal sig_game_over(id)

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
	block.set_value_index(value)	# important here for figure out right parent
	var parent_block = insert_block(block)
	$snake_blocks.add_child(block)
	block.block_init(parent_block, value, $snake_blocks)

func insert_block(block) -> CharacterBody2D:
	var parent_pos = find_parent_block(block)
	gamestate.ms_log("insert_block parent idx = %d" % parent_pos)
	var parent_block = blocks[parent_pos]
	parent_block.stored_positions.clear()
	blocks.insert(parent_pos + 1, block)
	return parent_block

func get_parent_block(block) -> CharacterBody2D:
	var idx = blocks.find(block)
	assert(idx >= 1, "Block is not valid!")
	return blocks[idx - 1]

func has_parent_block(block) -> bool:
	return block != snake_head

## Returns index for the most right element of snake such that 
## it is bigger that the block 
## Example: 8 4 (4) 2 2 find_parent_block(4) returns 2
##          so parent block has position 2.
func find_parent_block(block: Block) -> int:
	assert(not block.is_greater(snake_head), "Block can't be bigger than head")
	for idx in range(blocks.size() - 1, 0, -1):
		print("idx = ", idx)
		var b = blocks[idx]
		if b.is_equal(block) or b.is_greater(block): return idx
	return 0

func verify_doubling(block) -> void:
	var idx = blocks.find(block)
	assert(idx != -1, "Block is not present in blocks!")
	if check_doubling(idx):
		print("Doubling is initiated")
		$ChainDoublingTimer.wait_time = ChainDoubleStartTimeout
		perform_doubling(idx)
	#else:
		#print("No doubling")

func perform_doubling(idx) -> void:
	gamestate.ms_log("Perform doubling, idx = %d" % idx)
	assert(idx > 0, "Cant initiate doubing from head!")
	var block = blocks[idx - 1]
	block.do_double()

	# Remove initiator block
	var initiator_block = blocks[idx]
	initiator_block.queue_free()
	blocks.remove_at(idx)
	if blocks.size() == 1: snake_head.stored_positions.clear()
	if check_doubling(idx - 1) and $ChainDoublingTimer.is_stopped():
		$ChainDoublingTimer.start()

## Returns true a block at position index is equal to it's predecessor
func check_doubling(idx: int) -> bool:
	return idx > 0 and blocks[idx - 1].is_equal(blocks[idx])

func _on_chain_doubling_timer_timeout():
	$ChainDoublingTimer.wait_time /= 2.0
	for idx in range(1, blocks.size()):
		if check_doubling(idx): 
			perform_doubling(idx)
			return

## This snake is colliding with other snake's body
## result: 
## 1. do nothing if blocks are same
## 2. aquire other's snake body if that body is less
## 3. game over if other's body is greater
func collide_with_other_snake(body) -> void:
	if snake_head.is_equal(body):
		gamestate.ms_log("collide: do nothing")
	elif snake_head.is_greater(body):
		gamestate.ms_log("collide: aquire other")
		if body != body.snake.snake_head:
			aquire_block(body)
		else:
			call_deferred("add_player_block", body.get_value_index())
	else:
		gamestate.ms_log("collide: game over")
		game_over()

func aquire_block(block) -> void:
	gamestate.ms_log(name + ": aquire_block")
	var other_snake = block.snake
	other_snake.remove_block(block)
	var parent_block = insert_block(block)
	block.call_deferred("block_init", parent_block, block.get_value_index(), $snake_blocks)

func remove_block(block) -> void:
	gamestate.ms_log(name + ": remove_block")
	block.set_processing(false)
	#if block != snake_head:
		#var parent = get_parent_block(block)
		#parent.clear_stored_positions()
	blocks.erase(block)

func game_over() -> void:
	sig_game_over.emit(str(name).to_int())
	queue_free()

func is_movement_enabled() -> bool:
	return inputs.motion_enabled

func get_head_position():
	if snake_head.process_enabled:
		return snake_head.global_position
	else:
		return null
