extends Control

const DISCOVERY_PORT = 4313
var udp_client: PacketPeerUDP
var client_connected = false
var acting_as_server = false
var udp_server_peer: PacketPeerUDP
const REPEAT_BROADCAST_INERVAL = 1.0
var timeout: float = 0.0
var server_ip: String

func _ready() -> void:
	# Called every time the node is added to the scene.
	gamestate.connection_failed.connect(_on_connection_failed)
	gamestate.connection_succeeded.connect(_on_connection_success)
	gamestate.player_list_changed.connect(refresh_lobby)
	gamestate.game_ended.connect(_on_game_ended)
	gamestate.game_error.connect(_on_game_error)
	# Set the player name according to the system username. Fallback to the path.
	if OS.has_environment("USERNAME"):
		$Connect/Name.text = OS.get_environment("USERNAME")
	else:
		var desktop_path := OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP).replace("\\", "/").split("/")
		$Connect/Name.text = desktop_path[desktop_path.size() - 2]

func _process(_delta):
	if acting_as_server:
		timeout += _delta
	if timeout > REPEAT_BROADCAST_INERVAL:
		timeout = 0.0
		var err = udp_server_peer.put_packet("DISCO".to_utf8_buffer())
		if err != OK: print("Error sending packet: %s" % err)
		else: print("Sent packet")

	if client_connected:
		# if OK != udp_client.poll(): print("Error in polling")
		# if udp_client.is_connection_available():
		if udp_client.get_available_packet_count() > 0:
			var packet = udp_client.get_packet()
			print("Accepted packet: %s:%s" % [udp_client.get_packet_ip(), udp_client.get_packet_port()])
			print("data is %s" % packet.get_string_from_utf8())
			if (packet.get_string_from_utf8() == "DISCO"):
				$Connect/Join.disabled = false
				server_ip = udp_client.get_packet_ip()


func _on_host_pressed() -> void:
	if $Connect/Name.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return

	$Connect.hide()
	$Players.show()
	$Connect/ErrorLabel.text = ""

	var player_name: String = $Connect/Name.text
	gamestate.host_game(player_name)
	get_window().title = ProjectSettings.get_setting("application/config/name") + ": Server (%s)" % $Connect/Name.text
	refresh_lobby()
	acting_as_server = true
	udp_server_peer = PacketPeerUDP.new()
	udp_server_peer.set_broadcast_enabled(true)
	udp_server_peer.set_dest_address("255.255.255.255", DISCOVERY_PORT)


func _on_connection_success() -> void:
	$Connect.hide()
	$Players.show()

func _on_connection_failed() -> void:
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false
	$Connect/ErrorLabel.set_text("Connection failed.")


func _on_game_ended() -> void:
	show()
	$Connect.show()
	$Players.hide()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false


func _on_game_error(errtxt: String) -> void:
	$ErrorDialog.dialog_text = errtxt
	$ErrorDialog.popup_centered()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false


func refresh_lobby() -> void:
	var players := gamestate.get_player_list()
	players.sort()
	$Players/List.clear()
	$Players/List.add_item(gamestate.player_name + " (you)")
	for p: String in players:
		$Players/List.add_item(p)

	$Players/Start.disabled = not multiplayer.is_server()


func _on_start_pressed() -> void:
	## Stop broadcasting
	acting_as_server = false
	gamestate.begin_game()


func _on_find_public_ip_pressed() -> void:
	OS.shell_open("https://icanhazip.com/")


func _on_find_avail_servers_pressed() -> void:
	if client_connected:
		return
	print("start listening")
	udp_client = PacketPeerUDP.new()
	if OK != udp_client.bind(DISCOVERY_PORT): print("Failed to bind")

	# if udp_client.listen(DISCOVERY_PORT, "0.0.0.0") != OK: print("Fail to listen on UDP port")
	client_connected = true


func _on_connect_to_server_pressed() -> void:
	if $Connect/Name.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return

	var ip: String = server_ip
	if not ip.is_valid_ip_address():
		$Connect/ErrorLabel.text = "Invalid IP address!"
		return

	$Connect/ErrorLabel.text = ""
	$Connect/Host.disabled = true
	$Connect/Join.disabled = true

	var player_name: String = $Connect/Name.text
	gamestate.join_game(ip, player_name)
	get_window().title = ProjectSettings.get_setting("application/config/name") + ": Client (%s)" % $Connect/Name.text

