extends Node2D

@onready var npc_value = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	if not is_multiplayer_authority(): $CanvasLayer/CreateNpcBtn.disabled = true
	updateCreateNpcBtnLabel()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_create_npc_btn_pressed():
	#$CanvasLayer/CreateNpcBtn.set_focus_mode(Control.FOCUS_NONE)
	#var npc = preload("res://scenes/NpcBlock.tscn").instantiate()
	#npc.position = Vector2(500, 500)
	gamestate.ms_log("btn pressed to create npc")
	#$NpcBlocks.add_child(npc)
	create_npc.rpc(npc_value)

@rpc("authority", "call_local", "reliable")
func create_npc(value: int) -> void:
	gamestate.ms_log("Created npc")
	$CanvasLayer/CreateNpcBtn.set_focus_mode(Control.FOCUS_NONE)
	var npc = preload("res://scenes/NpcBlock.tscn").instantiate()
	npc.position = Vector2(500 + randi_range(-100, 100), 500 + randi_range(-100, 100))
	npc.value = value
	$NpcBlocks.add_child(npc)

func _on_h_slider_value_changed(value):
	npc_value = value
	updateCreateNpcBtnLabel()

func updateCreateNpcBtnLabel():
	$CanvasLayer/CreateNpcBtn.text = "CreateNPC[" + str(npc_value) + "]"
