extends Area2D

@export var snake: Node2D

## The head collision detector is located on the head of snake
func _on_body_entered(body):
	if not is_multiplayer_authority(): return
	if body.is_in_group("snake_blocks") and body.snake != snake:
		if not body.is_processing_enabled(): return
		var body_value = body.get_value_index()
		log.ms_log(Log.collision, "%s Snake head collides with block (%d)" % [name, body_value])
		var value_index = body.get_value_index()

		var lambda = func(sn, vi, bo):
			sn.add.rpc(vi)
			bo.snake.delete.rpc(vi)

		if body.snake.snake_head == body:
			if snake.snake_head.is_greater(body):
				lambda.call(snake, value_index, body)
		else:
			if snake.snake_head.is_equal(body) or snake.snake_head.is_greater(body):
				lambda.call(snake, value_index, body)

func _on_body_exited(_body):
	pass
