extends Node2D
## Arranque: comprueba que existe data/ y abre el selector de juego.
## En web los recursos viajan en packs/*.pck: se descargan (o se recuperan
## de la cache IDBFS de user://) y se montan antes de entrar al juego.

const PACK_DIR := "user://packs"
const PACK_CACHE := "user://packs.json"

var _manifest := {}
var _queue: Array = []
var _done := 0
var _total := 0
var _req: HTTPRequest
var _manifest_text := ""
var _status: Label
var _bar: ProgressBar
var _base := ""


func _ready() -> void:
	_apply_window_override()
	if OS.has_feature("web") and not DirAccess.dir_exists_absolute("res://webdata"):
		_web_bootstrap()
		return
	_start()


func _start() -> void:
	# Sin recursos: el importador de las copias del usuario.
	if not Paths.has_data() or Paths.storage_error:
		Game.open_launcher()
		queue_free()
		return
	var start := Debug.start_override()
	var ending := Paths.cmdline_value("scene")
	if ending in ["credits", "video"]:
		Game.open_ending(start if start in Game.GAMES else "yugi", ending)
	elif ending == "joey-native":
		Game.current_game = "joey"
		Game.goto(load("res://scenes/duel/joey_native_normal.gd").new())
	elif ending == "joey-engine-harness":
		Game.current_game = "joey"
		Game.goto(load("res://scenes/duel/joey_native_duel.tscn").instantiate())
	elif ending == "lan":
		# Herramienta de desarrollo: --scene=lan abre la pantalla de conexion de Joey (D17).
		Game.open_lan("joey")
	elif Paths.cmdline_value("scenario") != "":
		# Herramienta de desarrollo: --scenario=<nombre o ruta> abre el duelo preparado.
		Game.open_normal_duel(start if start in Game.GAMES else "yugi")
	elif start in Game.GAMES:
		Game.open_title(start)
	else:
		# Portada unica: la campaña con los tres rivales en un solo juego. El
		# selector del lanzador solo se usa con migracion pendiente o una cuenta
		# de Drive vinculada: ambos pasos ocurren en el selector.
		var any_game := false
		for game in Game.GAMES:
			if Paths.has_game(game):
				any_game = true
		if Paths.migration_source == "" and not CloudSync.linked() and any_game:
			Game.open_main_menu()
		else:
			Game.open_launcher()
	queue_free()


# ---- Descarga de packs (web) -----------------------------------------------

func _web_bootstrap() -> void:
	_loader_ui()
	_status.text = "Connecting..."
	# HTTPRequest exige URL absoluta; la base es el directorio donde vive index.html.
	_base = str(JavaScriptBridge.eval(
			"location.origin + location.pathname.substring(0, location.pathname.lastIndexOf('/') + 1)"))
	var probe := HTTPRequest.new()
	add_child(probe)
	probe.request_completed.connect(_on_manifest.bind(probe))
	probe.request(_base + "packs/packs.json")


func _on_manifest(result: int, code: int, _h: PackedStringArray, body: PackedByteArray,
		probe: HTTPRequest) -> void:
	probe.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		# Sin red: si la cache esta completa se juega igual (los packs ya
		# bajados se guardan en user:// junto al manifest).
		if _mount_cached():
			return
		_fail("Could not reach the server.")
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("packs"):
		_fail("Bad pack manifest.")
		return
	_manifest = parsed
	_manifest_text = body.get_string_from_utf8()
	_queue = []
	_total = 0
	for p in _manifest["packs"]:
		_total += int(p["bytes"])
		_queue.append(p["name"])
	if _cache_valid():
		_mount_all()
	else:
		_status.text = "Downloading cards..."
		_req = HTTPRequest.new()
		add_child(_req)
		_req.request_completed.connect(_on_pack)
		_next_pack()


## La cache de user:// vale si el manifest coincide y todos los packs estan.
func _cache_valid() -> bool:
	if not FileAccess.file_exists(PACK_CACHE):
		return false
	var f := FileAccess.open(PACK_CACHE, FileAccess.READ)
	if f == null or f.get_as_text() != _manifest_text:
		return false
	return _files_ok(_manifest)


