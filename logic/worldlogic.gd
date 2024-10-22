extends Node2D

@onready var npc_value = 1
@onready var camera_update_timeout: float = 0.

@onready var debug_canvas_layer = $DebugCanvasLayer
@onready var respawn_ui = $CanvasLayer

func _ready():
	pre_start_configure_debug()
	if not is_multiplayer_authority(): debug_canvas_layer.get_node("CreateNpcBtn").disabled = true
	updateCreateNpcBtnLabel()

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
	gamestate.ms_log("btn pressed to create npc")
	#$NpcBlocks.add_child(npc)
	create_npc(npc_value)

func create_npc(value: int) -> void:
	gamestate.ms_log("Created npc")
	debug_canvas_layer.get_node("CreateNpcBtn").set_focus_mode(Control.FOCUS_NONE)
	var npc_position = Vector2(500 + randi_range(-100, 100), 500 + randi_range(-100, 100))
	$NpcBlocksSpawner.spawn([npc_position, value])

func _on_h_slider_value_changed(value):
	npc_value = value
	updateCreateNpcBtnLabel()

func updateCreateNpcBtnLabel():
	debug_canvas_layer.get_node("CreateNpcBtn").text = "CreateNPC[" + str(npc_value) + "]"

func _process(delta: float) -> void:
	if camera_update_timeout > 0.1:
		camera_update_timeout = 0.
		for player in $Players.get_children():
			#print("check ", player.name)
			if gamestate.is_main_player(player.name):
				var p = player.get_head_position()
				if p: $Camera2D.position = p
				break
	camera_update_timeout += delta
	
	const CAMERA_SPEED = 400
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

func _on_set_camera_btn_pressed() -> void:
	$Camera2D.enabled = false
	$DebugCamera.enabled = true

func _on_set_mc_camera_btn_pressed() -> void:
	$DebugCamera.enabled = false
	$Camera2D.enabled = true
	$DebugCamera.position = Vector2.ZERO
	$DebugCamera.zoom = Vector2(4,4)

func _on_npc_spawn_timer_timeout() -> void:
	gamestate.ms_log("On spawn TO")
	gamestate.spawn_npc()

func _on_check_npc_amount_btn_pressed() -> void:
	gamestate.ms_log("Theree are currently:  %d" % $NpcBlocks.get_child_count())

func main_player_died() -> void:
	gamestate.ms_log("Main player died")
	respawn_ui.show()

func _on_req_respawn_button_pressed() -> void:
	gamestate.respawn.rpc(multiplayer.get_unique_id())
	respawn_ui.hide()

