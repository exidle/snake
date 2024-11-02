
extends Node
class_name Log

class Config:
	var enabled: bool
	var tag: String

	func _init(e: bool = true, t: String = "") -> void:
		enabled = e
		tag = t

## Logging parameters
const default = [true, "default"] 
const respawn = [false, "respawn"] 
const best_score = [false, "best_score"]
const collision = [true, "collision"] 
const snake_structure = [false, "snake_structure"]
const doubling = [false, "doubling"] 
const debug_elements = [false, "debug_elements"]
const camera = [false, "camera"] 
const spawn_npc = [false, "spawn_npc"] 

## logging fun
func ms_log(config: Array, v: String):
	var enabled = config[0]
	if not enabled: return
	var side = "[client]"
	if is_multiplayer_authority(): side = "[server]"
	var tag = config[1]
	print(str(Time.get_ticks_msec()), '# ', side, ' [', tag, ']: ', v)
