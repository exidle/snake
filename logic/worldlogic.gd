extends Node2D

@onready var npc_value = 1
@onready var camera_update_timeout: float = 0.

func _ready():
	if not is_multiplayer_authority(): $CanvasLayer/CreateNpcBtn.disabled = true
	updateCreateNpcBtnLabel()

func _on_create_npc_btn_pressed():
	#$CanvasLayer/CreateNpcBtn.set_focus_mode(Control.FOCUS_NONE)
	#var npc = preload("res://scenes/NpcBlock.tscn").instantiate()
	#npc.position = Vector2(500, 500)
	gamestate.ms_log("btn pressed to create npc")
	#$NpcBlocks.add_child(npc)
	create_npc(npc_value)

func create_npc(value: int) -> void:
	gamestate.ms_log("Created npc")
	$CanvasLayer/CreateNpcBtn.set_focus_mode(Control.FOCUS_NONE)
	var npc_position = Vector2(500 + randi_range(-100, 100), 500 + randi_range(-100, 100))
	$NpcBlocksSpawner.spawn([npc_position, value])

func _on_h_slider_value_changed(value):
	npc_value = value
	updateCreateNpcBtnLabel()

func updateCreateNpcBtnLabel():
	$CanvasLayer/CreateNpcBtn.text = "CreateNPC[" + str(npc_value) + "]"

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
			
