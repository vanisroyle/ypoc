class_name AIPolicy
## Pesos por carta aprendidos por self-play (tools/selfplay/train.py escribe
## PoC Data/ai_policy.json). El motor los consulta al elegir entre candidatos:
## se mezclan con la heuristica original (f5af600) y un JSON vacio o ausente
## deja el comportamiento intacto.

const PATH_NAME := "ai_policy.json"
## Escala: un peso 1.0 equivale a esta ventaja de ATK/DEF al puntuar candidatos.
const WEIGHT_SCALE := 800.0

var weights: Dictionary = {}
var games := 0


## Carga el JSON; devuelve null si no existe o esta mal formado.
static func load_from(path: String) -> AIPolicy:
	if not FileAccess.file_exists(path):
		return null
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is not Dictionary or data.get("cards", {}) is not Dictionary:
		return null
	var policy := AIPolicy.new()
	for key in data["cards"]:
		policy.weights[str(key)] = clampf(float(data["cards"][key]), -1.0, 1.0)
	policy.games = int(data.get("games", 0))
	return policy


## Valor entrenado de la carta (id interno); 0 si la carta no aparece en el modelo.
func weight(card_id: int) -> float:
	return float(weights.get(str(card_id), 0.0))
