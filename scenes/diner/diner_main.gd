extends Control
## The food stall screen (2D): Bajie cooks at his stand on the left, guests wait on stools on the right,
## below are the pantry and three tabs (market, Wukong's day trips, upgrades).
##
## All pictures are placeholders (emoji + colored panels). To use real art just drop PNG files with these names:
##   assets/art/background.png, assets/art/bajie.png, assets/art/wukong.png (not used yet),
##   assets/art/guests/<guest id>.png (e.g. villager.png, hungry_ghost.png), assets/art/dishes/<dish id>.png.
## The screen only shows the state of DinerGame and calls its functions; the rules live there.

const ART_ROOT: String = "res://assets/art/"
const SPEEDS: Array[int] = [1, 5, 20]
const REFRESH_SECONDS: float = 0.15
const TOAST_SECONDS: float = 4.0
const BAJIE_ICON: String = "🐷"
const CARD_SIZE: Vector2 = Vector2(168.0, 262.0)

const COLOR_SKY: Color = Color(0.98, 0.78, 0.55)
const COLOR_GROUND: Color = Color(0.42, 0.28, 0.2)
const COLOR_PANEL: Color = Color(0.1, 0.07, 0.06, 0.82)
const COLOR_CARD: Color = Color(1.0, 0.95, 0.84)
const COLOR_TEXT_DARK: Color = Color(0.2, 0.13, 0.1)
const COLOR_GOLD: Color = Color(1.0, 0.85, 0.45)

var _game: DinerGame = null
var _refresh_timer: float = 0.0
var _time: float = 0.0
var _signature: String = ""
var _speed_index: int = 0
var _last_coins: int = 0
## Entry ids we already showed (a new guest pops in, the others stay).
var _seen_ids: Dictionary = {}

var _coins_label: Label = null
var _served_label: Label = null
var _regulars_label: Label = null
var _speed_button: Button = null
var _bajie_holder: Control = null
var _steam_label: Label = null
var _cook_label: Label = null
var _cook_bar: ProgressBar = null
var _seat_row: HBoxContainer = null
var _pantry_row: HBoxContainer = null
var _toast_box: VBoxContainer = null
var _pantry_labels: Dictionary = {}
var _market_buttons: Dictionary = {}
var _trip_widgets: Dictionary = {}
var _upgrade_buttons: Dictionary = {}
## entry id -> the patience bar of that guest's card.
var _patience_bars: Dictionary = {}


func _ready() -> void:
	_game = DinerGame.new()
	_game.name = "DinerGame"
	add_child(_game)
	_game.message.connect(_show_toast)
	_build_ui()
	_last_coins = _game.coins
	_refresh(true)


func _process(delta: float) -> void:
	_time += delta
	_refresh_timer += delta
	if _refresh_timer >= REFRESH_SECONDS:
		_refresh_timer = 0.0
		_refresh(false)
	_animate_bajie(delta)


# --- Building the screen -----------------------------------------------------------------

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_background()
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	column.add_child(_build_top_bar())

	var stage: HBoxContainer = HBoxContainer.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_theme_constant_override("separation", 14)
	column.add_child(stage)
	stage.add_child(_build_stand())
	_seat_row = HBoxContainer.new()
	_seat_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_seat_row.alignment = BoxContainer.ALIGNMENT_END
	_seat_row.add_theme_constant_override("separation", 10)
	stage.add_child(_seat_row)

	column.add_child(_build_bottom_panel())

	# Messages float at the top center, above everything.
	_toast_box = VBoxContainer.new()
	_toast_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast_box.offset_left = -220.0
	_toast_box.offset_right = 220.0
	_toast_box.offset_top = 64.0
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast_box)


func _build_background() -> void:
	var art_path: String = ART_ROOT + "background.png"
	if ResourceLoader.exists(art_path):
		var picture: TextureRect = TextureRect.new()
		picture.texture = load(art_path) as Texture2D
		picture.set_anchors_preset(Control.PRESET_FULL_RECT)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(picture)
		return
	var sky: ColorRect = ColorRect.new()
	sky.color = COLOR_SKY
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sky)
	var ground: ColorRect = ColorRect.new()
	ground.color = COLOR_GROUND
	ground.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	ground.anchor_top = 0.62
	ground.offset_top = 0.0
	add_child(ground)


