class_name UpgradeDef
extends Resource
## A stand upgrade bought with coins. Data only; files in scenes/diner/data/upgrades.

enum Effect { SEATS, COOK_SPEED, ARRIVAL_SPEED, SNACK_GUARD }

@export var id: String = ""
@export var name_key: String = ""
@export var icon: String = "⬆"
@export var effect: Effect = Effect.SEATS
## Price of level 1 and the factor the price grows by per level.
@export var base_cost: int = 40
@export var cost_growth: float = 1.8
@export var max_level: int = 5
## Effect per level: seats = +N seats, the others = fraction (0.1 = 10 % faster / less snacking).
@export var amount_per_level: float = 1.0
