extends Node2D

func _ready() -> void:
	var snake = $snake

	snake.add(1)
	await get_tree().create_timer(1.2).timeout

	snake.add(2)
	print_snake(snake)
	await get_tree().create_timer(1.2).timeout
	snake.add(2)
	print_snake(snake)
	await get_tree().create_timer(0.452).timeout
	snake.add(2)
	print_snake(snake)
	await get_tree().create_timer(0.33).timeout
	snake.add(1)
	print_snake(snake)
	await get_tree().create_timer(0.583).timeout
	snake.add(2)
	print_snake(snake)
	await get_tree().create_timer(0.300).timeout
	snake.add(2)
	print_snake(snake)
	await get_tree().create_timer(0.383).timeout
	snake.add(2)
	print_snake(snake)
	await get_tree().create_timer(0.183).timeout
	snake.add(2)
	print_snake(snake)
	await get_tree().create_timer(0.602).timeout
	snake.add(3)
	#await get_tree().create_timer(2.1).timeout
	print_snake(snake)
	## 5 - 3 - 1 
	await get_tree().create_timer(0.151).timeout
	snake.add(2)
	print_snake(snake)
	await get_tree().create_timer(0.5134).timeout
	snake.add(2)
	print_snake(snake)
	await get_tree().create_timer(0.183).timeout
	snake.add(3)
	print_snake(snake)
	await get_tree().create_timer(0.501).timeout
	snake.add(2)
	print_snake(snake)
	await get_tree().create_timer(0.66).timeout
	snake.add(3)
	print_snake(snake)
	await get_tree().create_timer(0.100).timeout
	snake.add(1)
	print_snake(snake)
	await get_tree().create_timer(0.368).timeout
	snake.add(2)
	print_snake(snake)
	await get_tree().create_timer(2.183).timeout
	print_snake(snake)

	await get_tree().create_timer(0.183).timeout
	snake.add(2)
	print_snake(snake)
	await get_tree().create_timer(0.133).timeout
	snake.add(1)
	print_snake(snake)
	await get_tree().create_timer(0.518).timeout
	snake.add(2)
	print_snake(snake)
	await get_tree().create_timer(0.116).timeout
	snake.add(1)
	print_snake(snake)
	await get_tree().create_timer(0.467).timeout
	snake.add(1)
	print_snake(snake)
	await get_tree().create_timer(0.167).timeout
	snake.add(3)
	print_snake(snake)
	await get_tree().create_timer(0.217).timeout
	snake.add(1)
	print_snake(snake)
	## 6 - 5 - 2
	await get_tree().create_timer(0.2952).timeout
	snake.add(3)
	await get_tree().create_timer(0.167).timeout
	snake.add(2)

	await get_tree().create_timer(2).timeout

	print_snake(snake)
	verify(snake)

func print_snake(snake) -> void:
	var blocks = snake.blocks
	var s = "snake(" + str(blocks.size()) + "): "
	for block in blocks:
		s += str(block.get_value_index()) + " "
	print(s)

func verify(snake) -> void:
	var blocks = snake.blocks
	for idx in range(1, blocks.size() - 1):
		var parent = blocks[idx - 1]
		var child = blocks[idx]
		assert(parent.is_greater(child), "Block %d is not valid!" % idx)
	print("all test pass")

#100# [server] [snake_structure]: add value = 1
#368# [server] [snake_structure]: add value = 2
#183# [server] [snake_structure]: add value = 2
#133# [server] [snake_structure]: add value = 1
#518# [server] [snake_structure]: add value = 2
#116# [server] [snake_structure]: add value = 1
#467# [server] [snake_structure]: add value = 1
#167# [server] [snake_structure]: add value = 3
#217# [server] [snake_structure]: add value = 1
#2952# [server] [snake_structure]: add value = 3
#167# [server] [snake_structure]: add value = 2
