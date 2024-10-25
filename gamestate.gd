extends Node

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of May 2024:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 10567

## The maximum number of players.
const MAX_PEERS = 4

var peer: ENetMultiplayerPeer

## Our local player's name.
var player_name := "The Warrior"

# Names for remote players in id:name format.
var players := {}
var players_ready: Array[int] = []

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what: int)

# Callback from SceneTree.
func _player_connected(id: int) -> void:
	# Registration of a client beings here, tell the connected player that we are here.
	register_player.rpc_id(id, player_name)


# Callback from SceneTree.
func _player_disconnected(id: int) -> void:
	if has_node("/root/World"):
		# Game is in progress.
		if multiplayer.is_server():
			game_error.emit("Player " + players[id] + " disconnected")
			end_game()
	else:
		# Game is not in progress.
		# Unregister this player.
		unregister_player(id)


# Callback from SceneTree, only for clients (not server).
func _connected_ok() -> void:
	# We just connected to a server
	connection_succeeded.emit()


# Callback from SceneTree, only for clients (not server).
func _server_disconnected() -> void:
	game_error.emit("Server disconnected")
	end_game()


# Callback from SceneTree, only for clients (not server).
func _connected_fail() -> void:
	multiplayer.set_network_peer(null) # Remove peer
	connection_failed.emit()


# Lobby management functions.
@rpc("any_peer")
func register_player(new_player_name: String) -> void:
	var id := multiplayer.get_remote_sender_id()
	players[id] = new_player_name
	player_list_changed.emit()


func unregister_player(id: int) -> void:
	players.erase(id)
	player_list_changed.emit()


@rpc("call_local")
func load_world() -> void:
	# Change scene.
	var world: Node2D = load("res://scenes/world.tscn").instantiate()
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("Lobby").hide()

	# Set up score.
	#world.get_node("Score").add_player(multiplayer.get_unique_id(), player_name)
	#for pn: int in players:
		#world.get_node("Score").add_player(pn, players[pn])

	# Unpause and unleash the game!
	get_tree().paused = false


func host_game(new_player_name: String) -> void:
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	peer.create_server(DEFAULT_PORT, MAX_PEERS)
	multiplayer.set_multiplayer_peer(peer)


func join_game(ip: String, new_player_name: String) -> void:
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, DEFAULT_PORT)
	multiplayer.set_multiplayer_peer(peer)


func get_player_list() -> Array:
	return players.values()

func spawn_npc() -> void:
	var world: Node2D = get_tree().get_root().get_node("World")
	var npc_spawner = world.get_node("NpcBlocksSpawner")
	for p_id: int in range(0, 8):
		var spawn_pos: Vector2 = world.get_node("NpcPositions/" + str(p_id)).position
		var value = 1
		for repeat in range(1, 6):	
			npc_spawner.spawn([spawn_pos, value])



func begin_game() -> void:
	assert(multiplayer.is_server())
	load_world.rpc()

	var world: Node2D = get_tree().get_root().get_node("World")

	# Create a dictionary with peer ID. and respective spawn points.
	# TODO: This could be improved by randomizing spawn points for players.
	var spawn_points := {}
	spawn_points[1] = 0  # Server in spawn point 0.
	var spawn_point_idx := 1
	for p: int in players:
		print("p is ", p)
		spawn_points[p] = spawn_point_idx
		spawn_point_idx += 1
	print("Players are: ", players)

	for p_id: int in spawn_points:
		var spawn_pos: Vector2 = world.get_node("SpawnPoints/" + str(spawn_points[p_id])).position
		spawn_player(p_id, spawn_pos)
	spawn_npc()

func spawn_player(p_id: int, spawn_pos: Vector2) -> void:
	var world: Node2D = get_tree().get_root().get_node("World")
	var player_scene: PackedScene = load("res://scenes/snake.tscn")
	var player := player_scene.instantiate()
	player.sig_game_over.connect(end_game_for_player)
	player.synced_position = spawn_pos
	player.name = str(p_id)
	world.get_node("Players").add_child(player)
	# The RPC must be called after the player is added to the scene tree.
	player.set_player_name.rpc(player_name if p_id == multiplayer.get_unique_id() else players[p_id])
	world.set_camera_player.rpc_id(p_id, player.name)

func end_game_for_player(p_id):
	ms_log("end_game_for_player id = %d" % p_id)
	rpc_id(p_id, "activate_respawn")

@rpc("any_peer", "call_local")
func activate_respawn() -> void:
	var world: Node2D = get_tree().get_root().get_node("World")
	world.main_player_died()

@rpc("any_peer", "call_local")
func respawn(id: int) -> void:
	if not is_multiplayer_authority():
		return
	ms_log("respawn id = %d" % id)

	var world: Node2D = get_tree().get_root().get_node("World")

	# spwan player at first spawn point
	var spawn_pos: Vector2 = world.get_node("SpawnPoints/0").position
	spawn_player(id, spawn_pos)

func is_main_player(p_id):
	return p_id == multiplayer.get_unique_id()

func end_game() -> void:
	if has_node("/root/World"):
		# If the game is in progress, end it.
		get_node("/root/World").queue_free()

	game_ended.emit()
	players.clear()


func _ready() -> void:
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connected_to_server.connect(_connected_ok)
	multiplayer.connection_failed.connect(_connected_fail)
	multiplayer.server_disconnected.connect(_server_disconnected)


## Returns an unique-looking player color based on the name's hash.
func get_player_color(p_name: String) -> Color:
	return Color.from_hsv(wrapf(p_name.hash() * 0.001, 0.0, 1.0), 0.6, 1.0)


## logging fun
func ms_log(v: String):
	var s = "[client]"
	if is_multiplayer_authority(): s = "[server]"
	print(s, str(Time.get_ticks_msec()), '# ', v)
