extends Control
## Plain test screen for the food stall rules (no art yet): shows guests, pantry, market, day trips and
## upgrades, and lets you choose dishes by hand. Start it with F6 (scene diner_debug.tscn).

const REFRESH_SECONDS: float = 0.25
const SPEEDS: Array[int] = [1, 5, 20]

var _game: DinerGame = null
var _refresh_timer: float = 0.0
var _signature: String = ""
var _speed_index: int = 0
var _log_lines: Array[String] = []

var _coins_label: Label = null
var _served_label: Label = null
var _regulars_label: Label = null
var _cook_label: Label = null
var _guest_box: VBoxContainer = null
var _pantry_label: Label = null
var _log_label: Label = null
var _speed_button: Button = null
var _market_buttons: Dictionary = {}
var _trip_buttons: Dictionary = {}
var _upgrade_buttons: Dictionary = {}
## entry id -> label with the guest's remaining patience.
var _patience_labels: Dictionary = {}


func _ready() -> void:
	_game = DinerGame.new()
	_game.name = "DinerGame"
	add_child(_game)
	_game.message.connect(_on_message)
	_build_ui()
	_refresh(true)


func _process(delta: float) -> void:
	_refresh_timer += delta
	if _refresh_timer >= REFRESH_SECONDS:
		_refresh_timer = 0.0
		_refresh(false)


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	margin.add_child(columns)

	# Left: status, guests, log.
	var left: VBoxContainer = _column(columns, 520.0)
	var title: Label = Label.new()
	title.text = tr("DINER_TITLE")
	title.add_theme_font_size_override("font_size", 26)
	left.add_child(title)
	_coins_label = Label.new()
	_served_label = Label.new()
	_regulars_label = Label.new()
	_cook_label = Label.new()
	for label: Label in [_coins_label, _served_label, _regulars_label, _cook_label]:
		left.add_child(label)
	_speed_button = Button.new()
	_speed_button.pressed.connect(_on_speed_pressed)
	left.add_child(_speed_button)
	left.add_child(_header(tr("DINER_QUEUE")))
	_guest_box = VBoxContainer.new()
	left.add_child(_guest_box)
	_log_label = Label.new()
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_header(""))
	left.add_child(_log_label)

	# Middle: pantry and market.
	var middle: VBoxContainer = _column(columns, 300.0)
	middle.add_child(_header(tr("DINER_STOCK")))
	_pantry_label = Label.new()
	middle.add_child(_pantry_label)
	middle.add_child(_header(tr("DINER_MARKET")))
	for ingredient_id: String in _game.catalog.ingredients.keys():
		var button: Button = Button.new()
		button.pressed.connect(_on_buy_pressed.bind(ingredient_id))
		middle.add_child(button)
		_market_buttons[ingredient_id] = button

	# Right: day trips and upgrades.
	var right: VBoxContainer = _column(columns, 360.0)
	right.add_child(_header(tr("DINER_TRIPS")))
	for trip_id: String in _game.catalog.expeditions.keys():
		var button: Button = Button.new()
		button.pressed.connect(_on_trip_pressed.bind(trip_id))
		right.add_child(button)
		_trip_buttons[trip_id] = button
	right.add_child(_header(tr("DINER_UPGRADES")))
	for upgrade_id: String in _game.catalog.upgrades.keys():
		var button: Button = Button.new()
		button.pressed.connect(_on_upgrade_pressed.bind(upgrade_id))
		right.add_child(button)
		_upgrade_buttons[upgrade_id] = button


func _column(parent: Control, width: float) -> VBoxContainer:
	var box: VBoxContainer = VBoxContainer.new()
	box.custom_minimum_size = Vector2(width, 0.0)
	box.add_theme_constant_override("separation", 6)
	parent.add_child(box)
	return box


