extends CharacterBody2D

func _on_collision_area_body_entered(body):
	if body.has_method("on_npc_bump"):
		body.on_npc_bump()
	$AnimationPlayer.play("Dissolve")
	
