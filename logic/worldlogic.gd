extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	if not is_multiplayer_authority(): $CanvasLayer/CreateNpcBtn.disabled = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_create_npc_btn_pressed():
	#$CanvasLayer/CreateNpcBtn.set_focus_mode(Control.FOCUS_NONE)
	#var npc = preload("res://scenes/NpcBlock.tscn").instantiate()
	#npc.position = Vector2(500, 500)
	gamestate.ms_log("btn pressed to create npc")
	#$NpcBlocks.add_child(npc)
	create_npc.rpc()

@rpc("authority", "call_local", "reliable")
func create_npc() -> void:
	gamestate.ms_log("Created npc")
	$CanvasLayer/CreateNpcBtn.set_focus_mode(Control.FOCUS_NONE)
	var npc = preload("res://scenes/NpcBlock.tscn").instantiate()
	npc.position = Vector2(500, 500)
	$NpcBlocks.add_child(npc)
