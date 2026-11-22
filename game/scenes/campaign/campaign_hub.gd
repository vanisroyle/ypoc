class_name CampaignHub
extends Control
## Menu unico del juego combinado: las tres campañas se recorren desde aqui.
## Estructura del menu de Joey (duelo / mazo / lista / opciones / salir), dibujado
## propio porque el juego no replica una sola pantalla original. Pagina "duel":
## rivales yugi -> kaiba -> joey (el ya vencido admite revancha), modo Duelo o
## Match al mejor de 3, duelo en red y repeticiones.

const GOLD := Color(1.0, 0.82, 0.3)
const GOLD_LIGHT := Color(1.0, 0.95, 0.7)
const STONE := Color(0.07, 0.05, 0.04)
const PANEL := Color(0.13, 0.09, 0.06)
const LOCKED := Color(0.4, 0.4, 0.4)

const RIVALS := [
	{"game": "yugi", "name": "Yugi", "art": "yugi/bust_up/gofu/gofu_#00.webp"},
	{"game": "kaiba", "name": "Kaiba", "art": "kaiba/bust_up/win/lose_all#e.webp"},
	{"game": "joey", "name": "Joey", "art": "joey/bust_up/start/reaction16.webp"},
]
const MUSIC := {
	"yugi": "yugi/voice/stream/menu.wav",
	"kaiba": "kaiba/voice/stream/m_title.wav",
	"joey": "joey/voice/stream/m_menu.wav",
}

var _page := ""
var _match := false
var _root: Control = null
var _options: Node2D = null
var _replay_dialog: Control = null


func _init(page := "") -> void:
	_page = page


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = STONE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	Audio.play_music(MUSIC.get(_menu_game(), ""))
	_footer()
	_show(_page if _page != "" else "main")


func _process(_delta: float) -> void:
	if _options != null and _options.visible:
		_options._mouse = get_local_mouse_position()
		_options.tick()


func _input(event: InputEvent) -> void:
	# No marcar como consumido: Game._input y PlatformInput deben seguir viendo
	# teclado/mando para que el puntero se mueva dentro del panel de opciones.
	if _options != null:
		_options.handle_input(event)


func _unhandled_input(event: InputEvent) -> void:
	if _options != null or _replay_dialog != null:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.pressed
			and event.button_index == MOUSE_BUTTON_RIGHT):
		if _page != "main":
			_back_sfx()
			_show("main")


func _sfx(kind: String) -> void:
	Audio.play_sfx("%s/voice/internal/%s.wav" % [_menu_game(), kind])


func _back_sfx() -> void:
	_sfx("return")


## Juego que presta arte, sonido y opciones al menu: joey si esta instalado.
func _menu_game() -> String:
	return "joey" if Paths.has_game("joey") else _most_complete_game()


func _most_complete_game() -> String:
	var best := ""
	for game in Game.GAMES:
		if Paths.has_game(game):
			best = game
	return best if best != "" else "yugi"


# --- paginas ---------------------------------------------------------------------------------

func _show(page: String) -> void:
	_page = page
	if is_instance_valid(_root):
		_root.queue_free()
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	match page:
		"duel":
			_page_duel()
		_:
			_page_main()


