extends Node

var server_udp = PacketPeerUDP.new()
var peer_udp = PacketPeerUDP.new()

var txt_server = "tyson5000.ddns.net" 
var port = 4000
var found_server = false
var recieved_peer = false

var own_port
var peer_address
var peer_port



func _process(delta):
	if peer_udp.get_available_packet_count() > 0:
		var array_bytes = peer_udp.get_packet()
		var packet_string = array_bytes.get_string_from_ascii()
		dlog("Recieved Packet from peer!!! " + packet_string)
		
	if server_udp.get_available_packet_count() > 0:
		var array_bytes = server_udp.get_packet()
		var packet_string = array_bytes.get_string_from_ascii()
#		dlog("Recieved Packet from server: " + packet_string)
		
		if not found_server:
			if packet_string.begins_with("ok"):
					found_server=true
					dlog("Recieved ok from Rendezvous Server")
					var p = packet_string.split(":")
					own_port =int( p[1] )
					dlog("Own port is: " + str(own_port))
					dlog("Waiting for peer...")
					
				
		elif not recieved_peer:
			if packet_string.begins_with("peer:"):
				dlog("Recieved peer info")
				var p = packet_string.split(":")
				peer_address = p[1]
				peer_port =int( p[2] )
				recieved_peer=true
				dlog("Peer adress: " + peer_address)
				dlog("Peer port: " + str( peer_port))
				start_peer_contact()
				
func start_peer_contact():
	if peer_udp.is_listening():
		peer_udp.close()
	peer_udp.set_dest_address(peer_address, peer_port)
	var err = peer_udp.listen(own_port, "*")
	if err != OK:
		dlog("Error listening on port: " + str(own_port) + " to peer: " + peer_address)
	else:
		dlog("Listening on port: " + str(own_port) + " to peer : " + peer_address)

	var p_timer = Timer.new()
	get_node("/root/").add_child(p_timer)
	p_timer.connect("timeout", self, "ping_peer")
	p_timer.wait_time = 0.5
	p_timer.start()
	dlog("Contacting peer...")
	
func ping_peer():
#	dlog("pinging peer...")
	var buffer = PoolByteArray()
	buffer.append_array("Hello from your peer".to_utf8())
#	buffer.resize("Hello from your peer".to_utf8().size())
	peer_udp.put_packet(buffer)

	
func start_server_contact():
	
	if server_udp.is_listening():
		server_udp.close()
	var err = server_udp.listen(port, "*")
	if err != OK:
		dlog("Error listening on port: " + str(port) + " to server: " + txt_server)
	else:
		dlog("Listening on port: " + str(port) + " to server: " + txt_server)
		
	found_server = false
	recieved_peer = false
	dlog("Connecting Rendezvouz Server...")
	var buffer = PoolByteArray()
	buffer.append_array("hello".to_utf8())
#	buffer.resize("hello".to_utf8().size())
	server_udp.close()
	server_udp.set_dest_address(txt_server, port)
	server_udp.put_packet(buffer)
		
func _exit_tree():
	server_udp.close()
	
func dlog(line):
	get_node("/root/Lobby").dlog(line)
	
