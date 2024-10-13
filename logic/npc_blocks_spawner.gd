extends MultiplayerSpawner

func _init() -> void:
	spawn_function = _spawn_npc

func _spawn_npc(data: Array) -> RigidBody2D:
	# check data
	if data.size() != 2 or typeof(data[0]) != TYPE_VECTOR2 or typeof(data[1]) != TYPE_INT:
		return null
	var npc = preload("res://scenes/NpcBlock.tscn").instantiate()
	npc.init_block(data[0], data[1])
	return npc

func _on_despawned(_node: Node) -> void:
	gamestate.ms_log("despawned!")
