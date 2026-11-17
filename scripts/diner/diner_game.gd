class_name DinerGame
extends Node
## The rules of Bajie's food stall, without any pictures: guests arrive, wait, Bajie cooks, guests pay,
## happy guests become regulars (bring gifts, unlock recipes), Wukong goes on day trips for ingredients.
## The stand also runs while the game is closed (offline progress).
## A picture layer (2D or 3D) only has to show this state and call the functions below.

## A short line for the screen (already translated), e.g. "Fox spirit is a regular now!".
signal message(text: String)
## Something changed that the screen should redraw (guest came / left, dish done, coins ...).
signal changed

@export_group("Start")
@export var start_coins: int = 25
@export var start_seats: int = 3
@export var start_pantry: Dictionary = {"rice": 6, "peach": 4}

@export_group("Guests")
## Seconds between two arriving guests (random in this range, shortened by the lantern upgrade).
@export var arrival_min_seconds: float = 7.0
@export var arrival_max_seconds: float = 13.0
## Bajie waits this long for the player's choice, then picks a dish himself.
@export var auto_choice_delay: float = 3.0
## Pay factor when the player chose the dish / Bajie chose it.
@export var manual_pay_factor: float = 1.25
@export var auto_pay_factor: float = 1.0
## Extra pay from regulars.
@export var regular_pay_bonus: float = 0.2

@export_group("Bajie")
## Chance that Bajie nibbles from a dish, and how much of the pay is lost then.
@export var snack_chance: float = 0.25
@export var snack_pay_loss: float = 0.3

@export_group("Saving")
@export var save_path: String = "user://diner.cfg"
@export var autosave_seconds: float = 30.0
## Longest time the stand keeps working while the game is closed (seconds) and the step of that simulation.
@export var offline_cap_seconds: float = 43200.0
@export var offline_step_seconds: float = 2.0

## Test helper: runs the game faster (the UI has a button).
var time_scale: float = 1.0

var catalog: DinerCatalog = DinerCatalog.new()

# --- State that is saved -------------------------------------------------------------
var coins: int = 0
var pantry: Dictionary = {}
## guest id -> happy visits so far, guest id -> all visits so far.
var friendship: Dictionary = {}
var visits: Dictionary = {}
var regulars: Array[String] = []
var known_dishes: Array[String] = []
## upgrade id -> level.
var upgrades: Dictionary = {}
var served_total: int = 0
## The running day trip ("" = Wukong is at home) and when it ends (unix time, real clock).
var active_trip: String = ""
var trip_end: float = 0.0

# --- State of the moment (not saved) -----------------------------------------------------
## Waiting guests, front first. Each entry: {guest, patience, waited, dish, manual, cooking}.
var waiting: Array[Dictionary] = []
## The dish on the stove: {} or {dish, left, total, order (a `waiting` entry)}.
var cooking: Dictionary = {}

var _next_entry_id: int = 1
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _arrival_timer: float = 3.0
var _autosave_timer: float = 0.0
var _silent: bool = false


func _ready() -> void:
	_rng.randomize()
	_new_game()
	load_file()


func _process(delta: float) -> void:
	step(delta * time_scale)
	_check_trip()
	_autosave_timer += delta
	if _autosave_timer >= autosave_seconds:
		_autosave_timer = 0.0
		save_file()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_file()


func _new_game() -> void:
	coins = start_coins
	pantry = start_pantry.duplicate()
	friendship.clear()
	visits.clear()
	regulars.clear()
	upgrades.clear()
	served_total = 0
	active_trip = ""
	waiting.clear()
	cooking = {}
	known_dishes.clear()
	for dish_id: String in catalog.dishes.keys():
		if (catalog.dishes[dish_id] as DishDef).unlocked_by_guest == "":
			known_dishes.append(dish_id)


## Throws away the saved game and starts again.
func reset() -> void:
	_new_game()
	save_file()
	changed.emit()


# --- Time -----------------------------------------------------------------------------

## Advances the stand by `delta` seconds.
func step(delta: float) -> void:
	_arrival_timer -= delta
	if _arrival_timer <= 0.0:
		_arrival_timer = _next_arrival_interval()
		_try_arrival()
	_update_waiting(delta)
	_update_cooking(delta)


func _next_arrival_interval() -> float:
	return _rng.randf_range(arrival_min_seconds, arrival_max_seconds) * _arrival_factor()


