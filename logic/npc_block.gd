extends CharacterBody2D

@onready var is_active = true

func _on_collision_area_body_entered(body):
	if not is_active: return
	if body.has_method("on_npc_bump"):
		gamestate.ms_log("%s NpcBlock collision detected" % name)
		is_active = false
		if is_multiplayer_authority():
			gamestate.ms_log("NpcBlock is calling on_npc_bump")
			body.on_npc_bump.rpc()
		$AnimationPlayer.play("Dissolve")
