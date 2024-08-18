extends CharacterBody2D

## The player's movement speed (in pixels per second).
const MOTION_SPEED = 90.0
var motion_multiplier = 1.0

## The distance between stored positions (pixels).
const STORED_DISTANCE = 30.0

@export var snake: Node2D = null
@export var value: int = 1
@onready var inputs: Node = null

@onready var stored_positions: Array = []

var update_position_time: float = 0.

func _ready() -> void:
	update_text_label()

func block_init(block_parent: CharacterBody2D, block_value) -> void:
	self.global_position = block_parent.global_position
	self.rotation = block_parent.rotation
	self.snake = block_parent.snake
	self.value = block_value
	self.update_text_label()
	$ImmuteTimer.start(0.5)

func _physics_process(delta):
	# Everybody runs physics. i.e. clients try to predict where they will be during the next frame.
	if inputs != null and not has_parent_block():
		if not inputs.motion_enabled:
			motion_multiplier = 0.0
		else:
			motion_multiplier = 1.0
			
		rotation = inputs.angle
		velocity = inputs.motion * MOTION_SPEED * motion_multiplier
	elif has_parent_block():
		var parent_block = snake.get_parent_block(self)
		parent_block.update_motion_multiplier()
		update_position_time += delta
		if update_position_time > STORED_DISTANCE / MOTION_SPEED:
			update_position_time = 0.
			if snake.is_movement_enabled(): parent_block.update_stored_positions()
		var vd = (parent_block.get_last_stored_position() - global_position).normalized()
		velocity = vd * MOTION_SPEED * parent_block.motion_multiplier
		if get_total_distance() < 148.0:
			velocity *= 0.5
		rotation = lerp_angle(rotation, -vd.angle_to(Vector2.UP), delta * 6.0)
		if global_position.distance_to(parent_block.get_last_stored_position()) < 5.:
			parent_block.remove_last_stored_position()

	move_and_slide()
	queue_redraw()

func get_parent_block(): 
	assert(snake != null, "Snake shall be set")
	return snake.get_parent_block(self)

@rpc("call_local")
func set_player_name(value: String) -> void:
	$label.text = value
	# Assign a random color to the player based on its name.
	$label.modulate = gamestate.get_player_color(value)
	$sprite.modulate = Color(0.5, 0.5, 0.5) + gamestate.get_player_color(value)

func update_stored_positions():
	if not stored_positions.is_empty():
		if stored_positions.front().distance_to(global_position) < 2.5:
			return
	stored_positions.append(global_position)
	$DebugLabel.text = str(stored_positions.size())

func get_last_stored_position():
	if stored_positions.is_empty(): return global_position
	return stored_positions.front()

func remove_last_stored_position():
	stored_positions.pop_front()

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
	
func update_motion_multiplier() -> void:
	if has_parent_block(): 
		motion_multiplier = snake.get_parent_block(self).motion_multiplier

@rpc("authority", "call_local", "reliable")
func bump_with_block(block_value: int) -> void:
	if not $ImmuteTimer.is_stopped():
		gamestate.ms_log("%s The block is immuted" % name)
		return
	gamestate.ms_log("%s Player %s enters into npc block value: %d" % [name, str(name), block_value])
	assert(value >= block_value, "Cannot eat bigger block")
	snake.call_deferred("add_player_block", block_value)

func collide_with_head():
	gamestate.ms_log("%s The collision with other head for a block" % name)
	#if not has_parent(): snake.game_over()

func has_parent_block() -> bool:
	return snake.has_parent_block(self)

func update_text_label() -> void:
	$TextLabel.text = gamestate.get_block_label_text(value)

func _draw():
	for a in stored_positions:
		draw_circle(to_local(a), 4, Color.YELLOW_GREEN)

## + Proper doubling
## + Place in right position
## Eat part of snake
## Eat other snake head

func _on_immute_timer_timeout():
	snake.verify_doubling(self)