func _build_top_bar() -> Control:
	var bar: PanelContainer = PanelContainer.new()
	bar.add_theme_stylebox_override("panel", _style(COLOR_PANEL, 10))
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	bar.add_child(row)
	var title: Label = Label.new()
	title.text = tr("DINER_TITLE")
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLOR_GOLD)
	row.add_child(title)
	_coins_label = Label.new()
	_coins_label.add_theme_font_size_override("font_size", 22)
	row.add_child(_coins_label)
	_served_label = Label.new()
	row.add_child(_served_label)
	_regulars_label = Label.new()
	_regulars_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_regulars_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(_regulars_label)
	_speed_button = Button.new()
	_speed_button.pressed.connect(_on_speed_pressed)
	row.add_child(_speed_button)
	return bar


func _build_stand() -> Control:
	var stand: PanelContainer = PanelContainer.new()
	stand.custom_minimum_size = Vector2(300.0, 0.0)
	stand.add_theme_stylebox_override("panel", _style(Color(0.35, 0.2, 0.12, 0.92), 14))
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	stand.add_child(box)
	var name_label: Label = Label.new()
	name_label.text = tr("DINER_BAJIE")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", COLOR_GOLD)
	box.add_child(name_label)
	_bajie_holder = Control.new()
	_bajie_holder.custom_minimum_size = Vector2(200.0, 190.0)
	_bajie_holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_bajie_holder)
	var art: Control = _make_art("", "bajie", 150)
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bajie_holder.add_child(art)
	_steam_label = Label.new()
	_steam_label.text = "♨ ♨ ♨"
	_steam_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_steam_label.add_theme_font_size_override("font_size", 22)
	box.add_child(_steam_label)
	_cook_label = Label.new()
	_cook_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cook_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_cook_label)
	_cook_bar = ProgressBar.new()
	_cook_bar.max_value = 1.0
	_cook_bar.show_percentage = false
	_cook_bar.custom_minimum_size = Vector2(0.0, 16.0)
	box.add_child(_cook_bar)
	var hint: Label = Label.new()
	hint.text = tr("DINER_HINT_SERVE")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 13)
	hint.modulate = Color(1.0, 1.0, 1.0, 0.7)
	box.add_child(hint)
	return stand


func _build_bottom_panel() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0.0, 236.0)
	panel.add_theme_stylebox_override("panel", _style(COLOR_PANEL, 12))
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var stock_title: HBoxContainer = HBoxContainer.new()
	stock_title.add_theme_constant_override("separation", 18)
	var stock_label: Label = Label.new()
	stock_label.text = tr("DINER_STOCK")
	stock_label.add_theme_color_override("font_color", COLOR_GOLD)
	stock_title.add_child(stock_label)
	_pantry_row = HBoxContainer.new()
	_pantry_row.add_theme_constant_override("separation", 16)
	stock_title.add_child(_pantry_row)
	box.add_child(stock_title)
	for ingredient_id: String in _game.catalog.ingredients.keys():
		var ingredient: IngredientDef = _game.catalog.ingredients[ingredient_id] as IngredientDef
		var label: Label = Label.new()
		label.tooltip_text = tr(ingredient.name_key)
		_pantry_row.add_child(label)
		_pantry_labels[ingredient_id] = label

	var tabs: TabContainer = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(tabs)
	tabs.add_child(_build_market_tab())
	tabs.add_child(_build_trips_tab())
	tabs.add_child(_build_upgrades_tab())
	tabs.set_tab_title(0, tr("DINER_MARKET"))
	tabs.set_tab_title(1, tr("DINER_TRIPS"))
	tabs.set_tab_title(2, tr("DINER_UPGRADES"))
	return panel


func _build_market_tab() -> Control:
	var grid: GridContainer = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for ingredient_id: String in _game.catalog.ingredients.keys():
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(250.0, 44.0)
		button.pressed.connect(_on_buy_pressed.bind(ingredient_id))
		grid.add_child(button)
		_market_buttons[ingredient_id] = button
	return grid


