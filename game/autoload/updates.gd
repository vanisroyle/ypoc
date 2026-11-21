extends Node
## Actualizador: descarga y aplica el ejecutable publicado (core/updates_desktop.gd).
signal changed

const REPOSITORY := "https://github.com/Johanfer12/Yu-Gi-Oh-Power-of-Chaos-Remake"
const _FORWARDED := [&"current", &"available", &"release_notes", &"state", &"detail", &"_http"]

var impl: Node = load("res://core/updates_desktop.gd").new()


func _ready() -> void:
	impl.name = "Implementation"
	impl.changed.connect(changed.emit)
	add_child(impl)


func _get(property: StringName) -> Variant:
	return impl.get(property) if property in _FORWARDED else null


func supported() -> bool:
	return impl.supported()


func check_once() -> void:
	impl.check_once()


func check() -> void:
	impl.check()


func download() -> void:
	impl.download()


func cancel() -> void:
	impl.cancel()


## Fracción descargada (0..1) o -1 si la plataforma o el servidor no la informan.
func progress() -> float:
	return impl.progress() if impl.has_method("progress") else -1.0
