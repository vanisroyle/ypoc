extends Control
## Dialogo de contrasenas: 8 digitos como en los juegos de consola (ruedas de
## digitos, funcionan con teclado, raton y mando) para desbloquear una carta,
## mas un boton de desbloqueo total. Arte propio del hub combinado.

signal closed

const GOLD := Color(1.0, 0.82, 0.3)
const GOLD_LIGHT := Color(1.0, 0.95, 0.7)
const PANEL := Color(0.13, 0.09, 0.06)
const LOCKED := Color(0.4, 0.4, 0.4)

var _digits := [0, 0, 0, 0, 0, 0, 0, 0]
var _cursor := 0
var _boxes: Array[Label] = []
var _result: Label
var _art: TextureRect
var _ok: Button


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.position = Vector2(190, 140)
	panel.custom_minimum_size = Vector2(420, 330)
	panel.size = panel.custom_minimum_size
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	var title := _label("CONTRASENA" if Assets.lang == "s" else "PASSWORD", 22, GOLD)
	v.add_child(title)
	v.add_child(_label(
		"codigo de 8 digitos de la carta — clic para elegir, escribe o toca para girar" if Assets.lang == "s"
		else "8-digit card code — click to pick, type or tap to spin", 12, LOCKED))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	for i in 8:
		var b := Label.new()
		b.text = "0"
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.custom_minimum_size = Vector2(38, 52)
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		b.add_theme_font_size_override("font_size", 30)
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.09, 0.07, 0.05)
		s.border_color = Color(0.45, 0.35, 0.15)
		s.set_border_width_all(2)
		s.set_corner_radius_all(4)
		b.add_theme_stylebox_override("normal", s)
		_boxes.append(b)
		row.add_child(b)
	_paint_cursor()

	_art = TextureRect.new()
	_art.custom_minimum_size = Vector2(60, 87)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var center := CenterContainer.new()
	center.add_child(_art)
	v.add_child(center)

	_result = _label(" ", 15, GOLD_LIGHT)
	_result.custom_minimum_size = Vector2(400, 40)
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_result)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 10)
	v.add_child(buttons)
	_ok = _button("OK", func() -> void: _confirm())
	buttons.add_child(_ok)
	buttons.add_child(_button("DESBLOQUEAR TODO" if Assets.lang == "s" else "UNLOCK ALL",
		func() -> void: _unlock_all()))
	buttons.add_child(_button("VOLVER" if Assets.lang == "s" else "BACK", func() -> void: closed.emit()))
	_ok.grab_focus()


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(110, 36)
	b.add_theme_font_size_override("font_size", 14)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.2, 0.14, 0.08)
	normal.border_color = Color(0.45, 0.35, 0.15)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(4)
	b.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.border_color = GOLD
	hover.bg_color = Color(0.32, 0.22, 0.1)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_color_override("font_color", GOLD_LIGHT)
	b.add_theme_color_override("font_hover_color", GOLD_LIGHT)
	b.add_theme_color_override("font_focus_color", GOLD_LIGHT)
	b.pressed.connect(on_press)
	return b


func _paint_cursor() -> void:
	for i in _boxes.size():
		_boxes[i].text = str(_digits[i])
		var s: StyleBoxFlat = _boxes[i].get_theme_stylebox("normal").duplicate()
		s.border_color = GOLD if i == _cursor else Color(0.45, 0.35, 0.15)
		_boxes[i].add_theme_color_override("font_color",
			GOLD_LIGHT if i == _cursor else GOLD)
		_boxes[i].add_theme_stylebox_override("normal", s)


func _code() -> int:
	var c := 0
	for d in _digits:
		c = c * 10 + d
	return c


func _confirm() -> void:
	var card := CardDB.by_password(_code())
	if card.is_empty():
		_art.texture = null
		_result.text = ("CONTRASENA INVALIDA" if Assets.lang == "s" else "INVALID PASSWORD")
		_result.add_theme_color_override("font_color", Color(0.9, 0.4, 0.3))
		Audio.play_sfx("%s/voice/internal/unable.wav" % _menu_game())
		return
	var id := int(card["internal_id"])
	var gained := SaveData.unlock_card(id)
	_art.texture = CardDB.card_texture(id)
	_result.text = "%s  —  +%d %s" % [CardDB.name_of(id), gained,
		"COPIAS (total %d)" % SaveData.card_count(id) if Assets.lang == "s"
		else "COPIES (total %d)" % SaveData.card_count(id)]
	_result.add_theme_color_override("font_color", Color(0.6, 0.9, 0.5))
	Audio.play_sfx("%s/voice/internal/decide.wav" % _menu_game())


func _unlock_all() -> void:
	SaveData.unlock_all()
	_art.texture = null
	_result.text = ("TODAS LAS CARTAS DESBLOQUEADAS" if Assets.lang == "s" else "ALL CARDS UNLOCKED")
	_result.add_theme_color_override("font_color", Color(0.6, 0.9, 0.5))
	Audio.play_sfx("%s/voice/internal/decide.wav" % _menu_game())


func _menu_game() -> String:
	return "joey" if Paths.has_game("joey") else "yugi"


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Clic sobre una cifra: la selecciona y la gira (tap-friendly).
		for i in _boxes.size():
			if _boxes[i].get_global_rect().has_point(event.global_position):
				if i == _cursor:
					_digits[i] = (_digits[i] + 1) % 10
				_cursor = i
				_paint_cursor()
				accept_event()
				return


func _input(event: InputEvent) -> void:
	# _input, no _unhandled_key_input: las flechas y el Enter no deben llegar a la
	# navegacion de botones antes de que las vean las ruedas de digitos.
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ESCAPE:
			closed.emit()
		KEY_LEFT:
			_cursor = (_cursor - 1 + 8) % 8
			_paint_cursor()
		KEY_RIGHT:
			_cursor = (_cursor + 1) % 8
			_paint_cursor()
		KEY_UP:
			_digits[_cursor] = (_digits[_cursor] + 1) % 10
			_paint_cursor()
		KEY_DOWN:
			_digits[_cursor] = (_digits[_cursor] + 9) % 10
			_paint_cursor()
		KEY_BACKSPACE:
			_cursor = maxi(0, _cursor - 1)
			_digits[_cursor] = 0
			_paint_cursor()
		KEY_ENTER, KEY_KP_ENTER:
			_confirm()
		_:
			var d: int = event.keycode - KEY_0
			if d < 0 or d > 9:
				d = event.keycode - KEY_KP_0
			if d >= 0 and d <= 9:
				_digits[_cursor] = d
				_cursor = mini(7, _cursor + 1)
				_paint_cursor()
			else:
				return
	accept_event()
