extends SceneTree
## Trocea "PoC Data/resources" en .pck de ~20 MB para la version web.
## Cada pieza cabe en el limite de 25 MB de Cloudflare Pages, sin R2.
## Uso: godot --headless --path game --script res://_mkpacks.gd -- --src=<dir> --out=<dir>

const MAX_PART := 20 * 1024 * 1024
const PACK_ROOT := "res://webdata/"


func _init() -> void:
	var src := ""
	var out := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--src="):
			src = arg.trim_prefix("--src=")
		elif arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	assert(src != "" and out != "", "faltan --src/--out")
	DirAccess.make_dir_recursive_absolute(out)

	var entries := []
	_walk(src, "", entries)
	var manifest := {"version": int(Time.get_unix_time_from_system()), "packs": []}
	var part := 0
	var size := 0
	var current := "pack-%02d.pck" % part
	var packer := PCKPacker.new()
	packer.pck_start(out.path_join(current))
	for e in entries:
		if size + e[2] > MAX_PART and size > 0:
			packer.flush(true)
			manifest["packs"].append({"name": current, "bytes": _file_size(out.path_join(current))})
			part += 1
			size = 0
			packer = PCKPacker.new()
			current = "pack-%02d.pck" % part
			packer.pck_start(out.path_join(current))
		packer.add_file(PACK_ROOT + e[1], e[0])
		size += e[2]
	packer.flush(true)
	manifest["packs"].append({"name": current, "bytes": _file_size(out.path_join(current))})

	var f := FileAccess.open(out.path_join("packs.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest))
	f.close()
	print("packs: ", manifest["packs"].size(), " ficheros: ", entries.size())
	quit()


func _file_size(path: String) -> int:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return 0
	var n := f.get_length()
	f.close()
	return n


func _walk(dir_path: String, rel: String, entries: Array) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		var full := dir_path.path_join(name)
		var sub := name if rel == "" else rel + "/" + name
		if d.current_is_dir():
			_walk(full, sub, entries)
		elif name.ends_with(".import"):
			# Remap del editor; en los packs viaja el fichero en bruto.
			pass
		else:
			var f := FileAccess.open(full, FileAccess.READ)
			if f:
				entries.append([full, sub, f.get_length()])
				f.close()
		name = d.get_next()
