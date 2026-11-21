class_name CampaignHub
extends Control
## Pantalla de la campaña: los tres rivales en un solo juego. Derrotar a cada uno
## abre al siguiente (yugi -> kaiba -> joey); los ya vencidos pueden rejugar para
## seguir ganando cartas. Los duelos corren en el motor propio de cada rival y la
## IA escala con las rachas (stats) como en los originales.

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


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = STONE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "PODER DEL CAOS — CAMPAÑA"
	title.add_theme_color_override("font_color", GOLD)
	title.add_theme_font_size_override("font_size", 22)
	title.position = Vector2(0, 18)
	title.size = Vector2(800, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	var defeated: Array = SaveData.data.get("campaign", {}).get("defeated", [])
	var next := SaveData.campaign_next()
	for i in RIVALS.size():
		var rival: Dictionary = RIVALS[i]
		var game: String = rival["game"]
		# Desbloqueado si el juego esta instalado y ya fue vencido o es el
		# rival pendiente de la campaña; el resto queda bloqueado.
		var state := "locked"
		var open := false
		if Paths.has_game(game):
			if game in defeated:
				state = "defeated"
				open = true
			elif game == next:
				state = "next"
				open = true
		_add_panel(i, rival, state, open)

	_footer()


func _add_panel(i: int, rival: Dictionary, state: String, open: bool) -> void:
	var x := 40 + i * 245
	var panel := PanelContainer.new()
	panel.position = Vector2(x, 70)
	panel.custom_minimum_size = Vector2(220, 420)
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL if open else Color(0.09, 0.08, 0.08)
	style.border_color = GOLD if state == "next" else (Color(0.5, 0.5, 0.5) if state == "locked" else Color(0.45, 0.35, 0.15))
	style.set_border_width_all(3 if state == "next" else 1)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

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
			status.text = "DERROTADO — revancha disponible"
			status.add_theme_color_override("font_color", Color(0.6, 0.9, 0.5))
		"next":
			status.text = "SIGUIENTE RIVAL"
			status.add_theme_color_override("font_color", GOLD)
		_:
			status.text = "BLOQUEADO"
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
		hint.text = "Nivel de IA: %d/7" % int(stats.get("level", 1))
	elif streak > 0:
		hint.text = "Racha: %d" % streak
	else:
		hint.text = ""
	v.add_child(hint)

	var duel := Button.new()
	duel.text = "DUELAR" if state != "defeated" else "REVANCHA"
	duel.custom_minimum_size = Vector2(0, 44)
	duel.add_theme_font_size_override("font_size", 18)
	duel.disabled = not open
	var bstyle := StyleBoxFlat.new()
	bstyle.bg_color = Color(0.45, 0.3, 0.08) if open else Color(0.15, 0.15, 0.15)
	bstyle.border_color = GOLD if open else Color(0.3, 0.3, 0.3)
	bstyle.set_border_width_all(2)
	bstyle.set_corner_radius_all(4)
	duel.add_theme_stylebox_override("normal", bstyle)
	duel.add_theme_color_override("font_color", GOLD_LIGHT if open else LOCKED)
	duel.pressed.connect(_on_duel.bind(rival["game"]))
	v.add_child(duel)


func _footer() -> void:
	var pool := CardDB.obtainable_in("joey")
	var owned := 0
	for card in pool:
		owned += int(SaveData.card_count(int(card["internal_id"])) > 0)

	var bar := Label.new()
	bar.text = "Colección: %d/%d cartas" % [owned, pool.size()]
	bar.add_theme_color_override("font_color", GOLD_LIGHT)
	bar.add_theme_font_size_override("font_size", 16)
	bar.position = Vector2(40, 540)
	bar.size = Vector2(400, 30)
	add_child(bar)

	var free := Button.new()
	free.text = "Colección y opciones"
	free.custom_minimum_size = Vector2(220, 40)
	free.position = Vector2(540, 532)
	free.add_theme_font_size_override("font_size", 15)
	free.add_theme_color_override("font_color", GOLD_LIGHT)
	var bstyle := StyleBoxFlat.new()
	bstyle.bg_color = Color(0.2, 0.14, 0.08)
	bstyle.border_color = GOLD
	bstyle.set_border_width_all(1)
	bstyle.set_corner_radius_all(4)
	free.add_theme_stylebox_override("normal", bstyle)
	free.pressed.connect(func() -> void: Game.open_title(_most_complete_game()))
	add_child(free)


func _on_duel(game: String) -> void:
	Game.start_normal_duel(game)


## Juego mas completo instalado (joey > kaiba > yugi), para abrir coleccion y
## opciones aunque falten discos.
func _most_complete_game() -> String:
	var best := ""
	for game in Game.GAMES:
		if Paths.has_game(game):
			best = game
	return best if best != "" else "yugi"