func _build_trips_tab() -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	for trip_id: String in _game.catalog.expeditions.keys():
		var trip: ExpeditionDef = _game.catalog.expeditions[trip_id] as ExpeditionDef
		var card: PanelContainer = PanelContainer.new()
		card.custom_minimum_size = Vector2(220.0, 0.0)
		card.add_theme_stylebox_override("panel", _style(Color(0.2, 0.14, 0.11, 0.95), 8))
		var box: VBoxContainer = VBoxContainer.new()
		card.add_child(box)
		var title: Label = Label.new()
		title.text = trip.icon + " " + tr(trip.name_key)
		title.add_theme_color_override("font_color", COLOR_GOLD)
		box.add_child(title)
		var yields: Array[String] = []
		for ingredient_id: String in trip.yields.keys():
			yields.append((_game.catalog.ingredients[ingredient_id] as IngredientDef).icon)
		var brings: Label = Label.new()
		brings.text = tr("DINER_TRIP_BRINGS") + " " + " ".join(yields)
		box.add_child(brings)
		var bar: ProgressBar = ProgressBar.new()
		bar.max_value = trip.duration_seconds
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0.0, 12.0)
		box.add_child(bar)
		var button: Button = Button.new()
		button.pressed.connect(_on_trip_pressed.bind(trip_id))
		box.add_child(button)
		row.add_child(card)
		_trip_widgets[trip_id] = {"card": card, "bar": bar, "button": button}
	return row


func _build_upgrades_tab() -> Control:
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for upgrade_id: String in _game.catalog.upgrades.keys():
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(380.0, 44.0)
		button.pressed.connect(_on_upgrade_pressed.bind(upgrade_id))
		grid.add_child(button)
		_upgrade_buttons[upgrade_id] = button
	return grid


# --- Small helpers -------------------------------------------------------------------------

