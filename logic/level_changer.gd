extends Node

@onready var current_level_layer = $Level0
var empty_map_positions = []

const DEFAULT_MAP_POSITIONS = 30

func _ready() -> void:
	log.ms_log(Log.level_changer, "LevelChanger ready")
	calc_empty_map_positions(DEFAULT_MAP_POSITIONS)
	pass 

func change_level(level: int) -> void:
	log.ms_log(Log.level_changer, "change_level level = %d" % level)

func get_max_npc_for_location() -> int:
	return 10

func get_empty_positions() -> Array:
	if empty_map_positions.is_empty():
		recalculate_empty_map_positions()
	return empty_map_positions

func recalculate_empty_map_positions() -> void:
	calc_empty_map_positions(empty_map_positions.size() if not empty_map_positions.empty() else DEFAULT_MAP_POSITIONS)

func reset_empty_map_positions() -> void:
	empty_map_positions.clear()

func calc_empty_map_positions(amount: int) -> void:
	log.ms_log(Log.level_changer, "calc_empty_map_positions amount = %d" % amount)
	empty_map_positions.clear()

	var used_loc = current_level_layer.get_used_cells()
	var min_location = used_loc[0]
	var max_location = used_loc.back()

	while amount > 0:
		var x = randi_range(min_location.x, max_location.x)
		var y = randi_range(min_location.y, max_location.y)
		if Vector2(x, y) not in used_loc:
			amount -= 1
			empty_map_positions.append(Vector2(x, y))
			log.ms_log(Log.level_changer, "added %s" % Vector2(x, y))

