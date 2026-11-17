class_name ExpeditionDef
extends Resource
## A day trip of Wukong that brings ingredients home. Data only; files in scenes/diner/data/expeditions.

@export var id: String = ""
@export var name_key: String = ""
@export var icon: String = "🧭"
## Real seconds the trip takes (it also runs while the game is closed).
@export var duration_seconds: float = 60.0
## Ingredient id -> [min, max] pieces brought home.
@export var yields: Dictionary = {}
## The trip becomes available after this many portions were served in total.
@export var appears_after_served: int = 0