func _try_arrival() -> void:
	if waiting.size() >= seats():
		return
	var choices: Array[GuestDef] = []
	var total_weight: float = 0.0
	for guest_id: String in catalog.guests.keys():
		var guest: GuestDef = catalog.guests[guest_id] as GuestDef
		if served_total >= guest.appears_after_served:
			choices.append(guest)
			total_weight += guest.weight
	if choices.is_empty():
		return
	var roll: float = _rng.randf() * total_weight
	var picked: GuestDef = choices[choices.size() - 1]
	for guest: GuestDef in choices:
		roll -= guest.weight
		if roll <= 0.0:
			picked = guest
			break
	waiting.append({"id": _next_entry_id, "guest": picked.id, "patience": picked.patience_seconds, "waited": 0.0,
		"dish": "", "manual": false, "cooking": false})
	_next_entry_id += 1
	visits[picked.id] = int(visits.get(picked.id, 0)) + 1
	changed.emit()


## Entries are compared by their own id, never by content.
func _entry_index(entry: Dictionary) -> int:
	for i: int in waiting.size():
		if int(waiting[i]["id"]) == int(entry["id"]):
			return i
	return -1


func _remove_entry(entry: Dictionary) -> void:
	var index: int = _entry_index(entry)
	if index >= 0:
		waiting.remove_at(index)


func _update_waiting(delta: float) -> void:
	var gone: Array[Dictionary] = []
	for entry: Dictionary in waiting:
		if entry["cooking"]:
			continue # being served: the guest does not get impatient now
		entry["waited"] = float(entry["waited"]) + delta
		entry["patience"] = float(entry["patience"]) - delta
		if entry["dish"] == "" and float(entry["waited"]) >= auto_choice_delay:
			var best: String = best_dish_for(str(entry["guest"]))
			if best != "":
				entry["dish"] = best
				entry["manual"] = false
		if float(entry["patience"]) <= 0.0:
			gone.append(entry)
	for entry: Dictionary in gone:
		_remove_entry(entry)
		_say(tr("DINER_EVENT_LEFT") % tr((catalog.guests[str(entry["guest"])] as GuestDef).name_key))
		changed.emit()


func _update_cooking(delta: float) -> void:
	if cooking.is_empty():
		_start_next_dish()
		return
	cooking["left"] = float(cooking["left"]) - delta
	if float(cooking["left"]) <= 0.0:
		_serve(cooking["order"] as Dictionary, str(cooking["dish"]))
		cooking = {}


func _start_next_dish() -> void:
	for entry: Dictionary in waiting:
		if entry["cooking"] or entry["dish"] == "":
			continue
		var dish: DishDef = catalog.dishes[str(entry["dish"])] as DishDef
		if not can_cook(dish.id):
			entry["dish"] = "" # the ingredients are gone meanwhile: choose again
			continue
		for ingredient: String in dish.ingredients.keys():
			pantry[ingredient] = int(pantry.get(ingredient, 0)) - int(dish.ingredients[ingredient])
		entry["cooking"] = true
		var cook_time: float = dish.cook_seconds * _cook_factor()
		cooking = {"dish": dish.id, "left": cook_time, "total": cook_time, "order": entry}
		changed.emit()
		return


func _serve(entry: Dictionary, dish_id: String) -> void:
	var dish: DishDef = catalog.dishes[dish_id] as DishDef
	var guest: GuestDef = catalog.guests[str(entry["guest"])] as GuestDef
	var score: int = taste_score(dish, guest)
	var happiness: float = _happiness(score)
	var pay_factor: float = manual_pay_factor if entry["manual"] else auto_pay_factor
	var pay: float = dish.base_price * (0.3 + 0.9 * happiness) * pay_factor
	if regulars.has(guest.id):
		pay *= 1.0 + regular_pay_bonus
	if _rng.randf() < snack_chance * _snack_factor():
		pay *= 1.0 - snack_pay_loss
		_say(tr("DINER_EVENT_SNACK") % tr(dish.name_key))
	coins += maxi(1, roundi(pay))
	served_total += 1
	_remove_entry(entry)
	if happiness >= 0.6:
		friendship[guest.id] = int(friendship.get(guest.id, 0)) + (2 if happiness >= 1.0 else 1)
		_check_regular(guest)
	if regulars.has(guest.id) and guest.gift_ingredient != "" \
			and int(visits.get(guest.id, 1)) % maxi(1, guest.gift_every_visits) == 0:
		pantry[guest.gift_ingredient] = int(pantry.get(guest.gift_ingredient, 0)) + guest.gift_amount
		var gift: IngredientDef = catalog.ingredients[guest.gift_ingredient] as IngredientDef
		_say(tr("DINER_EVENT_GIFT") % [tr(guest.name_key), guest.gift_amount, tr(gift.name_key)])
	changed.emit()


