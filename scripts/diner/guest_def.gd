class_name GuestDef
extends Resource
## One kind of guest (villager, hungry ghost, fox spirit ...). Data only; files in scenes/diner/data/guests.

@export var id: String = ""
@export var name_key: String = ""
@export var icon: String = "🙂"
## Flavor tags this guest loves / cannot stand.
@export var likes: PackedStringArray = PackedStringArray()
@export var dislikes: PackedStringArray = PackedStringArray()
## Seconds the guest waits for food before leaving.
@export var patience_seconds: float = 40.0
## Happy visits needed to become a regular.
@export var friendship_needed: int = 5
## The guest first shows up after this many portions were served in total.
@export var appears_after_served: int = 0
## Gift of a regular: ingredient id and amount, brought now and then (every `gift_every_visits` visits).
@export var gift_ingredient: String = ""
@export var gift_amount: int = 2
@export var gift_every_visits: int = 4
## How often this guest comes compared to others (relative weight).
@export var weight: float = 1.0
