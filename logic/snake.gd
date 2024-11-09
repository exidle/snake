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
signal sig_score_updated(id, score)

var return_camera_cb = null

const collision: bool = true

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

func get_player_name() -> String:
	var a_name = snake_head.get_block_name()
	return a_name
#return a_name if not gamestate.is_main_player(a_name) else "You" 

func get_player_score() -> int:
	var score = 0
	for x in blocks:
		score += BlocksCommon.get_value(x.value_index)
	return score

func emit_udpate_player_score() -> void:
	log.ms_log(Log.best_score, "emit_udpate_player_score")
	sig_score_updated.emit(str(name).to_int(), get_player_score())

@rpc("call_local", "reliable")
func add(value: int) -> void:
	log.ms_log(Log.snake_structure, "add value = %d" % value)
	var block = BlockScene.instantiate()
	block.set_processing(false)
	block.visible = false
	block.set_value_index(value)	# important here for figure out right parent
	var my_lambda = func (bl, va):
		log.ms_log(Log.snake_structure, "deferred call add block with value = %d" % va)
		var parent_block = insert_block(bl)
		$snake_blocks.add_child(bl)
		bl.block_init(parent_block, va, $snake_blocks)

	my_lambda.call_deferred(block, value)

@rpc("call_local", "reliable")
func delete(value: int) -> void:
	log.ms_log(Log.snake_structure, "delete value = %d" % value)
	var block_id = -1
	for idx in range(blocks.size()):
		if blocks[idx].get_value_index() == value: 
			block_id = idx
			break
	assert(block_id > -1, "Not available block!")
	if blocks[block_id] == snake_head:
		game_over()
		return
	var my_lambda = func(bl, bl_id):
		log.ms_log(Log.snake_structure, "deferred call delete block id = %d" % bl_id)
		var bl_ref = bl[bl_id]
		bl.remove_at(bl_id)
		$snake_blocks.remove_child(bl_ref)
	my_lambda.call_deferred(blocks, block_id)

func insert_block(block) -> CharacterBody2D:
	var parent_pos = find_parent_block(block)
	log.ms_log(Log.snake_structure, "insert_block parent idx = %d" % parent_pos)
	var parent_block = blocks[parent_pos]
	parent_block.stored_positions.clear()
	blocks.insert(parent_pos + 1, block)
	emit_udpate_player_score()
	verify_chain_doubling()
	return parent_block

func verify_chain_doubling() -> void:
	log.ms_log(Log.snake_structure, "verify_chain_doubling")
	if not $ChainDoublingTimer.is_stopped(): return
	log.ms_log(Log.snake_structure, "verify_chain_doubling is stopped")
	var idx = check_doubling()
	if idx != -1:
		perform_doubling(idx)

func get_parent_block(block) -> CharacterBody2D:
	var idx = blocks.find(block)
	if idx == -1:
		return null
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
		var b = blocks[idx]
		if b.is_equal(block) or b.is_greater(block): return idx
	return 0

func perform_doubling(idx) -> void:
	assert(idx > 0, "Cant initiate doubing from head!")
	var initiator_block = blocks[idx]
	initiator_block.set_processing(false)

	var block = blocks[idx - 1]
	log.ms_log(Log.doubling, "Perform doubling from block %d value(%d)" % [idx - 1, block.get_value_index()])
	block.do_double()

	# Remove initiator block
	log.ms_log(Log.doubling, "Remove block %d value(%d)" % [idx, initiator_block.get_value_index()])

	initiator_block.queue_free()
	blocks.remove_at(idx)

	emit_udpate_player_score()
	#sort_blocks()
	if blocks.size() == 1: snake_head.stored_positions.clear()
	if check_doubling() and $ChainDoublingTimer.is_stopped():
		log.ms_log(Log.doubling, "Start chain doubling timer")
		$ChainDoublingTimer.start()

func sort_blocks() -> void:
	log.ms_log(Log.snake_structure, "sort_blocks")
	blocks.slice(1).sort_custom(func (a, b): return a.is_greater(b))

func check_doubling() -> int:
	for idx in range(blocks.size()):
		log.ms_log(Log.snake_structure, "check_doubling idx = %d" % idx)
		if idx > 0 and blocks[idx - 1].is_equal(blocks[idx]): 
			return idx
	return -1

func _on_chain_doubling_timer_timeout():
	$ChainDoublingTimer.wait_time /= 2.0
	var idx = check_doubling() 
	if idx != -1:
		log.ms_log(Log.snake_structure, "Chain doubling timer timeout idx = %d" % idx)
		perform_doubling(idx)

func collide_with_other_snake(_body) -> void:
	pass

func remove_block(block) -> void:
	log.ms_log(Log.snake_structure, name + ": remove_block")
	block.set_processing(false)
	#if block != snake_head:
		#var parent = get_parent_block(block)
		#parent.clear_stored_positions()
	blocks.erase(block)

func game_over() -> void:
	sig_game_over.emit(str(name).to_int())
	dettach_camera()
	queue_free()

func is_movement_enabled() -> bool:
	return inputs.motion_enabled

func get_head_position():
	if snake_head.process_enabled:
		return snake_head.global_position
	else:
		return null

func dettach_camera() -> void:
	if null == return_camera_cb: return
	for child in snake_head.get_children():
		if child is Camera2D:
			return_camera_cb.call(child)

func attach_main_camera(camera: Camera2D, callback: Callable) -> void:
	return_camera_cb = callback
	camera.reparent(snake_head)
	camera.make_current()