func _style(color: Color, radius: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.content_margin_left = 12.0
	box.content_margin_right = 12.0
	box.content_margin_top = 10.0
	box.content_margin_bottom = 10.0
	return box


## A picture for `id`: assets/art/<folder>/<id>.png if the file exists, otherwise the emoji placeholder.
func _make_art(folder: String, id: String, size: int) -> Control:
	var path: String = ART_ROOT + (folder + "/" if folder != "" else "") + id + ".png"
	if ResourceLoader.exists(path):
		var picture: TextureRect = TextureRect.new()
		picture.texture = load(path) as Texture2D
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.custom_minimum_size = Vector2(size, size)
		return picture
	var label: Label = Label.new()
	label.text = BAJIE_ICON if id == "bajie" else _icon_of(folder, id)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", int(size * 0.7))
	label.custom_minimum_size = Vector2(size, size)
	return label


func _icon_of(folder: String, id: String) -> String:
	if folder == "guests" and _game.catalog.guests.has(id):
		return (_game.catalog.guests[id] as GuestDef).icon
	if folder == "dishes" and _game.catalog.dishes.has(id):
		return (_game.catalog.dishes[id] as DishDef).icon
	return "❔"


func _tag_text(tags: PackedStringArray) -> String:
	var names: Array[String] = []
	for tag: String in tags:
		names.append(tr("TAG_" + tag.to_upper()))
	return ", ".join(names)


# --- Refreshing ----------------------------------------------------------------------------------

func _refresh(force: bool) -> void:
	var catalog: DinerCatalog = _game.catalog
	_coins_label.text = tr("DINER_COINS") % _game.coins
	_served_label.text = tr("DINER_SERVED") % _game.served_total
	var regular_names: Array[String] = []
	for guest_id: String in _game.regulars:
		regular_names.append(tr((catalog.guests[guest_id] as GuestDef).name_key))
	_regulars_label.text = tr("DINER_REGULARS") % (", ".join(regular_names) if not regular_names.is_empty() else tr("DINER_NO_REGULARS"))
	_speed_button.text = tr("DINER_FASTER") % SPEEDS[_speed_index]

	# Coins went up: a guest paid.
	if _game.coins > _last_coins:
		_float_text("+%d" % (_game.coins - _last_coins), _coins_label.global_position + Vector2(20.0, 30.0))
	_last_coins = _game.coins

	# The stove.
	if _game.cooking.is_empty():
		_cook_label.text = tr("DINER_IDLE_COOK")
		_cook_bar.value = 0.0
		_steam_label.visible = false
	else:
		var dish: DishDef = catalog.dishes[str(_game.cooking["dish"])] as DishDef
		_cook_label.text = dish.icon + " " + tr(dish.name_key)
		_cook_bar.value = 1.0 - float(_game.cooking["left"]) / maxf(float(_game.cooking["total"]), 0.01)
		_steam_label.visible = true

	for ingredient_id: String in catalog.ingredients.keys():
		var ingredient: IngredientDef = catalog.ingredients[ingredient_id] as IngredientDef
		(_pantry_labels[ingredient_id] as Label).text = "%s %d" % [ingredient.icon, int(_game.pantry.get(ingredient_id, 0))]
		var buy_button: Button = _market_buttons[ingredient_id] as Button
		buy_button.text = tr("DINER_BUY") % [ingredient.icon + " " + tr(ingredient.name_key), ingredient.buy_price]
		buy_button.disabled = _game.coins < ingredient.buy_price

	for trip_id: String in catalog.expeditions.keys():
		var trip: ExpeditionDef = catalog.expeditions[trip_id] as ExpeditionDef
		var widgets: Dictionary = _trip_widgets[trip_id]
		(widgets["card"] as Control).visible = _game.is_trip_available(trip_id)
		var trip_button: Button = widgets["button"] as Button
		var trip_bar: ProgressBar = widgets["bar"] as ProgressBar
		if _game.active_trip == trip_id:
			trip_button.text = tr("DINER_TRIP_RUNNING") % [tr(trip.name_key), ceili(_game.trip_seconds_left())]
			trip_bar.value = trip.duration_seconds - _game.trip_seconds_left()
		else:
			trip_button.text = tr("DINER_TRIP_START") % [tr(trip.name_key), int(trip.duration_seconds)]
			trip_bar.value = 0.0
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
		_rebuild_seats()
	for entry: Dictionary in _game.waiting:
		var bar: ProgressBar = _patience_bars.get(int(entry["id"])) as ProgressBar
		if bar != null:
			bar.value = float(entry["patience"])
			var ratio: float = bar.value / maxf(bar.max_value, 0.01)
			bar.modulate = Color(0.55, 0.85, 0.45) if ratio > 0.5 else (Color(0.95, 0.75, 0.3) if ratio > 0.25 else Color(0.9, 0.35, 0.3))


func _make_signature() -> String:
	var parts: Array[String] = ["seats%d" % _game.seats(), "regulars%d" % _game.regulars.size()]
	for entry: Dictionary in _game.waiting:
		parts.append("%d:%s:%s" % [int(entry["id"]), str(entry["dish"]), str(entry["cooking"])])
	for dish_id: String in _game.known_dishes:
		parts.append(dish_id + (":y" if _game.can_cook(dish_id) else ":n"))
	return "|".join(parts)


func _rebuild_seats() -> void:
	for child: Node in _seat_row.get_children():
		_seat_row.remove_child(child)
		child.queue_free()
	_patience_bars.clear()
	var current_ids: Dictionary = {}
	for i: int in _game.seats():
		if i < _game.waiting.size():
			var entry: Dictionary = _game.waiting[i]
			current_ids[int(entry["id"])] = true
			var card: Control = _make_guest_card(entry)
			_seat_row.add_child(card)
			if not _seen_ids.has(int(entry["id"])):
				_pop_in(card)
		else:
			_seat_row.add_child(_make_free_seat())
	_seen_ids = current_ids


func _make_free_seat() -> Control:
	var seat: PanelContainer = PanelContainer.new()
	seat.custom_minimum_size = CARD_SIZE
	seat.tooltip_text = tr("DINER_TIP_FREE_SEAT")
	seat.add_theme_stylebox_override("panel", _style(Color(0.0, 0.0, 0.0, 0.18), 14))
	var stool: Label = Label.new()
	stool.text = "🪑"
	stool.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stool.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stool.add_theme_font_size_override("font_size", 40)
	stool.modulate = Color(1.0, 1.0, 1.0, 0.35)
	seat.add_child(stool)
	return seat


func _make_guest_card(entry: Dictionary) -> Control:
	var guest: GuestDef = _game.catalog.guests[str(entry["guest"])] as GuestDef
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE
	card.add_theme_stylebox_override("panel", _style(COLOR_CARD, 14))
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)

	var picture: Control = _make_art("guests", guest.id, 84)
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(picture)
	var name_label: Label = Label.new()
	name_label.text = ("⭐ " if _game.regulars.has(guest.id) else "") + tr(guest.name_key)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	name_label.add_theme_font_size_override("font_size", 17)
	box.add_child(name_label)
	var likes: Label = Label.new()
	likes.text = "👍 %s\n👎 %s" % [_tag_text(guest.likes), _tag_text(guest.dislikes)]
	likes.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	likes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	likes.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	likes.add_theme_font_size_override("font_size", 12)
	box.add_child(likes)

	var patience: ProgressBar = ProgressBar.new()
	patience.max_value = guest.patience_seconds
	patience.value = float(entry["patience"])
	patience.show_percentage = false
	patience.custom_minimum_size = Vector2(0.0, 10.0)
	box.add_child(patience)
	_patience_bars[int(entry["id"])] = patience

	var state: Label = Label.new()
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	state.add_theme_font_size_override("font_size", 14)
	if str(entry["dish"]) != "":
		var chosen: DishDef = _game.catalog.dishes[str(entry["dish"])] as DishDef
		state.text = ("🍳 " if entry["cooking"] else "→ ") + chosen.icon + " " + tr(chosen.name_key)
		state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(state)

	if not entry["cooking"]:
		var dishes: HFlowContainer = HFlowContainer.new()
		dishes.alignment = FlowContainer.ALIGNMENT_CENTER
		dishes.add_theme_constant_override("h_separation", 4)
		dishes.add_theme_constant_override("v_separation", 4)
		box.add_child(dishes)
		for dish_id: String in _game.known_dishes:
			if not _game.can_cook(dish_id):
				continue
			var dish: DishDef = _game.catalog.dishes[dish_id] as DishDef
			var score: int = _game.taste_score(dish, guest)
			var button: Button = Button.new()
			button.text = dish.icon
			button.tooltip_text = tr(dish.name_key) + " – " + _tag_text(dish.tags)
			button.custom_minimum_size = Vector2(38.0, 34.0)
			if score >= 2:
				button.modulate = Color(0.6, 1.0, 0.6)
			elif score == 1:
				button.modulate = Color(0.85, 1.0, 0.6)
			elif score < 0:
				button.modulate = Color(1.0, 0.55, 0.5)
			button.pressed.connect(_on_dish_pressed.bind(entry, dish_id))
			dishes.add_child(button)
	return card


