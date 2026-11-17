class_name DinerCatalog
extends RefCounted
## Loads all data files of the food stall (ingredients, dishes, guests, day trips, upgrades) once.
## Each table maps the id (String) to its Resource.

const ROOT: String = "res://scenes/diner/data/"

var ingredients: Dictionary = {}
var dishes: Dictionary = {}
var guests: Dictionary = {}
var expeditions: Dictionary = {}
var upgrades: Dictionary = {}


func _init() -> void:
	_load_folder("ingredients", ingredients)
	_load_folder("dishes", dishes)
	_load_folder("guests", guests)
	_load_folder("expeditions", expeditions)
	_load_folder("upgrades", upgrades)


func _load_folder(folder: String, into: Dictionary) -> void:
	var dir: DirAccess = DirAccess.open(ROOT + folder)
	if dir == null:
		push_error("DinerCatalog: folder not found: " + ROOT + folder)
		return
	var file_names: Array[String] = []
	for file_name: String in dir.get_files():
		# An exported game lists "name.tres.remap" instead of "name.tres".
		file_names.append(file_name.trim_suffix(".remap"))
	file_names.sort()
	for file_name: String in file_names:
		if not file_name.ends_with(".tres"):
			continue
		var resource: Resource = load(ROOT + folder + "/" + file_name)
		if resource != null:
			into[str(resource.get("id"))] = resource
