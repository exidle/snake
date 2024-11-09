class_name Block
extends CharacterBody2D

## The player's movement speed (in pixels per second).
const MOTION_SPEED = 290.0
const K_SPEEDUP_FRACTION = 0.3

## The distance between stored positions (pixels).
const STORED_DISTANCE = 30.0
const BETWEEN_BLOCKS_DISTANCE = 128 + 20

@export var snake: Node2D = null
@export var value_index: int = 1
@onready var inputs: Node = null

@onready var stored_positions: Array = []
@onready var process_enabled = true

var update_position_time: float = 0.

func _ready() -> void:
	get_tree().physics_interpolation = true
	pre_start_configure_debug()
	update_text_label()

func pre_start_configure_debug():
	if OS.is_debug_build():
		$DebugLabel.visible = true
	else:
		$DebugLabel.visible = false

func block_init(block_parent: CharacterBody2D, block_value, tree_node) -> void:
	reset_physics_interpolation()
	assert(block_parent != null)
	self.add_to_group("snake_blocks")
	self.reparent(tree_node)
	self.global_position = block_parent.global_position
	self.rotation = block_parent.rotation
	self.scale = BlocksCommon.get_scale(BlocksCommon.get_value(value_index)) * Vector2.ONE
	self.snake = block_parent.snake
	self.value_index = block_value
	$label.text = ""
	self.update_text_label()
	self.visible = true
	stored_positions.clear()
	$ImmuteTimer.start(0.5)
	process_enabled = true

func set_processing(enabled):
	process_enabled = enabled

func is_processing_enabled():
	return process_enabled

func _physics_process(delta):
	if !process_enabled: return
	# Everybody runs physics. i.e. clients try to predict where they will be during the next frame.
	if inputs != null and not has_parent_block():
		if not inputs.motion_enabled:
			snake.motion_multiplier = 0.0
		else:
			snake.motion_multiplier = 1.0
			
		rotation = inputs.angle
		velocity = inputs.motion * MOTION_SPEED * snake.motion_multiplier
	elif has_parent_block():
		var parent_block = snake.get_parent_block(self)
		if parent_block == null: return
		update_position_time += delta
		if update_position_time > STORED_DISTANCE / MOTION_SPEED:
			update_position_time = 0.
			if snake.is_movement_enabled(): parent_block.update_stored_positions()
		var vd = (parent_block.get_last_stored_position() - global_position).normalized()
		velocity = vd * MOTION_SPEED * snake.motion_multiplier
		if get_total_distance() < BETWEEN_BLOCKS_DISTANCE:
			velocity *= 0.
		if get_total_distance() > BETWEEN_BLOCKS_DISTANCE + 20:
			velocity *= 2.
		## To avoid a following block stop because of collision
		if get_total_distance() > BETWEEN_BLOCKS_DISTANCE + 40:
			reset_physics_interpolation()
			global_position = parent_block.global_position
			parent_block.clear_stored_positions()
		rotation = lerp_angle(rotation, -vd.angle_to(Vector2.UP), delta * 6.0)
		if global_position.distance_to(parent_block.get_last_stored_position()) < 5.:
			parent_block.remove_last_stored_position()

	move_and_slide()
	if OS.is_debug_build():
		queue_redraw()

@rpc("call_local")
func set_player_name(player_name: String) -> void:
	$label.text = player_name
	# Assign a random color to the player based on its name.
	$label.modulate = gamestate.get_player_color(player_name)
	var player_color = gamestate.get_player_color(player_name)
	$block_kant.modulate = Color(0.5, 0.5, 0.5) + player_color
	$block_sprite.modulate = Color(0.2, 0.2, 0.2) + player_color

func get_block_name() -> String:
	return $label.text

func update_stored_positions():
	if not stored_positions.is_empty():
		if stored_positions.back().distance_to(global_position) < 2.5:
			return
	stored_positions.append(global_position)
	$DebugLabel.text = str(stored_positions.size())

func get_last_stored_position():
	if stored_positions.is_empty(): return global_position
	return stored_positions.front()

func remove_last_stored_position():
	stored_positions.pop_front()

func clear_stored_positions():
	stored_positions.clear()

## Returns cumullative distance from a parent's center to center of the block
func get_total_distance():
	var parent_block = snake.get_parent_block(self)
	var d:float = 0.
	var c: Vector2 = global_position
	for x in parent_block.stored_positions:
		d += c.distance_to(x)
		c = x
	d += c.distance_to(parent_block.global_position)
	return d

func bump_with_block(block_value: int) -> void:
	assert(self.is_multiplayer_authority(), "Only server can call this function")
	if not $ImmuteTimer.is_stopped():
		log.ms_log(Log.collision, "%s The block is immuted" % name)
		return
	log.ms_log(Log.collision, "%s Player %s (%d) enters into npc block (%d)" % [name, str(name), value_index, block_value])
	assert(value_index >= block_value, "Cannot eat bigger block")
	snake.add.rpc(block_value)

func collide_with_head():
	log.ms_log(Log.collision, "%s The collision with other head for a block" % name)
	#if not has_parent(): snake.game_over()

func has_parent_block() -> bool:
	return snake.has_parent_block(self)

func update_text_label() -> void:
	# Number value label
	$TextLabel.text = BlocksCommon.get_block_value_as_text(value_index)

func _draw():
	if not OS.is_debug_build(): return
	for a in stored_positions:
		draw_circle(to_local(a), 4, Color.YELLOW_GREEN)

func _on_immute_timer_timeout():
	pass

func set_value_index(val_index: int):
	value_index = val_index

func get_value_index() -> int:
	return value_index

func is_equal(block: Block) -> bool:
	return value_index == block.value_index

func is_greater(block: Block) -> bool:
	return self.value_index > block.value_index

func do_double():
	log.ms_log(Log.snake_structure, "do_double from value %d" % value_index)
	value_index += 1
	self.scale = BlocksCommon.get_scale(BlocksCommon.get_value(value_index)) * Vector2.ONE
	update_text_label()
	
