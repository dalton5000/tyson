extends Control

const DEFAULT_PORT = 8910 # some random number, pick your port properly

onready var host_edit = $MarginContainer/PanelContainer/VBoxContainer/HBoxContainer/Address
onready var port_edit = $MarginContainer/PanelContainer/VBoxContainer/HBoxContainer/Port
onready var name_edit = $MarginContainer/PanelContainer/VBoxContainer/HBoxContainer2/Name
onready var log_label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/Log

func _on_Pair_pressed():
	udp_traversal.rendevouz_address = name_edit.text
	udp_traversal.rendevouz_port = int(port_edit.text)
	udp_traversal.client_name = name_edit.text
	

func dlog(line, isok=true):
	log_label.text = str(line) + "\n" + log_label.text




#### Network callbacks from SceneTree ####

# callback from SceneTree
func _player_connected(_id):
	dlog("Player connected on ENet")
	#someone connected, start the game!
	var pong = load("res://pong.tscn").instance()
	pong.connect("game_finished", self, "_end_game", [], CONNECT_DEFERRED) # connect deferred so we can safely erase it from the callback
	
	get_tree().get_root().add_child(pong)
	hide()

func _player_disconnected(_id):

	if get_tree().is_network_server():
		_end_game("Client disconnected")
	else:
		_end_game("Server disconnected")

# callback from SceneTree, only for clients (not server)
func _connected_ok():
	# will not use this one
	pass
	
# callback from SceneTree, only for clients (not server)	
func _connected_fail():

	dlog("Couldn't connect",false)
	
	get_tree().set_network_peer(null) #remove peer
	
	get_node("panel/join").set_disabled(false)
	get_node("panel/host").set_disabled(false)

func _server_disconnected():
	_end_game("Server disconnected")
	
##### Game creation functions ######

func _end_game(with_error=""):
	if has_node("/root/pong"):
		#erase pong scene
		get_node("/root/pong").free() # erase immediately, otherwise network might show errors (this is why we connected deferred above)
		show()
	
	get_tree().set_network_peer(null) #remove peer
	
	get_node("panel/join").set_disabled(false)
	get_node("panel/host").set_disabled(false)
	
	dlog(with_error, false)

func _on_Host_pressed():
	udp_traversal.is_host = true
	start_traversal()
	
func _on_Join_pressed():
	udp_traversal.is_host = false
	start_traversal()

func host_game():
	var host = NetworkedMultiplayerENet.new()
	var port = udp_traversal.own_port
	host.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_RANGE_CODER)
	var err = host.create_server(port, 1) # max: 1 peer, since it's a 2 players game
	if err != OK:
		#is another server running?
		dlog("Can't host, address in use? Error: " + str(err),false)
		return
		
	get_tree().set_network_peer(host)
	dlog("Waiting for player..", true)

func start_traversal():
	udp_traversal.client_name = name_edit.text
	udp_traversal.rendevouz_address = host_edit.text
	udp_traversal.rendevouz_port = int(port_edit.text)
	udp_traversal.start_traversal()
	
func join_game():
	var ip = udp_traversal.peer_address
	var port = udp_traversal.peer_port
	if not ip.is_valid_ip_address():
		dlog("IP address is invalid", false)
		return
	
	var host = NetworkedMultiplayerENet.new()
	host.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_RANGE_CODER)
	host.create_client(ip, port)
	get_tree().set_network_peer(host)
	
	dlog("Connecting..", true)

	
func _on_udp_hole_punched():
	$StartTimer.start()
### INITIALIZER ####
	
func _ready():
	randomize()
	name_edit.text = "Client-" + str( randi()%1000)
	
	udp_traversal.connect("hole_punched",self,"_on_udp_hole_punched")
	# connect all the callbacks related to networking
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")


func _on_StartTimer_timeout():
	udp_traversal.starting_game = true
	udp_traversal.peer_udp.close()
	yield(get_tree(),"idle_frame")
	if udp_traversal.is_host:
		dlog("Starting game as host", true)
		host_game()
	else:
		dlog("Starting game as client", true)
		join_game()
