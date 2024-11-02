extends VBoxContainer

#@onready var SnakeItem = preload("res://Levels/snake_item.tscn")
@onready var playersNode = self

func update_best_players(bestis: Array):
	if bestis.size() < playersNode.get_child_count():
		var d = - bestis.size() + playersNode.get_child_count()
		for x in range(0, d):
			playersNode.get_child(playersNode.get_child_count() - 1 - x).set_values('--', 0)
	for idx in range(0, bestis.size()):
		var nv = bestis[idx]
		log.ms_log(Log.best_score, "ScoreTable: " + nv.m_name + " " + str(nv.m_value))
		playersNode.get_child(idx).set_values(nv.m_name, nv.m_value)
		#playersNode.add_child(item)
		#item.set_values(x.name, x.value)
