extends Node2D
const start_value_index = 10

func _ready() -> void:
	var snake = $snake
	snake.snake_head.value_index = start_value_index
	snake.snake_head.scale = BlocksCommon.get_scale(BlocksCommon.get_value(start_value_index)) * Vector2.ONE
	snake.add(2)		# add block 4
	snake.add(1)		# add block 2
