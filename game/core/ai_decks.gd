extends RefCounted
## Mazos extra de la CPU: dos generados por el port (beatdown y bastion) mas los que
## el usuario deje en `PoC Data/ai_decks/<juego>/` (.ydc o .json de la comunidad).
## choose_rival_deck los usa a veces en vez del mazo nativo, con mas probabilidad
## cuando el jugador encadena victorias.

const GEN := "_gen_v1_"
## Staples del formato PoC reconocibles por nombre ingles (en minusculas).
const STAPLES := ["raigeki", "dark hole", "monster reborn", "pot of greed",
		"change of heart", "megamorph", "fissure", "giant trunade", "heavy storm",
		"swords of revealing light", "mirror force", "torrential tribute",
		"trap hole", "waboku", "magic jammer", "solemn judgment", "card destruction",
		"mystical space typhoon", "de-spell", "remove trap", "polymerization",
		"seven tools of the bandit", "spellbinding circle", "gift of the mystical elf",
		"just desserts", "magic cylinder"]


static func dir_for(game: String) -> String:
	# storage_dir, no data_dir: en la web data_dir es res://webdata (solo lectura).
	return Paths.storage_dir.path_join("ai_decks").path_join(game)


## Prepara el directorio: convierte .ydc sueltos y escribe los mazos generados.
static func ensure(game: String) -> void:
	var dir := dir_for(game)
	DirAccess.make_dir_recursive_absolute(dir)
	_import_ydc(dir)
	if not FileAccess.file_exists(dir.path_join(GEN + "beatdown.json")):
		_generate(game, dir)


static func files(game: String) -> PackedStringArray:
	ensure(game)
	var out := PackedStringArray()
	var d := DirAccess.open(dir_for(game))
	if d == null: return out
	for f in d.get_files():
		if f.ends_with(".json"):
			out.append(f)
	return out


## {} o un mazo del directorio con `_name` (el fichero). Sale mas a menudo cuanto
## mejor le va al jugador: con la racha cero es 25%, ganando mucho llega a 65%.
static func pick(game: String, draw: Callable) -> Dictionary:
	var stats: Dictionary = SaveData.data.get("stats", {}).get(game, {})
	var streak := int(stats.get("streak", 0)) if int(stats.get("streak_last", 0)) == 1 else 0
	var chance := 25 + mini(40, 10 * streak)
	if int(draw.call() % 100) >= chance:
		return {}
	var list := files(game)
	for n in mini(list.size(), 4):
		var f := list[int(draw.call()) % list.size()]
		var deck: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir_for(game).path_join(f)))
		if deck is Dictionary and deck.get("main", []).size() >= 40 and deck.get("main", []).size() <= 80:
			deck["_name"] = f
			return deck
	return {}


static func _import_ydc(dir: String) -> void:
	var d := DirAccess.open(dir)
	if d == null: return
	for f in d.get_files():
		if not f.ends_with(".ydc"): continue
		var json_path := dir.path_join(f.get_basename() + ".json")
		if FileAccess.file_exists(json_path): continue
		var deck := Ydc.load(dir.path_join(f))
		if deck.is_empty(): continue
		var out := FileAccess.open(json_path, FileAccess.WRITE)
		out.store_string(JSON.stringify({"main": deck.get("main", []),
				"fusion": deck.get("fusion", []), "side": deck.get("side", [])}))
		out.close()


static func _generate(game: String, dir: String) -> void:
	var mons: Array = []
	var staples: Array = []
	for c in CardDB.usable_in(game):
		var g := CardDB.group_of(c)
		if g == CardDB.Group.NORMAL or g == CardDB.Group.EFFECT:
			mons.append(c)
		elif g == CardDB.Group.SPELL or g == CardDB.Group.TRAP:
			var label := CardDB.name_of(int(c["internal_id"]), "eng").to_lower()
			for s in STAPLES:
				if label.contains(s):
					staples.append(int(c["internal_id"]))
					break
	var low := mons.filter(func(c): return int(c.get("level", 0)) <= 4)
	var atk := low.duplicate()
	atk.sort_custom(func(a, b): return int(a.get("atk", 0)) > int(b.get("atk", 0)))
	_save(dir.path_join(GEN + "beatdown.json"), _fill(atk, 22, staples, 40))
	var def_: Array = mons.duplicate()
	def_.sort_custom(func(a, b): return int(a.get("defense", 0)) > int(b.get("defense", 0)))
	_save(dir.path_join(GEN + "bastion.json"), _fill(def_, 18, staples, 40))


## `count` monstruos (max. 2 copias) + staples (max. 3 de cada) hasta `total`.
static func _fill(mons: Array, count: int, staples: Array, total: int) -> Array:
	var deck: Array = []
	for c in mons:
		if deck.size() >= count: break
		var id := int(c["internal_id"])
		for i in mini(2, count - deck.size()):
			deck.append(id)
	for id in staples:
		if deck.size() >= total: break
		for i in mini(2, total - deck.size()):
			deck.append(id)
	for c in mons:
		if deck.size() >= total: break
		var id := int(c["internal_id"])
		if deck.count(id) < 3:
			deck.append(id)
	return deck


static func _save(path: String, main: Array) -> void:
	var out := FileAccess.open(path, FileAccess.WRITE)
	if out == null: return
	out.store_string(JSON.stringify({"main": main, "fusion": [], "side": []}))
	out.close()
