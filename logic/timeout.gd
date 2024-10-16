extends Node

signal on_timeout

@export_range(3, 10) var time_in_sec = 5

@onready var elapsed_time_ms: float = 0
@onready var elapsed_time_sec_prec: int = 0

@onready var index_text_label = 0

@onready var update_label_in_sec: int = ceil(1.0 * time_in_sec / 3.0) as int
@onready var control_label_time: int = 0

@onready var labels = ["READY", "STEADY", "GO!"]

func _ready() -> void:
	var tween_c = create_tween().set_loops(time_in_sec)
	tween_c.tween_property($Control, "modulate", Color.RED, 2.0).set_ease(Tween.EASE_OUT)
	tween_c.tween_property($Control, "modulate", Color.WEB_GRAY, 0.5).set_ease(Tween.EASE_IN)
	#tween.set_parallel()
	var tween = create_tween().set_loops(time_in_sec)
	tween.tween_property($Control/LabelWIthText, "visible_ratio", 1.0, 1.0).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property($Control/LabelWIthText, "visible_ratio", 0.0, 0.5).set_trans(Tween.TRANS_LINEAR).set_delay(0.5)
	$Control/LabelWIthText.text = labels[0]
	tween.finished.connect(final_set_visible)

func final_set_visible():
	$Control/LabelWIthText.visible_ratio = 1.0

func _process(delta: float) -> void:
	elapsed_time_ms += delta * 1000
	if elapsed_time_ms >= 1000.0:
		elapsed_time_ms = 0.
		elapsed_time_sec_prec += 1
		control_label_time += 1
		
		if control_label_time >= update_label_in_sec:
			control_label_time = 0
			change_text_label()
	
	if elapsed_time_sec_prec == time_in_sec: 
		on_timeout.emit()
		queue_free()

func change_text_label():
	index_text_label = clamp(index_text_label + 1, 0, 2)
	print("Scroll to line %d" % index_text_label)
	$Control/LabelWIthText.text = labels[index_text_label]
