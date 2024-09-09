extends MultiplayerSpawner

func _init() -> void:
	spawn_function = _spawn_npc

func _spawn_npc(data: Array) -> CharacterBody2D:
	# check data
	if data.size() != 2 or typeof(data[0]) != TYPE_VECTOR2 or typeof(data[1]) != TYPE_INT:
		return null
	var npc = preload("res://scenes/NpcBlock.tscn").instantiate()
	npc.position = data[0] #Vector2(500 + randi_range(-100, 100), 500 + randi_range(-100, 100))
	npc.value = data[1]
	return npc


func _on_despawned(_node: Node) -> void:
	gamestate.ms_log("despawned!")
	pass # Replace with function body.