func _check_regular(guest: GuestDef) -> void:
	if regulars.has(guest.id) or int(friendship.get(guest.id, 0)) < guest.friendship_needed:
		return
	regulars.append(guest.id)
	_say(tr("DINER_EVENT_REGULAR") % tr(guest.name_key))
	for dish_id: String in catalog.dishes.keys():
		var dish: DishDef = catalog.dishes[dish_id] as DishDef
		if dish.unlocked_by_guest == guest.id and not known_dishes.has(dish.id):
			known_dishes.append(dish.id)
			_say(tr("DINER_EVENT_RECIPE") % tr(dish.name_key))


# --- Dishes and taste ------------------------------------------------------------------

## Loved tags minus twice the disliked tags.
func taste_score(dish: DishDef, guest: GuestDef) -> int:
	var score: int = 0
	for tag: String in dish.tags:
		if guest.likes.has(tag):
			score += 1
		if guest.dislikes.has(tag):
			score -= 2
	return score


func _happiness(score: int) -> float:
	if score >= 2:
		return 1.0
	if score == 1:
		return 0.65
	if score == 0:
		return 0.35
	return 0.1


func can_cook(dish_id: String) -> bool:
	if not known_dishes.has(dish_id):
		return false
	var dish: DishDef = catalog.dishes[dish_id] as DishDef
	for ingredient: String in dish.ingredients.keys():
		if int(pantry.get(ingredient, 0)) < int(dish.ingredients[ingredient]):
			return false
	return true


## The best dish Bajie could cook right now for this guest (never one the guest dislikes); "" = none.
func best_dish_for(guest_id: String) -> String:
	var guest: GuestDef = catalog.guests[guest_id] as GuestDef
	var best: String = ""
	var best_value: float = -INF
	for dish_id: String in known_dishes:
		if not can_cook(dish_id):
			continue
		var dish: DishDef = catalog.dishes[dish_id] as DishDef
		var score: int = taste_score(dish, guest)
		if score < 0:
			continue
		var value: float = score * 10.0 + dish.base_price * 0.1
		if value > best_value:
			best_value = value
			best = dish_id
	return best


## The player chooses a dish for a waiting guest (better pay than Bajie's own choice).
func choose_dish(entry: Dictionary, dish_id: String) -> bool:
	if _entry_index(entry) < 0 or entry["cooking"] or not can_cook(dish_id):
		return false
	entry["dish"] = dish_id
	entry["manual"] = true
	changed.emit()
	return true


# --- Market, day trips, upgrades ----------------------------------------------------------

func buy_ingredient(ingredient_id: String, count: int = 1) -> bool:
	var ingredient: IngredientDef = catalog.ingredients.get(ingredient_id) as IngredientDef
	if ingredient == null or coins < ingredient.buy_price * count:
		return false
	coins -= ingredient.buy_price * count
	pantry[ingredient_id] = int(pantry.get(ingredient_id, 0)) + count
	changed.emit()
	return true


func is_trip_available(trip_id: String) -> bool:
	var trip: ExpeditionDef = catalog.expeditions.get(trip_id) as ExpeditionDef
	return trip != null and served_total >= trip.appears_after_served


## Wukong goes out (one trip at a time). Returns false if he is already away.
func start_trip(trip_id: String) -> bool:
	if active_trip != "" or not is_trip_available(trip_id):
		return false
	var trip: ExpeditionDef = catalog.expeditions[trip_id] as ExpeditionDef
	active_trip = trip_id
	trip_end = Time.get_unix_time_from_system() + trip.duration_seconds
	changed.emit()
	return true


func trip_seconds_left() -> float:
	if active_trip == "":
		return 0.0
	return maxf(0.0, trip_end - Time.get_unix_time_from_system())


func _check_trip() -> void:
	if active_trip == "" or Time.get_unix_time_from_system() < trip_end:
		return
	var trip: ExpeditionDef = catalog.expeditions[active_trip] as ExpeditionDef
	for ingredient: String in trip.yields.keys():
		var range_array: Array = trip.yields[ingredient] as Array
		var amount: int = _rng.randi_range(int(range_array[0]), int(range_array[1]))
		pantry[ingredient] = int(pantry.get(ingredient, 0)) + amount
	_say(tr("DINER_EVENT_TRIP_HOME") % tr(trip.name_key))
	active_trip = ""
	changed.emit()


