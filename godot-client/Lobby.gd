extends Control

onready var log_label= $CenterContainer/PanelContainer/VBoxContainer/MarginContainer/Panel/Log


func reset():
	log_label.text = ""
	log_label.set_scroll_follow(true)


func _on_Pair_pressed():
	udp_traversal.rendevouz_address = $CenterContainer/PanelContainer/VBoxContainer/HBoxContainer2/Adress.text
	udp_traversal.rendevouz_port = int( $CenterContainer/PanelContainer/VBoxContainer/HBoxContainer2/Port.text )
	udp_traversal.start_server_contact()
	

func dlog(line):
	log_label.text = str(line) + "\n" + log_label.text
#	log_label.cursor_set_line(log_label.get_line_count())


