extends Node

@onready var current_level_layer = $Level0
var empty_map_positions = []

const DEFAULT_MAP_POSITIONS = 7
const offset_x = 64
const offset_y = 64

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
	calc_empty_map_positions(empty_map_positions.size() if not empty_map_positions.is_empty() else DEFAULT_MAP_POSITIONS)

func reset_empty_map_positions() -> void:
	empty_map_positions.clear()

func calc_empty_map_positions(amount: int) -> void:
	log.ms_log(Log.level_changer, "calc_empty_map_positions amount = %d" % amount)
	empty_map_positions.clear()

	var used_loc = current_level_layer.get_used_cells()
	
	log.ms_log(Log.level_changer, "used_loc size = %d" % used_loc.size())
	var min_location = used_loc[0]
	var max_location = used_loc.back()
	log.ms_log(Log.level_changer, "min_location = %s, max_location = %s" % [ min_location, max_location ])

	while amount > 0:
		var x = randi_range(min_location.x, max_location.x)
		var y = randi_range(min_location.y, max_location.y)
		var map_pos = Vector2i(x, y)
		if map_pos not in used_loc:
			amount -= 1
			var pos = 1.25 * current_level_layer.map_to_local(map_pos)
			empty_map_positions.append(pos)
			log.ms_log(Log.level_changer, "added %s : %s" % [map_pos, pos])
