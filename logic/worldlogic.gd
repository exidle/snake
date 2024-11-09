extends Node2D

@onready var npc_value = 1
@onready var camera_update_timeout: float = 0.

@onready var debug_canvas_layer = $DebugCanvasLayer
@onready var respawn_ui = $CanvasLayer
@onready var score_table = $HUD/Players/ScoreTable
@onready var level_changer = $LevelChanger
@onready var npc_blocks = $NpcBlocks

var camera_player: Node2D = null

func _ready():
	pre_start_configure_debug()
	if not is_multiplayer_authority(): debug_canvas_layer.get_node("CreateNpcBtn").disabled = true
	updateCreateNpcBtnLabel()
	update_best_3()

func pre_start_configure_debug():
	if OS.is_debug_build():
		debug_canvas_layer.visible = true
		$DebugCamera.visible = true
	else:
		debug_canvas_layer.visible = false
		$DebugCamera.visible = false

func _on_create_npc_btn_pressed():
	#debug_canvas_layer.get_node("CreateNpcBtn.set_focus_mode(Control.FOCUS_NONE)
	#var npc = preload("res://scenes/NpcBlock.tscn").instantiate()
	#npc.position = Vector2(500, 500)
	log.ms_log(Log.debug_elements, "btn pressed to create npc")
	#$NpcBlocks.add_child(npc)
	create_npc(npc_value)

func create_npc(value: int) -> void:
	log.ms_log(Log.debug_elements, "Created npc")
	debug_canvas_layer.get_node("CreateNpcBtn").set_focus_mode(Control.FOCUS_NONE)
	var npc_position = Vector2(500 + randi_range(-100, 100), 500 + randi_range(-100, 100))
	$NpcBlocksSpawner.spawn([npc_position, value])

func _on_h_slider_value_changed(value):
	npc_value = value
	updateCreateNpcBtnLabel()

func updateCreateNpcBtnLabel():
	debug_canvas_layer.get_node("CreateNpcBtn").text = "CreateNPC[" + str(npc_value) + "]"

func _process(delta: float) -> void:
	if camera_player != null:
		$Camera2D.global_position = camera_player.snake_head.global_position

	const CAMERA_SPEED = 800
	if Input.is_action_pressed("CameraDown"):
		$DebugCamera.position.y += delta * CAMERA_SPEED
	if Input.is_action_pressed("CameraUp"):
		$DebugCamera.position.y -= delta * CAMERA_SPEED
	if Input.is_action_pressed("CameraLeft"):
		$DebugCamera.position.x -= delta * CAMERA_SPEED
	if Input.is_action_pressed("CameraRight"):
		$DebugCamera.position.x += delta * CAMERA_SPEED
	
	const CAMERA_MIN_VALUE = Vector2(0.2, 0.2)
	const CAMERA_MAX_VALUE = Vector2(6, 6)
	
	if Input.is_action_just_pressed("CameraZoomOut"):
		var zoom = $DebugCamera.zoom + 0.33*Vector2.ONE
		$DebugCamera.zoom = clamp(zoom, CAMERA_MIN_VALUE, CAMERA_MAX_VALUE)
		
	if Input.is_action_just_pressed("CameraZoomIn"):
		var zoom = $DebugCamera.zoom - 0.33*Vector2.ONE
		$DebugCamera.zoom = clamp(zoom, CAMERA_MIN_VALUE, CAMERA_MAX_VALUE)
	
	if is_multiplayer_authority() and $NpcBlocks.get_child_count() < 15 and $NpcSpawnTimer.is_stopped():
		$NpcSpawnTimer.start()

@rpc("authority", "call_local", "reliable")
func set_camera_player(player_name: String) -> void:
	log.ms_log(Log.camera, "Set camera player")
	for player in $Players.get_children():
		if player.name == player_name:
			camera_player = player
			break
	log.ms_log(Log.camera, "Camera player is: " + player_name)

func camera_player_died() -> void:
	log.ms_log(Log.camera, "Camera player died")
	camera_player = null

func _on_set_camera_btn_pressed() -> void:
	var debug_camera = $DebugCamera
	var main_camera = $Camera2D
	debug_camera.enabled = true
	main_camera.enabled = false
	debug_camera.make_current()
	

func _on_set_mc_camera_btn_pressed() -> void:
	var debug_camera = $DebugCamera
	var main_camera = $Camera2D
	debug_camera.enabled = false
	main_camera.enabled = true
	debug_camera.position = Vector2.ZERO
	main_camera.make_current()

func _on_npc_spawn_timer_timeout() -> void:
	log.ms_log(Log.spawn_npc, "On spawn TO")
	if npc_blocks.get_child_count() > level_changer.get_max_npc_for_location():
		log.ms_log(Log.spawn_npc, "Too many NPCs on location")
		return
	for pos in level_changer.get_empty_positions():
		gamestate.spawn_npc(pos, 1, 3)

func _on_check_npc_amount_btn_pressed() -> void:
	log.ms_log(Log.debug_elements, "Theree are currently:  %d" % $NpcBlocks.get_child_count())

func main_player_died() -> void:
	log.ms_log(Log.respawn, "Main player died")
	camera_player = null
	respawn_ui.show()

func _on_req_respawn_button_pressed() -> void:
	gamestate.respawn.rpc(multiplayer.get_unique_id())
	respawn_ui.hide()

@rpc("authority", "call_local")
func update_best_3():
	log.ms_log(Log.best_score, "update_best_3")
	var sort_snake = func(a, b): 
		return a.get_player_score() > b.get_player_score()
	var v = []
	for x in $Players.get_children():
		v.append(x)
	v.sort_custom(sort_snake)
	var elems = min(3, v.size())
	var max_elems = v.slice(0, elems)
	var result = []
	for x in max_elems:
		result.append(NameValue.new(x.get_player_name(), x.get_player_score()))

	score_table.update_best_players(result)
