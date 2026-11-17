class_name DishDef
extends Resource
## One dish Bajie can cook. Data only; the files live in scenes/diner/data/dishes.

@export var id: String = ""
@export var name_key: String = ""
@export var icon: String = "🍲"
## Ingredient id -> how many pieces one portion needs.
@export var ingredients: Dictionary = {}
## Flavor tags (sweet, savory, hot, cold, spicy, hearty, light, soft, crunchy). Guests like or dislike tags.
@export var tags: PackedStringArray = PackedStringArray()
## Coins a perfectly happy guest pays.
@export var base_price: int = 8
## Seconds Bajie needs to cook one portion.
@export var cook_seconds: float = 8.0
## Id of the guest whose friendship unlocks this recipe ("" = known from the start).
@export var unlocked_by_guest: String = ""
