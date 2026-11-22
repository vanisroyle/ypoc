class_name SelfplayRunner
## Modulo de self-play CPU contra CPU (no forma parte del juego; se excluye de los pck).
##
## Ejecuta N duelos sobre el motor de Joey en modo demostracion (los dos lados de la CPU)
## y vuelca un JSONL por partida con mazos, jugadas, comandos grabados y ganador, para que
## tools/selfplay/train.py destile ai_policy.json.
##
## Uso: godot --headless --path game -- --selfplay=<n> [--selfplay-seed=<s>]
##           [--selfplay-out=<ruta.jsonl>] [--selfplay-cap=<ticks>]

const DECK_DIRS := ["res://ai_decks/yugi", "res://ai_decks/kaiba", "res://ai_decks/joey"]
## Ticks de seguridad por partida (una demo real ronda las decenas de miles).
const DEFAULT_CAP := 200000

var rng := RandomNumberGenerator.new()
## Politica optativa inyectada a los dos bandos (--selfplay-policy=<ruta.json>): evaluarla.
var policy: AIPolicy


## Partida individual: devuelve el registro JSON de la partida o null si el motor no arranca.
func play(decks: Array[Dictionary], first: int, seed: int, cap: int) -> Dictionary:
	var duel: Duel = load("res://scenes/duel/joey_presentation_adapter.gd").create_native(Paths.data_dir)
	if duel == null:
		return {}
	# Demostracion (D35): tipo 7, los dos lados de la CPU, jugador local nativo 1.
	duel.native_normal_kind = 7
	duel.forced_local_player = 1
	(duel as JoeyPresentationAdapter).engine.ai_policy = policy
	duel.start_normal(decks, first & 1, seed)
	var engine := (duel as JoeyPresentationAdapter).engine
	var seen := [{}, {}]
	var plays: Array[Dictionary] = []
	var ticks := 0
	while duel.frame() and ticks < cap:
		for p in 2:
			for z in 11:
				var index := engine.m.u16(JoeyMem.zone(p, z)) & 0xfff
				var card := -1 if index == 0 else int(engine.f4022e0(index) & 0xffff)
				var prev: int = seen[p].get(z, -2)
				if card != prev:
					seen[p][z] = card
					if card >= 0 and prev <= 0:
						plays.append({"t": ticks, "p": p, "z": z, "card": card})
		ticks += 1
	var commands: Array = []
	for quad in duel.file_recorded:
		commands.append([quad[0], quad[1], quad[2], quad[3]])
	return {
		"seed": seed,
		"first": first & 1,
		"winner": duel.winner(),
		"lp": [engine.m.u16(JoeyMem.pl(0) + JoeyMem.P_LP), engine.m.u16(JoeyMem.pl(1) + JoeyMem.P_LP)],
		"ticks": ticks,
		"decks": [Array(decks[0]["main"]), Array(decks[1]["main"])],
		"plays": plays,
		"commands": commands,
	}


## Mazo aleatorio de 40-80 cartas del pool union (bit de Joey = carta usable en el motor).
func random_deck() -> Dictionary:
	var pool := PackedInt32Array()
	for card: Dictionary in CardDB.cards:
		if int(card.get("pack", 0)) & 4:
			pool.append(int(card["internal_id"]))
	var n := 40 + rng.randi_range(0, 20)
	var main := PackedInt32Array()
	for i in n:
		main.append(pool[rng.randi_range(0, pool.size() - 1)])
	return {"main": main, "side": PackedInt32Array(), "fusion": PackedInt32Array()}


## Mazos en res://ai_decks/<juego>/*.json (los empaquetados de la comunidad).
func bundled_decks() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for dir in DECK_DIRS:
		for file in DirAccess.get_files_at(dir):
			var name := file.trim_suffix(".import")
			if not name.ends_with(".json"):
				continue
			var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join(file)))
			if data is not Dictionary:
				continue
			var main := PackedInt32Array()
			for id in data.get("main", []):
				main.append(int(id))
			if main.size() < 40 or main.size() > 80:
				continue
			out.append({"main": main, "side": PackedInt32Array(),
					"fusion": PackedInt32Array(), "_name": name})
	return out


## Lote completo; devuelve la cuenta de partidas escritas.
func run(games: int, seed: int, out_path: String, cap: int) -> int:
	rng.seed = seed
	var pool := bundled_decks()
	if pool.is_empty():
		push_error("selfplay: no hay mazos en res://ai_decks")
		return 0
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	if file == null:
		push_error("selfplay: no se puede escribir " + out_path)
		return 0
	var written := 0
	for g in games:
		# Mitad mazos de la comunidad, mitad mazos aleatorios del pool union.
		var decks: Array[Dictionary] = [
			pool[rng.randi_range(0, pool.size() - 1)] if rng.randf() < 0.5 else random_deck(),
			pool[rng.randi_range(0, pool.size() - 1)] if rng.randf() < 0.5 else random_deck(),
		]
		var record := play(decks, g & 1, seed + g, cap)
		if record.is_empty():
			continue
		record["deck_names"] = [str(decks[0].get("_name", "random")), str(decks[1].get("_name", "random"))]
		file.store_line(JSON.stringify(record))
		written += 1
		if written % 10 == 0:
			print("selfplay: ", written, "/", games)
	file.close()
	return written


## Punto de entrada desde Game._ready (--selfplay=<n>).
static func main() -> int:
	var arg := func(name: String, fallback: String) -> String:
		var v := Paths.cmdline_value(name)
		return v if v != "" else fallback
	var games := maxi(1, String(arg.call("selfplay", "10")).to_int())
	var seed: int = String(arg.call("selfplay-seed", str(int(Time.get_unix_time_from_system())))).to_int()
	var out: String = String(arg.call("selfplay-out", Paths.storage_dir.path_join("selfplay.jsonl")))
	var cap: int = String(arg.call("selfplay-cap", str(DEFAULT_CAP))).to_int()
	var runner: RefCounted = load("res://selfplay/selfplay_runner.gd").new()
	var policy_path: String = String(arg.call("selfplay-policy", ""))
	if policy_path != "":
		runner.set("policy", AIPolicy.load_from(policy_path))
	var done: int = runner.run(games, seed, out, cap)
	print("selfplay: ", done, " partidas en ", out)
	return 0 if done > 0 else 1