func upgrade_level(upgrade_id: String) -> int:
	return int(upgrades.get(upgrade_id, 0))


## Price of the next level, -1 = already at the maximum.
func upgrade_cost(upgrade_id: String) -> int:
	var upgrade: UpgradeDef = catalog.upgrades[upgrade_id] as UpgradeDef
	var level: int = upgrade_level(upgrade_id)
	if level >= upgrade.max_level:
		return -1
	return roundi(upgrade.base_cost * pow(upgrade.cost_growth, level))


func buy_upgrade(upgrade_id: String) -> bool:
	var cost: int = upgrade_cost(upgrade_id)
	if cost < 0 or coins < cost:
		return false
	coins -= cost
	upgrades[upgrade_id] = upgrade_level(upgrade_id) + 1
	changed.emit()
	return true


func _upgrade_total(effect: UpgradeDef.Effect) -> float:
	var total: float = 0.0
	for upgrade_id: String in catalog.upgrades.keys():
		var upgrade: UpgradeDef = catalog.upgrades[upgrade_id] as UpgradeDef
		if upgrade.effect == effect:
			total += upgrade.amount_per_level * upgrade_level(upgrade_id)
	return total


func seats() -> int:
	return start_seats + roundi(_upgrade_total(UpgradeDef.Effect.SEATS))


func _cook_factor() -> float:
	return maxf(0.3, 1.0 - _upgrade_total(UpgradeDef.Effect.COOK_SPEED))


func _arrival_factor() -> float:
	return maxf(0.35, 1.0 - _upgrade_total(UpgradeDef.Effect.ARRIVAL_SPEED))


func _snack_factor() -> float:
	return maxf(0.0, 1.0 - _upgrade_total(UpgradeDef.Effect.SNACK_GUARD))


func _say(text: String) -> void:
	if not _silent:
		message.emit(text)


# --- Saving and offline progress ----------------------------------------------------------------

func save_file() -> void:
	var config: ConfigFile = ConfigFile.new()
	var saved_pantry: Dictionary = pantry.duplicate()
	if not cooking.is_empty():
		# The dish on the stove is not finished: give the ingredients back.
		var dish: DishDef = catalog.dishes[str(cooking["dish"])] as DishDef
		for ingredient: String in dish.ingredients.keys():
			saved_pantry[ingredient] = int(saved_pantry.get(ingredient, 0)) + int(dish.ingredients[ingredient])
	config.set_value("stand", "coins", coins)
	config.set_value("stand", "pantry", saved_pantry)
	config.set_value("stand", "friendship", friendship)
	config.set_value("stand", "visits", visits)
	config.set_value("stand", "regulars", regulars)
	config.set_value("stand", "known_dishes", known_dishes)
	config.set_value("stand", "upgrades", upgrades)
	config.set_value("stand", "served_total", served_total)
	config.set_value("stand", "active_trip", active_trip)
	config.set_value("stand", "trip_end", trip_end)
	config.set_value("stand", "saved_at", Time.get_unix_time_from_system())
	config.save(save_path)


func load_file() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(save_path) != OK:
		return
	coins = int(config.get_value("stand", "coins", coins))
	pantry = config.get_value("stand", "pantry", pantry) as Dictionary
	friendship = config.get_value("stand", "friendship", friendship) as Dictionary
	visits = config.get_value("stand", "visits", visits) as Dictionary
	regulars.assign(config.get_value("stand", "regulars", regulars) as Array)
	known_dishes.assign(config.get_value("stand", "known_dishes", known_dishes) as Array)
	upgrades = config.get_value("stand", "upgrades", upgrades) as Dictionary
	served_total = int(config.get_value("stand", "served_total", 0))
	active_trip = str(config.get_value("stand", "active_trip", ""))
	trip_end = float(config.get_value("stand", "trip_end", 0.0))
	var away: float = Time.get_unix_time_from_system() - float(config.get_value("stand", "saved_at", 0.0))
	if away > 10.0:
		_simulate_offline(minf(away, offline_cap_seconds))
	_check_trip()
	changed.emit()


## While the game was closed the stand kept running: play that time in coarse steps.
func _simulate_offline(seconds: float) -> void:
	var coins_before: int = coins
	var served_before: int = served_total
	_silent = true
	var elapsed: float = 0.0
	while elapsed < seconds:
		step(offline_step_seconds)
		elapsed += offline_step_seconds
	_silent = false
	waiting.clear()
	cooking = {}
	if served_total > served_before:
		_say(tr("DINER_EVENT_OFFLINE") % [served_total - served_before, coins - coins_before])
