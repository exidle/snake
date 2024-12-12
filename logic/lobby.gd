extends Control

const DISCOVERY_PORT = 4313
var udp_client: PacketPeerUDP
var client_connecting = false
var acting_as_server = false
var udp_server_peer: PacketPeerUDP
const REPEAT_BROADCAST_INERVAL = 1.0
var timeout: float = 0.0
var server_ip: String

@onready var name_label: Label = %NameLabel
@onready var player_name_edit: LineEdit = %Name
@onready var host_button: Button = %Host
@onready var error_label: Button = %ErrorLabel
@onready var join_button: Button = %Join
@onready var find_server_btn: Button = %FindServerBtn
@onready var buttons_container: HBoxContainer = %ButtonsContainer

@onready var available_players_list: ItemList = %List
@onready var start_game_btn: Button = %Start

@onready var find_server_timeout: Timer = %FindServerTimeout


func _ready() -> void:
	# Called every time the node is added to the scene.
	gamestate.connection_failed.connect(_on_connection_failed)
	gamestate.connection_succeeded.connect(_on_connection_success)
	gamestate.player_list_changed.connect(refresh_lobby)
	gamestate.game_ended.connect(_on_game_ended)
	gamestate.game_error.connect(_on_game_error)



func _process(_delta):
	if acting_as_server:
		timeout += _delta
	if timeout > REPEAT_BROADCAST_INERVAL:
		timeout = 0.0
		var err = udp_server_peer.put_packet("DISCO".to_utf8_buffer())
		if err != OK: print("Error sending packet: %s" % err)
		else: print("Sent packet")

	if client_connecting:
		# if OK != udp_client.poll(): print("Error in polling")
		# if udp_client.is_connection_available():
		if udp_client.get_available_packet_count() > 0:
			var packet = udp_client.get_packet()
			print("Accepted packet: %s:%s" % [udp_client.get_packet_ip(), udp_client.get_packet_port()])
			print("data is %s" % packet.get_string_from_utf8())
			if (packet.get_string_from_utf8() == "DISCO"):
				find_server_btn.text = "Join"
				find_server_btn.disconnect("pressed", _on_find_avail_servers_pressed)
				find_server_btn.connect("pressed", _on_connect_to_server_pressed)
				find_server_timeout.stop()
				server_ip = udp_client.get_packet_ip()
				client_connecting = false

func _on_host_pressed() -> void:
	$Connect.hide()
	$Players.show()

	var player_name: String = player_name_edit.text
	gamestate.host_game(player_name)
	get_window().title = ProjectSettings.get_setting("application/config/name") + ": Server (%s)" % player_name_edit.text
	refresh_lobby()
	acting_as_server = true
	udp_server_peer = PacketPeerUDP.new()
	udp_server_peer.set_broadcast_enabled(true)
	udp_server_peer.set_dest_address("255.255.255.255", DISCOVERY_PORT)


func _on_connection_success() -> void:
	$Connect.hide()
	$Players.show()

func _on_connection_failed() -> void:
	host_button.disabled = false
	join_button.disabled = false
	error_label.set_text("Connection failed.")
	error_label.show()


func _on_game_ended() -> void:
	show()
	$Connect.show()
	$Players.hide()
	host_button.disabled = false
	join_button.disabled = false


func _on_game_error(errtxt: String) -> void:
	$ErrorDialog.dialog_text = errtxt
	$ErrorDialog.popup_centered()
	host_button.disabled = false
	join_button.disabled = false


func refresh_lobby() -> void:
	var players := gamestate.get_player_list()
	players.sort()
	available_players_list.clear()
	available_players_list.add_item(gamestate.player_name + " (you)")
	for p: String in players:
		available_players_list.add_item(p)

	start_game_btn.disabled = not multiplayer.is_server()


func _on_start_pressed() -> void:
	## Stop broadcasting
	acting_as_server = false
	gamestate.begin_game()


func _on_find_public_ip_pressed() -> void:
	OS.shell_open("https://icanhazip.com/")


func _on_find_avail_servers_pressed() -> void:
	if client_connecting:
		return
	host_button.hide()
	find_server_timeout.start()
	
	print("start listening")
	udp_client = PacketPeerUDP.new()
	if OK != udp_client.bind(DISCOVERY_PORT): print("Failed to bind")

	# if udp_client.listen(DISCOVERY_PORT, "0.0.0.0") != OK: print("Fail to listen on UDP port")
	client_connecting = true


func _on_connect_to_server_pressed() -> void:
	var ip: String = server_ip
	if not ip.is_valid_ip_address():
		error_label.text = "Invalid IP address!"
		return

	error_label.text = ""
	host_button.disabled = true
	join_button.disabled = true

	var player_name: String = player_name_edit.text
	gamestate.join_game(ip, player_name)
	get_window().title = ProjectSettings.get_setting("application/config/name") + ": Client (%s)" % player_name
	client_connecting = false

func _on_name_text_changed(new_text:String) -> void:
	if new_text.length() > 0:
		buttons_container.show()
	else:
		buttons_container.hide()


func _on_find_server_timeout_timeout() -> void:
	log.ms_log(Log.default, "No servers found")
	host_button.show()
	client_connecting = false
