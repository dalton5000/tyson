extends Node

signal hole_punched

var server_udp = PacketPeerUDP.new()
var peer_udp = PacketPeerUDP.new()

var rendevouz_address = "tyson5000.ddns.net" 
var rendevouz_port = 4000
var found_server = false
var recieved_peer_info = false
var recieved_peer_greet = false
var recieved_peer_confirm = false
var recieved_peer_go = false

# warning-ignore:unused_class_variable
var is_host = false
var starting_game = false

var own_port
var peer_address
var peer_port
var peer_name
var client_name
var p_timer
var cascade_timer

var ports_tried = 0
var greets_sent = 0

# warning-ignore:unused_argument
func _process(delta):
	if peer_udp.get_available_packet_count() > 0:
		var array_bytes = peer_udp.get_packet()
		var packet_string = array_bytes.get_string_from_ascii()
		
		if not recieved_peer_greet:
			if packet_string.begins_with("greet"):
				var p = packet_string.split(":")
				peer_udp.close()
				peer_udp.set_dest_address(peer_address, peer_port)
				var peer_used_port = int(p[2])
				dlog("Recieved greet from: "+peer_name + "on port: " + str(peer_used_port))
				peer_name = p[1]
				if own_port != peer_used_port:
					own_port = peer_used_port
					dlog("Changing own port to: " + str(own_port))
#					peer_udp.close()
#					peer_udp.listen(own_port, "*")
					
				dlog("Sending confirm")
				
				recieved_peer_greet = true
				
		if not recieved_peer_confirm:
			if packet_string.begins_with("confirm"):
				var p = packet_string.split(":")
				var confirmed_port = int(p[1])
				dlog("Recieved confirm from: "+peer_name + "for port: " + str(confirmed_port))
				
				if peer_port != confirmed_port:
					peer_port = confirmed_port
					dlog("Changing peer port to: " + str(own_port))
					peer_udp.set_dest_address(peer_address, peer_port)
					cascade_timer.stop()
					
					
				peer_port = confirmed_port
				peer_udp.close()
				peer_udp.listen(peer_port, "*")
				dlog("Sending go")
				recieved_peer_confirm = true
				peer_udp.close()

				
		elif not recieved_peer_go:
			if packet_string.begins_with("go"):
				dlog("Recieved go from: "+peer_name)
				recieved_peer_go = true
				set_process(false)
				emit_signal("hole_punched")
		
	if server_udp.get_available_packet_count() > 0:
		var array_bytes = server_udp.get_packet()
		var packet_string = array_bytes.get_string_from_ascii()
		dlog("Recieved Packet from server: " + packet_string)
		
		if not found_server:
			if packet_string.begins_with("ok"):
					found_server=true
					dlog("Recieved ok from Rendezvous Server")
					var p = packet_string.split(":")
					own_port =int( p[1] )
					dlog("Own port is: " + str(own_port))
					dlog("Waiting for peer...")
					
				
		elif not recieved_peer_info:
			if packet_string.begins_with("peer:"):
				dlog("Recieved peer info")
				var p = packet_string.split(":")
				peer_address = p[1]
				peer_port =int( p[2] )
				recieved_peer_info=true
				dlog("Peer adress: " + peer_address)
				dlog("Peer port: " + str( peer_port))
				start_peer_contact()
				
func cascade_peer():
	if not recieved_peer_confirm:
		dlog("pinging on port " + str(ports_tried + peer_port) + " and above")
		for i in range(ports_tried, ports_tried+10):
			var p = peer_port + i
			peer_udp.set_dest_address(peer_address, p)
			var buffer = PoolByteArray()
			buffer.append_array(("greet:"+ client_name+":"+str(p) ).to_utf8())
			peer_udp.put_packet(buffer)
			yield(get_tree(),"idle_frame")
		ports_tried+=10
	

func ping_peer():
#	dlog("pinging peer...")
	if starting_game: return
	var buffer
	
	if not recieved_peer_confirm and greets_sent < 7:
#		dlog("sending:"+ str(buffer.get_string_from_utf8()))
		buffer = PoolByteArray()
		buffer.append_array(("greet:"+ client_name+":"+str(peer_port).to_utf8()))
		peer_udp.put_packet(buffer)
		greets_sent+=1
		if greets_sent == 6:
			dlog("Receiving no confirm. Starting port cascade")
			cascade_timer.start()
		
	if recieved_peer_greet and not recieved_peer_go :
		buffer = PoolByteArray()
		buffer.append_array(("confirm:" + str(own_port)).to_utf8())
#		dlog("sending:"+ str(buffer.get_string_from_utf8()))
		peer_udp.put_packet(buffer)
		
	if  recieved_peer_confirm:
		buffer = PoolByteArray()
		buffer.append_array(("go").to_utf8())
#		dlog("sending:"+ str(buffer.get_string_from_utf8()))
		peer_udp.put_packet(buffer)

func start_peer_contact():	
	server_udp.put_packet("goodbye".to_utf8())
	server_udp.close()
	if peer_udp.is_listening():
		peer_udp.close()
	peer_udp.set_dest_address(peer_address, peer_port)
	
	var err = peer_udp.listen(own_port, "*")
	if err != OK:
		dlog("Error listening on port: " + str(own_port) + " to peer: " + peer_address)
	else:
		dlog("Listening on port: " + str(own_port) + " to peer : " + peer_address)

		

	p_timer.start()
	dlog("Contacting peer...")
	
func start_traversal():
	if server_udp.is_listening():
		server_udp.close()
	var err = server_udp.listen(rendevouz_port, "*")
	if err != OK:
		dlog("Error listening on port: " + str(rendevouz_port) + " to server: " + rendevouz_address)
	else:
		dlog("Listening on port: " + str(rendevouz_port) + " to server: " + rendevouz_address)
		
	found_server = false
	recieved_peer_info = false
	
	recieved_peer_greet = false
	recieved_peer_confirm = false
	recieved_peer_go = false

	ports_tried = 0
	greets_sent = 0
	
	dlog("Connecting Rendezvouz Server...")
	var buffer = PoolByteArray()
	buffer.append_array("hello".to_utf8())
	server_udp.close()
	server_udp.set_dest_address(rendevouz_address, rendevouz_port)
	server_udp.put_packet(buffer)
		
func _exit_tree():
	server_udp.close()
	
func dlog(line):
	get_node("/root/Lobby").dlog(line)
	
func _ready():
	p_timer = Timer.new()
	get_node("/root/").add_child(p_timer)
	p_timer.connect("timeout", self, "ping_peer")
	p_timer.wait_time = 0.3
	
	cascade_timer = Timer.new()
	get_node("/root/").add_child(cascade_timer)
	cascade_timer.connect("timeout", self, "cascade_peer")
	cascade_timer.wait_time = 0.2
