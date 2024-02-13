extends Node

signal remote_command_click(peer,cellPos : Vector2)

const PORT = 23001
const HOST = "127.0.0.1"
var _server := UDPServer.new()
var peers = []


# Called when the node enters the scene tree for the first time.
func _ready():
	_server.listen(PORT,HOST)
	print("Server started")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_server.poll()
	if _server.is_connection_available():
		var peer : PacketPeerUDP = _server.take_connection()
		var packet = peer.get_packet()
		print("Accepted peer: %s:%s" % [peer.get_packet_ip(), peer.get_packet_port()])
		print("Received data: %s" % [packet.get_string_from_utf8()])
		
		var tMessage = packet.get_string_from_utf8()
		if tMessage.begins_with("COMMAND_CLICK_"):
			var clickNumber = int(tMessage.split('_')[2])
			if clickNumber < 0 or clickNumber > 99:
				peer.put_packet("INVALID_NUMBER".to_utf8_buffer())
			else:
				remote_command_click.emit(peer,Vector2(clickNumber % 10, clickNumber / 10))
		else:
			peer.put_packet("INVALID_COMMAND".to_utf8_buffer())
		

func isListening():
	return _server.is_listening()
