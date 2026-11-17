class_name IngredientDef
extends Resource
## One ingredient (peach, rice, tofu ...). Data only; the files live in scenes/diner/data/ingredients.

@export var id: String = ""
@export var name_key: String = ""
## Placeholder picture (an emoji) until real art exists.
@export var icon: String = "🍑"
## Price at the market (coins per piece).
@export var buy_price: int = 3
