extends Area2D

@export var snake: Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

## The head collision detector is located on the head of snake
## The callback is called when snake head is touching other objects that
## are forming snake
func _on_body_entered(body):
	if body.has_method("collide_with_head") and body.snake != snake:
		body.collide_with_head()
		snake.collide_with_other_snake(body)


func _on_body_exited(body):
	pass # Replace with function body.