## Monta la cache guardada usando su propio manifest (modo sin conexion).
func _mount_cached() -> bool:
	if not FileAccess.file_exists(PACK_CACHE):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PACK_CACHE))
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("packs"):
		return false
	if not _files_ok(parsed):
		return false
	_manifest = parsed
	_mount_all()
	return true


func _files_ok(manifest: Dictionary) -> bool:
	for p in manifest["packs"]:
		var path := PACK_DIR.path_join(p["name"])
		if not FileAccess.file_exists(path):
			return false
		var g := FileAccess.open(path, FileAccess.READ)
		if g == null or g.get_length() != int(p["bytes"]):
			return false
		g.close()
	return true


func _next_pack() -> void:
	if _queue.is_empty():
		# El manifest se guarda solo al completar la descarga entera.
		DirAccess.make_dir_recursive_absolute(PACK_DIR)
		var f := FileAccess.open(PACK_CACHE, FileAccess.WRITE)
		f.store_string(_manifest_text)
		f.close()
		_mount_all()
		return
	_req.request(_base + "packs/" + _queue[0])


func _on_pack(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_fail("Download interrupted.")
		return
	DirAccess.make_dir_recursive_absolute(PACK_DIR)
	var name: String = _queue.pop_front()
	var f := FileAccess.open(PACK_DIR.path_join(name), FileAccess.WRITE)
	f.store_buffer(body)
	f.close()
	_done += body.size()
	_next_pack()


func _mount_all() -> void:
	_status.text = "Loading cards..."
	for p in _manifest["packs"]:
		var path := PACK_DIR.path_join(p["name"])
		if not ProjectSettings.load_resource_pack(path, false):
			_fail("Corrupt download, reload to retry.")
			return
	# Los autoloads que leyeron data/ en _ready (aun vacia) recargan ahora.
	# El indice se guarda en user:// y se reusa mientras no cambie el manifiesto.
	Assets.reindex_cached(str(_manifest.get("version", "")))
	CardDB.load_db()
	Audio.reload_native_tables()
	SaveData.load_or_create()
	_start()


func _process(_delta: float) -> void:
	if _req == null:
		return
	var current := _req.get_downloaded_bytes()
	var target := _req.get_body_size()
	var pct := (_done + current) * 100.0 / maxf(_total, 1)
	_bar.value = pct
	var mb := (_done + current) / 1048576.0
	_status.text = "Downloading cards... %d MB / %d MB" % [mb, _total / 1048576.0]
	if target <= 0:
		_bar.value = _done * 100.0 / maxf(_total, 1)


func _fail(why: String) -> void:
	_bar.hide()
	_status.text = why + "\nCheck your connection and reload the page."


# ---- Pantalla de carga ------------------------------------------------------

func _loader_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.07)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)

	var title := Label.new()
	title.text = "POWER OF CHAOS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.83, 0.68, 0.32))
	box.add_child(title)

	var sub := Label.new()
	sub.text = "Campaign Edition"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.55, 0.55, 0.62))
	box.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(1, 24)
	box.add_child(spacer)

	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(420, 22)
	_bar.max_value = 100.0
	_bar.show_percentage = false
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.14, 0.14, 0.2)
	back.set_corner_radius_all(6)
	_bar.add_theme_stylebox_override("background", back)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.83, 0.68, 0.32)
	fill.set_corner_radius_all(6)
	_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(_bar)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	box.add_child(_status)


## El modo maximizado se configura al crear la ventana en project.godot.
## --window=ANCHOxALTO tiene prioridad sobre la preferencia del launcher.
func _apply_window_override() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var forced := Paths.cmdline_value("window").split("x")
	if forced.size() == 2 and forced[0].is_valid_int() and forced[1].is_valid_int():
		var size := Vector2i(forced[0].to_int(), forced[1].to_int())
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(size)
		var screen := DisplayServer.window_get_current_screen()
		DisplayServer.window_set_position(DisplayServer.screen_get_position(screen)
				+ (DisplayServer.screen_get_size(screen) - size) / 2)
		return
	if LauncherSettings.fullscreen_mode != Window.MODE_WINDOWED:
		get_window().mode = LauncherSettings.fullscreen_mode
