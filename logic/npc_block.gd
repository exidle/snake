class_name NpcBlock
extends RigidBody2D

@onready var is_active = true
@export_range(1, 39) var value_index = 1

func _ready():
	$sprite/ValueLabel.text = BlocksCommon.get_block_value_as_text(value_index)

func init_block(gp: Vector2, val: int):
	global_position = gp
	value_index = val
	var value = BlocksCommon.get_value(value_index)
	scale = Vector2.ONE * BlocksCommon.get_scale(value)
	
func get_value() -> int:
	return value_index

## Collision can happen with snake head only
func _on_collision_area_body_entered(body):
	if not is_active: return
	if body.has_method("bump_with_block"):
		if body.get_value_index() < value_index: return
		call_deferred("set_collision_layer", 0)
		log.ms_log(Log.collision, "%s NpcBlock collision detected" % name)
		is_active = false
		if is_multiplayer_authority():
			log.ms_log(Log.collision, "NpcBlock is calling bump_with_block")
			body.bump_with_block.rpc(value_index)
		$AnimationPlayer.play("Dissolve")
