extends CharacterBody2D

## The player's movement speed (in pixels per second).
const MOTION_SPEED = 90.0

## The distance between stored positions (pixels).
const STORED_DISTANCE = 30.0

@export var parent_block: CharacterBody2D = null
@export var snake: Node2D = null
@onready var inputs: Node = null

@onready var stored_positions: Array = []

var update_position_time: float = 0.

func _physics_process(delta):
	# Everybody runs physics. i.e. clients try to predict where they will be during the next frame.
	if inputs != null and parent_block == null:
		rotation = inputs.angle
		velocity = inputs.motion * MOTION_SPEED
	elif parent_block != null:
		update_position_time += delta
		if update_position_time > STORED_DISTANCE / MOTION_SPEED:
			update_position_time = 0.
			parent_block.update_stored_positions()
		var vd = (parent_block.get_last_stored_position() - global_position).normalized()
		velocity = vd * MOTION_SPEED
		if get_total_distance() < 148.0:
			velocity *= 0.5
		rotation = lerp_angle(rotation, -vd.angle_to(Vector2.UP), delta * 6.0)
		if global_position.distance_to(parent_block.get_last_stored_position()) < 5.:
			parent_block.remove_last_stored_position()

	move_and_slide()
	queue_redraw()

@rpc("call_local")
func set_player_name(value: String) -> void:
	$label.text = value
	# Assign a random color to the player based on its name.
	$label.modulate = gamestate.get_player_color(value)
	$sprite.modulate = Color(0.5, 0.5, 0.5) + gamestate.get_player_color(value)

func update_stored_positions():
	stored_positions.append(global_position)

func get_last_stored_position():
	if stored_positions.is_empty(): return global_position
	return stored_positions.front()

func remove_last_stored_position():
	stored_positions.pop_front()

## Returns cumullative distance from a parent's center to center of the block
func get_total_distance():
	assert(parent_block != null, "Can't be called on head block!")
	var d:float = 0.
	var c: Vector2 = global_position
	for x in parent_block.stored_positions:
		d += c.distance_to(x)
		c = x
	d += c.distance_to(parent_block.global_position)
	return d

func _draw():
	for a in stored_positions:
		draw_circle(to_local(a), 4, Color.YELLOW_GREEN)
