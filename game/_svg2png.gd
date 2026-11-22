extends SceneTree
## Rasteriza un SVG a PNGs: --src=x.svg --out=icon --sizes=144,180,512
func _init() -> void:
	var src := ""
	var out := ""
	var sizes := PackedStringArray(["512"])
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--src="):
			src = arg.substr(6)
		elif arg.begins_with("--out="):
			out = arg.substr(6)
		elif arg.begins_with("--sizes="):
			sizes = arg.substr(8).split(",")
	var svg := FileAccess.get_file_as_string(src)
	for s in sizes:
		var img := Image.new()
		if img.load_svg_from_string(svg, float(s) / 512.0) != OK:
			push_error("svg fallo: " + src)
			quit(1)
		img.save_png("%s-%s.png" % [out, s])
	quit()
