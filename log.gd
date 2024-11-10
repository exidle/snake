
extends Node
class_name Log

class Config:
	var enabled: bool
	var tag: String

	func _init(e: bool = true, t: String = "") -> void:
		enabled = e
		tag = t

var logging_to_file = false

func _ready() -> void:
	print("Log ready")
	var userargs = OS.get_cmdline_user_args()
	var log_suffix = ""
	for arg in userargs:
		if arg.begins_with("--log"):
			log_suffix = arg.get_slice("=", 1)
			print("Log suffix: " + log_suffix)

	if not create_log_file(log_suffix):
		print("Log file not created")
		print("Error: ", FileAccess.get_open_error())
		print("Logging to file is disabled")
	else:
		logging_to_file = true

## Logging parameters
const default = [true, "default"] 
const respawn = [false, "respawn"] 
const best_score = [false, "best_score"]
const collision = [false, "collision"] 
const snake_structure = [false, "snake_structure"]
const doubling = [false, "doubling"] 
const debug_elements = [true, "debug_elements"]
const camera = [false, "camera"] 
const spawn_npc = [false, "spawn_npc"] 
const level_changer = [true, "level_changer"]

var logs_folder: String = "user://logs/"
var log_file: FileAccess = null

## logging function
func ms_log(config: Array, v: String):
	var enabled = config[0]
	if not enabled and not logging_to_file: return
	var side = "[client]"
	if is_multiplayer_authority(): side = "[server]"
	var tag = config[1]
	var line = str(Time.get_ticks_msec()) + '# ' + side + ' [' + tag + ']: ' + v
	## log to file everything
	if logging_to_file:
		log_file.store_line(line)
		log_file.flush()
	if enabled:
		print(line)

func get_date() -> String:
	var date = Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [date.year, date.month, date.day]

func get_time() -> String:
	var time = Time.get_time_dict_from_system()
	return "%02d:%02d:%02d" % [time.hour, time.minute, time.second]

func get_file_name(log_suffix: String) -> String:
	var filename = "user://logs/" + get_date() 
	if log_suffix != "":
		filename += "_" + log_suffix
	filename += ".log"
	return filename

func create_log_file(log_suffix: String) -> bool:
	var filename = get_file_name(log_suffix)	

	log_file = FileAccess.open(filename, FileAccess.READ_WRITE)
	if FileAccess.get_open_error() == ERR_FILE_NOT_FOUND:
		log_file = FileAccess.open(filename, FileAccess.WRITE)
	var result = FileAccess.get_open_error() == OK

	if result:
		log_file.seek_end()
		log_file.store_line("------- Log created on " + get_date() + " at " + get_time() + " -------")
	return result
