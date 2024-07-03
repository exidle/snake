extends Node2D

const ROT_DELTA: float = PI / 36.0

enum INPUT_TYPE {MOUSE, KEYBOARD}
@export var input_type: INPUT_TYPE = INPUT_TYPE.MOUSE

@export var motion := Vector2():
	set(value):
		# This will be sent by players, make sure values are within limits.
		motion = clamp(value, Vector2(-1, -1), Vector2(1, 1))

@export var angle := 0.0

func update(center: Vector2, rot: float) -> void:
	match input_type:
		# Mouse input
		INPUT_TYPE.MOUSE:
			var dir = (get_global_mouse_position() - center).normalized()
			motion = dir
			angle = -dir.angle_to(Vector2.UP)
	
		# Keyboard input
		INPUT_TYPE.KEYBOARD:
			var tot_rot = rot
			if Input.is_action_pressed(&"rotate_ccw"):
				# build vector rotatated 15' ccw
				tot_rot = rot - ROT_DELTA
			if Input.is_action_pressed(&"rotate_cw"):
				tot_rot = rot + ROT_DELTA
			motion = Vector2.UP.rotated(tot_rot)
			angle = tot_rot
	
		