# --- Little animations --------------------------------------------------------------------------

## A new guest hops onto its stool.
func _pop_in(card: Control) -> void:
	card.pivot_offset = CARD_SIZE * 0.5
	card.scale = Vector2(0.6, 0.6)
	card.modulate.a = 0.0
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(card, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "modulate:a", 1.0, 0.25)


## Bajie sways while cooking and the steam bobs.
func _animate_bajie(delta: float) -> void:
	_bajie_holder.pivot_offset = _bajie_holder.size * 0.5
	var cooking: bool = not _game.cooking.is_empty()
	var target: float = sin(_time * 9.0) * 0.07 if cooking else 0.0
	_bajie_holder.rotation = lerpf(_bajie_holder.rotation, target, clampf(delta * 10.0, 0.0, 1.0))
	if cooking:
		_steam_label.modulate.a = 0.55 + 0.4 * sin(_time * 4.0)


func _float_text(text: String, from: Vector2) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", COLOR_GOLD)
	label.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.05))
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	label.global_position = from
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 50.0, 1.1)
	tween.tween_property(label, "modulate:a", 0.0, 1.1).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)


func _show_toast(text: String) -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color(0.1, 0.07, 0.06, 0.92), 10))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(label)
	_toast_box.add_child(panel)
	var tween: Tween = create_tween()
	tween.tween_interval(TOAST_SECONDS)
	tween.tween_property(panel, "modulate:a", 0.0, 0.6)
	tween.tween_callback(panel.queue_free)


# --- Buttons ---------------------------------------------------------------------------------------

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
