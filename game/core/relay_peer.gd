class_name RelayPeer
extends RefCounted
## Transporte en linea para el autoload Lan: los dos lados conectan de salida a un
## rele WebSocket (ws:// o wss://) y el rele tuba los paquetes del juego entre
## ambos. Ambos salen, asi que atraviesa NAT y cortafuegos sin abrir puertos.
##
## Protocolo con el rele (tramas de texto de control antes de enlazar):
##   cliente -> "HOST"           servidor -> "ROOM ABCDEF"  (sala creada)
##   cliente -> "JOIN ABCDEF"    servidor -> "GO" a ambos   (enlazados)
##                               servidor -> "ERR ..."      (codigo malo o lleno)
## Tras "GO" cada trama binaria se copia tal cual al otro lado; el par ve a Lan
## exactamente como un ENetMultiplayerPeer con un rival (id 1).
##
## Interfaz compatible con el subconjunto de ENetMultiplayerPeer que usa Lan:
## create_server/create_client, poll, put_packet/get_packet, set_transfer_*,
## set_target_peer, disconnect_peer, get_peer().peer_disconnect_later(),
## host.flush(), get_connection_status(), close() y las senales
## peer_connected/peer_disconnected.

signal peer_connected(id: int)
signal peer_disconnected(id: int)

var _ws: WebSocketPeer
var _remote_id := 1
var _linked := false
var _closed := false
var _rx: Array[PackedByteArray] = []
## Codigo de la sala creada (solo anfitrion, tras "ROOM").
var room_code := ""
## Motivo textual del ultimo rechazo del rele (para mensajes).
var error_reason := ""
## Salas publicas abiertas devueltas por el rele (tras "GAMES", solo invitado).
var public_rooms: PackedStringArray = []


func _dial(url: String, hello: String) -> int:
	_ws = WebSocketPeer.new()
	var err := _ws.connect_to_url(url)
	if err != OK:
		_ws = null
		return err
	_hello = hello
	_linked = false
	_closed = false
	_rx.clear()
	room_code = ""
	error_reason = ""
	_browse_url = ""
	_browse_key = ""
	return OK


var _hello := ""


static func _sep(url: String) -> String:
	return "" if url.ends_with("/") else "/"


## Anfitrion en linea: abre sala en el rele. La senal peer_connected llega en poll()
## cuando el rele enlaza al invitado ("GO"). ?op=host guia a reles que rutean por
## la URL antes del upgrade (p.ej. Cloudflare Workers); el rele Python la ignora.
func create_server(url: String, _port := 0, _peers := 0, public := false, key := "") -> int:
	var query := "op=host"
	if key != "":
		query += "&key=" + key.uri_encode()
	return _dial(url + _sep(url) + "?" + query, "HOST PUB" if public else "HOST")


## Invitado en linea: entra a la sala del codigo.
func create_client(url: String, code: String, key := "") -> int:
	var clean := code.strip_edges().to_upper()
	var query := "op=join&code=" + clean.uri_encode()
	if key != "":
		query += "&key=" + key.uri_encode()
	return _dial(url + _sep(url) + "?" + query, "JOIN %s" % clean)


## Invitado en modo exploracion: conecta y recibe la lista publica ("GAMES")
## sin unirse todavia; join_room() fija la sala despues.
func browse(url: String, key := "") -> int:
	var query := "op=list"
	if key != "":
		query += "&key=" + key.uri_encode()
	var err := _dial(url + _sep(url) + "?" + query, "LIST")
	if err == OK:
		_browse_url = url
		_browse_key = key
	return err


var _browse_url := ""
var _browse_key := ""


## Tras browse(): entrar a una sala publica o privada por codigo. Re-dial a
## op=join&code=: en el Worker el socket de lista vive en otro objeto y no
## puede enlazar, y en los demas reles una conexion JOIN limpia vale igual.
func join_room(code: String) -> int:
	if _browse_url == "":
		return ERR_UNAVAILABLE
	var url := _browse_url
	var key := _browse_key
	_browse_url = ""
	_browse_key = ""
	if _ws != null:
		_ws.close()
		_ws = null
	return create_client(url, code, key)