func _page_title(text: String) -> void:
	var title := Label.new()
	title.text = text
	title.add_theme_color_override("font_color", GOLD)
	title.add_theme_font_size_override("font_size", 22)
	title.position = Vector2(0, 18)
	title.size = Vector2(800, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(title)


func _page_main() -> void:
	_page_title("PODER DEL CAOS" if Assets.lang == "s" else "POWER OF CHAOS")
	var sub := Label.new()
	sub.text = ("los tres juegos, una campaña" if Assets.lang == "s" else "the three games, one campaign")
	sub.add_theme_color_override("font_color", Color(0.75, 0.7, 0.6))
	sub.add_theme_font_size_override("font_size", 14)
	sub.position = Vector2(0, 48)
	sub.size = Vector2(800, 20)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(sub)

	var items := [
		["duel", "Duelo" if Assets.lang == "s" else "Duel", func() -> void: _show("duel")],
		["deck", "Constructor de mazo" if Assets.lang == "s" else "Deck Construction", func() -> void:
			_sfx("decide")
			Game.open_deck_editor(_deck_game())],
		["list", "Lista de cartas" if Assets.lang == "s" else "Card List", func() -> void:
			_sfx("decide")
			Game.open_card_list(_menu_game())],
		["options", "Opciones" if Assets.lang == "s" else "Options", _open_options],
		["exit", "Salir" if Assets.lang == "s" else "Exit", func() -> void:
			_back_sfx()
			Audio.stop_music()
			Game.open_launcher()],
	]
	var y := 150
	for item: Array in items:
		var btn := _menu_button(item[1], Vector2(270, y), Vector2(260, 48), item[2])
		if item[0] == "options" and not Paths.has_game(_menu_game()):
			btn.disabled = true
		_root.add_child(btn)
		y += 58
	_root.get_child(2).grab_focus()   # primer boton (tras titulo y subtitulo)


func _page_duel() -> void:
	_page_title("ELIGE RIVAL" if Assets.lang == "s" else "CHOOSE OPPONENT")
	var defeated: Array = SaveData.data.get("campaign", {}).get("defeated", [])
	var next := SaveData.campaign_next()
	for i in RIVALS.size():
		var rival: Dictionary = RIVALS[i]
		var game: String = rival["game"]
		var state := "locked"
		var open := false
		if Paths.has_game(game):
			if game in defeated:
				state = "defeated"
				open = true
			elif game == next:
				state = "next"
				open = true
		_add_rival_panel(i, rival, state, open)

	var toggle := _menu_button(
		("MODO MATCH — MEJOR DE 3" if Assets.lang == "s" else "MATCH MODE — BEST OF 3") + ("  [X]" if _match else "  [ ]"),
		Vector2(40, 532), Vector2(240, 40), func() -> void:
			_match = not _match
			_sfx("decide")
			_show("duel"))
	_root.add_child(toggle)
	_root.add_child(_menu_button("DUELO EN RED" if Assets.lang == "s" else "LAN / ONLINE DUEL",
		Vector2(290, 532), Vector2(200, 40), func() -> void:
			_sfx("decide")
			Game.open_lan("joey"), not Paths.has_game("joey")))
	_root.add_child(_menu_button("REPETICIONES" if Assets.lang == "s" else "REPLAYS",
		Vector2(500, 532), Vector2(140, 40), _open_replays, _replay_count() == 0))
	_root.add_child(_menu_button("VOLVER" if Assets.lang == "s" else "BACK",
		Vector2(650, 532), Vector2(110, 40), func() -> void:
			_back_sfx()
			_show("main")))


## Mazo que se edita por defecto: el del proximo rival de la campaña; sin el, el del
## juego mas completo (joey tiene el pool completo de las 1113 cartas).
func _deck_game() -> String:
	var next := SaveData.campaign_next()
	if next != "" and Paths.has_game(next):
		return next
	return _menu_game()


# --- pagina de duelo: paneles de rival --------------------------------------------------------

func _add_rival_panel(i: int, rival: Dictionary, state: String, open: bool) -> void:
	var x := 40 + i * 245
	var panel := PanelContainer.new()
	panel.position = Vector2(x, 60)
	panel.custom_minimum_size = Vector2(220, 440)
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL if open else Color(0.09, 0.08, 0.08)
	style.border_color = GOLD if state == "next" else (Color(0.5, 0.5, 0.5) if state == "locked" else Color(0.45, 0.35, 0.15))
	style.set_border_width_all(3 if state == "next" else 1)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	_root.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	var art := TextureRect.new()
	art.custom_minimum_size = Vector2(196, 147)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex := Assets.texture(rival["art"])
	if tex != null:
		art.texture = tex
	art.modulate = Color(1, 1, 1) if open else Color(0.35, 0.35, 0.35)
	v.add_child(art)

	var name_label := Label.new()
	name_label.text = rival["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.add_theme_color_override("font_color", GOLD_LIGHT if open else LOCKED)
	v.add_child(name_label)

	var status := Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 15)
	match state:
		"defeated":
			status.text = "DERROTADO — revancha disponible" if Assets.lang == "s" else "DEFEATED — rematch available"
			status.add_theme_color_override("font_color", Color(0.6, 0.9, 0.5))
		"next":
			status.text = "SIGUIENTE RIVAL" if Assets.lang == "s" else "NEXT RIVAL"
			status.add_theme_color_override("font_color", GOLD)
		_:
			status.text = "BLOQUEADO" if Assets.lang == "s" else "LOCKED"
			status.add_theme_color_override("font_color", LOCKED)
	v.add_child(status)

	var hint := Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color(0.75, 0.7, 0.6) if open else LOCKED)
	var stats: Dictionary = SaveData.data.get("stats", {}).get(rival["game"], {})
	var streak := int(stats.get("streak", 0))
	if rival["game"] == "joey":
		hint.text = ("Nivel de IA: %d/7" if Assets.lang == "s" else "AI level: %d/7") % int(stats.get("level", 1))
	elif streak > 0:
		hint.text = ("Racha: %d" if Assets.lang == "s" else "Streak: %d") % streak
	else:
		hint.text = ""
	v.add_child(hint)

	var duel := Button.new()
	duel.text = ("DUELAR" if state != "defeated" else "REVANCHA") if Assets.lang == "s" else ("DUEL" if state != "defeated" else "REMATCH")
	duel.custom_minimum_size = Vector2(0, 44)
	duel.add_theme_font_size_override("font_size", 18)
	duel.disabled = not open
	duel.add_theme_color_override("font_color", GOLD_LIGHT if open else LOCKED)
	duel.pressed.connect(func() -> void:
		_sfx("decide")
		Game.start_normal_duel(rival["game"], 1 if _match else 0))
	v.add_child(duel)


