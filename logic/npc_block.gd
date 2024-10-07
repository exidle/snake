extends RigidBody2D

@onready var is_active = true
@export_range(1, 39) var value = 1

func _ready():
	$sprite/ValueLabel.text = gamestate.get_block_label_text(value)

func get_value() -> int:
	return value

## Collision can happen with snake head only
func _on_collision_area_body_entered(body):
	if not is_active: return
	if body.has_method("bump_with_block"):
		if body.value < value: return
		call_deferred("set_collision_layer", 0)
		gamestate.ms_log("%s NpcBlock collision detected" % name)
		is_active = false
		if is_multiplayer_authority():
			gamestate.ms_log("NpcBlock is calling bump_with_block")
			body.bump_with_block.rpc(value)
		$AnimationPlayer.play("Dissolve")