func poll() -> void:
	if _ws == null:
		return
	_ws.poll()
	var ready := _ws.get_ready_state()
	if ready == WebSocketPeer.STATE_OPEN and _hello != "":
		_ws.send_text(_hello)
		_hello = ""
	while ready == WebSocketPeer.STATE_OPEN and _ws.get_available_packet_count() > 0:
		var packet := _ws.get_packet()
		if _ws.was_string_packet():
			_control(packet.get_string_from_utf8())
		else:
			_rx.append(packet)
	if ready == WebSocketPeer.STATE_CLOSED and not _closed:
		_closed = true
		if _linked:
			_linked = false
			peer_disconnected.emit(_remote_id)


func _control(text: String) -> void:
	var head := text.get_slice(" ", 0)
	match head:
		"ROOM":
			room_code = text.get_slice(" ", 1)
		"GO":
			if not _linked:
				_linked = true
				peer_connected.emit(_remote_id)
		"ERR":
			error_reason = text.substr(4) if text.length() > 4 else text
		"GAMES":
			# Lista de salas publicas libres (respuesta a list_rooms()).
			public_rooms = PackedStringArray()
			if text.length() > 6:
				public_rooms = PackedStringArray(text.substr(6).split(" "))
		_:
			pass


## Invitado: pide al rele la lista de salas publicas abiertas (pre-JOIN).
func list_rooms() -> void:
	if _ws != null and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws.send_text("LIST")


## MultiplayerPeer.get_available_packet_count.
func get_available_packet_count() -> int:
	return _rx.size()


## MultiplayerPeer.get_packet.
func get_packet() -> PackedByteArray:
	if _rx.is_empty():
		return PackedByteArray()
	return _rx.pop_front()


## Siempre el rival (id 1).
func get_packet_peer() -> int:
	return _remote_id


func put_packet(packet: PackedByteArray) -> int:
	if _ws == null or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return ERR_UNAVAILABLE
	return _ws.send(packet)


# La fiabilidad la da TCP debajo: el canal y el modo de ENet son equivalentes aqui.
func set_transfer_mode(_mode: int) -> void:
	pass


func set_transfer_channel(_channel: int) -> void:
	pass


func set_target_peer(_id: int) -> void:
	pass


func disconnect_peer(_id: int, _force := false) -> void:
	close()


## Lan espera un objeto con peer_disconnect_later (ENetPacketPeer).
func get_peer(_id: int) -> RemotePeer:
	return RemotePeer.new(self)


## Lan llama _peer.host.flush() tras encolar el cierre.
var host: FlushPoint:
	get:
		if _host == null:
			_host = FlushPoint.new(self)
		return _host


var _host: FlushPoint


## Traduccion a MultiplayerPeer.ConnectionStatus.
func get_connection_status() -> int:
	if _ws == null:
		return MultiplayerPeer.CONNECTION_DISCONNECTED
	match _ws.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			return MultiplayerPeer.CONNECTION_CONNECTING
		WebSocketPeer.STATE_OPEN:
			return MultiplayerPeer.CONNECTION_CONNECTED if _linked else MultiplayerPeer.CONNECTION_CONNECTING
		_:
			return MultiplayerPeer.CONNECTION_DISCONNECTED


func close() -> void:
	if _ws != null:
		_ws.close()
		_ws = null
	_linked = false


class RemotePeer:
	var _owner: RelayPeer

	func _init(owner: RelayPeer) -> void:
		_owner = owner

	func peer_disconnect_later() -> void:
		_owner.close()


class FlushPoint:
	var _owner: RelayPeer

	func _init(owner: RelayPeer) -> void:
		_owner = owner

	func flush() -> void:
		if _owner._ws != null:
			_owner._ws.poll()