func _replay_count() -> int:
	var n := 0
	for game in Game.GAMES:
		if Paths.has_game(game):
			n += DuelResult.replay_files(game).size()
	return n


# --- repeticiones -----------------------------------------------------------------------------

func _open_replays() -> void:
	_sfx("decide")
	var dialog := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	dialog.add_theme_stylebox_override("panel", style)
	dialog.position = Vector2(180, 120)
	dialog.custom_minimum_size = Vector2(440, 360)
	_root.add_child(dialog)
	_replay_dialog = dialog

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	dialog.add_child(v)
	var title := Label.new()
	title.text = "REPETICIONES" if Assets.lang == "s" else "REPLAYS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", GOLD)
	v.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(400, 250)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for game in Game.GAMES:
		if not Paths.has_game(game):
			continue
		for name in DuelResult.replay_files(game):
			var b := Button.new()
			b.text = "%s · %s" % [rival_name(game), name]
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.add_theme_color_override("font_color", GOLD_LIGHT)
			b.pressed.connect(func() -> void:
				_sfx("decide")
				Game.open_duel_replay(game, "file:" + DuelResult.replays_dir(game).path_join(name + ".ydr")))
			list.add_child(b)
	v.add_child(_menu_button("CANCELAR" if Assets.lang == "s" else "CANCEL", Vector2.ZERO, Vector2(0, 34), func() -> void:
		_back_sfx()
		_replay_dialog = null
		dialog.queue_free()))


func rival_name(game: String) -> String:
	for rival in RIVALS:
		if rival["game"] == game:
			return rival["name"]
	return game


# --- opciones ---------------------------------------------------------------------------------

func _open_options() -> void:
	_sfx("decide")
	_options = preload("res://scenes/title/title_options.gd").new(_menu_game())
	add_child(_options)
	_root.visible = false
	Audio.set_option_volume(_options.volume)
	_options.exit_requested.connect(func() -> void:
		_options.save()
		_back_sfx()
		_options.queue_free()
		_options = null
		_root.visible = true)


# --- pie y botones ----------------------------------------------------------------------------

func _footer() -> void:
	var pool := CardDB.obtainable()
	var owned := 0
	for card in pool:
		owned += int(SaveData.card_count(int(card["internal_id"])) > 0)

	var bar := Label.new()
	bar.text = ("Colección: %d/%d cartas" if Assets.lang == "s" else "Collection: %d/%d cards") % [owned, pool.size()]
	bar.add_theme_color_override("font_color", GOLD_LIGHT)
	bar.add_theme_font_size_override("font_size", 16)
	bar.position = Vector2(40, 568)
	bar.size = Vector2(400, 30)
	add_child(bar)


func _menu_button(text: String, pos: Vector2, size: Vector2, on_press: Callable, disabled := false) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.custom_minimum_size = size
	btn.size = size
	btn.disabled = disabled
	btn.add_theme_font_size_override("font_size", 17)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.2, 0.14, 0.08) if not disabled else Color(0.11, 0.11, 0.11)
	normal.border_color = Color(0.45, 0.35, 0.15) if not disabled else Color(0.25, 0.25, 0.25)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.border_color = GOLD
	hover.bg_color = Color(0.32, 0.22, 0.1)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_color_override("font_color", GOLD_LIGHT if not disabled else LOCKED)
	btn.add_theme_color_override("font_hover_color", GOLD_LIGHT)
	btn.add_theme_color_override("font_disabled_color", LOCKED)
	btn.add_theme_color_override("font_focus_color", GOLD_LIGHT)
	btn.pressed.connect(on_press)
	return btn