func _header(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	return label


## Updates texts and button states every call; rebuilds the guest rows only when something changed there.
func _refresh(force: bool) -> void:
	var catalog: DinerCatalog = _game.catalog
	_coins_label.text = tr("DINER_COINS") % _game.coins
	_served_label.text = tr("DINER_SERVED") % _game.served_total
	var regular_names: Array[String] = []
	for guest_id: String in _game.regulars:
		regular_names.append(tr((catalog.guests[guest_id] as GuestDef).name_key))
	_regulars_label.text = tr("DINER_REGULARS") % (", ".join(regular_names) if not regular_names.is_empty() else tr("DINER_NO_REGULARS"))
	if _game.cooking.is_empty():
		_cook_label.text = tr("DINER_IDLE_COOK")
	else:
		var dish: DishDef = catalog.dishes[str(_game.cooking["dish"])] as DishDef
		_cook_label.text = tr("DINER_COOKING") % [dish.icon + " " + tr(dish.name_key), ceili(float(_game.cooking["left"]))]
	_speed_button.text = tr("DINER_FASTER") % SPEEDS[_speed_index]

	var stock_lines: Array[String] = []
	for ingredient_id: String in catalog.ingredients.keys():
		var count: int = int(_game.pantry.get(ingredient_id, 0))
		var ingredient: IngredientDef = catalog.ingredients[ingredient_id] as IngredientDef
		stock_lines.append("%s %s: %d" % [ingredient.icon, tr(ingredient.name_key), count])
		var button: Button = _market_buttons[ingredient_id] as Button
		button.text = tr("DINER_BUY") % [ingredient.icon + " " + tr(ingredient.name_key), ingredient.buy_price]
		button.disabled = _game.coins < ingredient.buy_price
	_pantry_label.text = "\n".join(stock_lines)

	for trip_id: String in catalog.expeditions.keys():
		var trip: ExpeditionDef = catalog.expeditions[trip_id] as ExpeditionDef
		var trip_button: Button = _trip_buttons[trip_id] as Button
		trip_button.visible = _game.is_trip_available(trip_id)
		if _game.active_trip == trip_id:
			trip_button.text = tr("DINER_TRIP_RUNNING") % [trip.icon + " " + tr(trip.name_key), ceili(_game.trip_seconds_left())]
		else:
			trip_button.text = tr("DINER_TRIP_START") % [trip.icon + " " + tr(trip.name_key), int(trip.duration_seconds)]
		trip_button.disabled = _game.active_trip != ""

	for upgrade_id: String in catalog.upgrades.keys():
		var upgrade: UpgradeDef = catalog.upgrades[upgrade_id] as UpgradeDef
		var upgrade_button: Button = _upgrade_buttons[upgrade_id] as Button
		var cost: int = _game.upgrade_cost(upgrade_id)
		var name_text: String = upgrade.icon + " " + tr(upgrade.name_key)
		if cost < 0:
			upgrade_button.text = tr("DINER_UPGRADE_MAX") % name_text
			upgrade_button.disabled = true
		else:
			upgrade_button.text = tr("DINER_UPGRADE_BUY") % [name_text, _game.upgrade_level(upgrade_id) + 1, upgrade.max_level, cost]
			upgrade_button.disabled = _game.coins < cost

	var signature: String = _make_signature()
	if force or signature != _signature:
		_signature = signature
		_rebuild_guests()
	for entry: Dictionary in _game.waiting:
		var label: Label = _patience_labels.get(int(entry["id"])) as Label
		if label != null:
			label.text = "⏳ %d s" % ceili(float(entry["patience"]))


func _make_signature() -> String:
	var parts: Array[String] = []
	for entry: Dictionary in _game.waiting:
		parts.append("%d:%s:%s" % [int(entry["id"]), str(entry["dish"]), str(entry["cooking"])])
	for dish_id: String in _game.known_dishes:
		parts.append(dish_id + (":y" if _game.can_cook(dish_id) else ":n"))
	return "|".join(parts)


func _rebuild_guests() -> void:
	for child: Node in _guest_box.get_children():
		_guest_box.remove_child(child)
		child.queue_free()
	_patience_labels.clear()
	if _game.waiting.is_empty():
		var nobody: Label = Label.new()
		nobody.text = tr("DINER_NOBODY")
		_guest_box.add_child(nobody)
		return
	for entry: Dictionary in _game.waiting:
		var guest: GuestDef = _game.catalog.guests[str(entry["guest"])] as GuestDef
		var row: VBoxContainer = VBoxContainer.new()
		var head: HBoxContainer = HBoxContainer.new()
		row.add_child(head)
		var name_label: Label = Label.new()
		name_label.text = "%s %s   👍 %s   👎 %s" % [guest.icon, tr(guest.name_key), _tag_text(guest.likes), _tag_text(guest.dislikes)]
		head.add_child(name_label)
		var patience_label: Label = Label.new()
		head.add_child(patience_label)
		_patience_labels[int(entry["id"])] = patience_label
		if str(entry["dish"]) != "":
			var chosen: DishDef = _game.catalog.dishes[str(entry["dish"])] as DishDef
			var chosen_label: Label = Label.new()
			chosen_label.text = "→ %s %s" % [chosen.icon, tr(chosen.name_key)]
			row.add_child(chosen_label)
		if not entry["cooking"]:
			var buttons: HBoxContainer = HBoxContainer.new()
			row.add_child(buttons)
			for dish_id: String in _game.known_dishes:
				if not _game.can_cook(dish_id):
					continue
				var dish: DishDef = _game.catalog.dishes[dish_id] as DishDef
				var button: Button = Button.new()
				button.text = dish.icon + " " + tr(dish.name_key)
				button.pressed.connect(_on_dish_pressed.bind(entry, dish_id))
				buttons.add_child(button)
		_guest_box.add_child(row)


func _tag_text(tags: PackedStringArray) -> String:
	var names: Array[String] = []
	for tag: String in tags:
		names.append(tr("TAG_" + tag.to_upper()))
	return ", ".join(names)


func _on_dish_pressed(entry: Dictionary, dish_id: String) -> void:
	_game.choose_dish(entry, dish_id)


func _on_buy_pressed(ingredient_id: String) -> void:
	_game.buy_ingredient(ingredient_id)


func _on_trip_pressed(trip_id: String) -> void:
	_game.start_trip(trip_id)


func _on_upgrade_pressed(upgrade_id: String) -> void:
	_game.buy_upgrade(upgrade_id)


func _on_speed_pressed() -> void:
	_speed_index = (_speed_index + 1) % SPEEDS.size()
	_game.time_scale = float(SPEEDS[_speed_index])


func _on_message(text: String) -> void:
	_log_lines.append(text)
	while _log_lines.size() > 6:
		_log_lines.remove_at(0)
	_log_label.text = "\n".join(_log_lines)
