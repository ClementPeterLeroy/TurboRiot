class_name CircuitGallery
extends Control
signal selected(identifier: StringName)
signal launch_requested
signal back_requested
signal cue_requested(event: StringName)
const CARD := preload("res://scenes/ui/circuit_card.tscn")
var definitions: Array[TrackDefinition] = []
var selected_id: StringName
var focusables: Array[Control] = []
var cards: Array[CircuitCard] = []
var _margin := MarginContainer.new()
var _strip := HBoxContainer.new()
var _scroll := ScrollContainer.new()
var _description := Label.new()
var _start := Button.new()
var _back := Button.new()
var _title := Label.new()
var _logo := TextureRect.new()
var _stick := Vector2.ZERO
var _stick_direction := ""
var _repeat := Timer.new()

func configure(entries: Array[TrackDefinition], identifier: StringName) -> void:
	definitions = entries
	selected_id = identifier

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_repeat.one_shot = true
	add_child(_repeat)
	_repeat.timeout.connect(_repeat_stick)
	add_child(_margin)
	_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_margin.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 28)
	column.add_child(header)
	_logo.texture = preload("res://assets/brand/turbo_riot_logo.png")
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.custom_minimum_size = Vector2(180, 76)
	header.add_child(_logo)
	_title.text = "CHOOSE YOUR CIRCUIT"
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.add_theme_color_override("font_color", Color("ffdc56"))
	header.add_child(_title)
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	column.add_child(_scroll)
	_strip.add_theme_constant_override("separation", 16)
	_strip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_scroll.add_child(_strip)
	for definition in definitions:
		if not definition.available or definition.internal_only: continue
		var card := CARD.instantiate() as CircuitCard
		card.definition = definition
		card.chosen = definition.identifier == selected_id
		_strip.add_child(card)
		cards.append(card)
		focusables.append(card)
		card.pressed.connect(func() -> void: _select(card))
		card.focus_entered.connect(func() -> void:
			cue_requested.emit(&"navigate")
			_start.focus_neighbor_top = card.get_path()
			_back.focus_neighbor_top = card.get_path())
	_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.custom_minimum_size.y = 48
	_description.add_theme_color_override("font_color", Color("b7d2e1"))
	column.add_child(_description)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 16)
	column.add_child(footer)
	for button in [_back, _start]:
		button.custom_minimum_size = Vector2(190, 48)
		footer.add_child(button)
		button.focus_entered.connect(func() -> void: cue_requested.emit(&"navigate"))
	_back.text = "Back"
	_start.text = "Start Race"
	_back.pressed.connect(func() -> void:
		cue_requested.emit(&"back")
		back_requested.emit())
	_start.pressed.connect(func() -> void:
		cue_requested.emit(&"confirm")
		launch_requested.emit())
	# Preserve the common menu's control registry; gallery owns its 2D links.
	focusables.append(_start)
	focusables.append(_back)
	var hint := Label.new()
	hint.text = "Arrows / stick: browse    Enter / A: select    Esc / B: back"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color("8aabbe"))
	column.add_child(hint)
	for i in cards.size():
		var card := cards[i]
		card.focus_neighbor_left = cards[posmod(i - 1, cards.size())].get_path()
		card.focus_neighbor_right = cards[(i + 1) % cards.size()].get_path()
		card.focus_neighbor_top = card.get_path()
		card.focus_neighbor_bottom = _start.get_path()
	for i in focusables.size():
		focusables[i].focus_next = focusables[(i + 1) % focusables.size()].get_path()
		focusables[i].focus_previous = focusables[posmod(i - 1, focusables.size())].get_path()
	_start.focus_neighbor_left = _back.get_path()
	_start.focus_neighbor_right = _back.get_path()
	_back.focus_neighbor_left = _start.get_path()
	_back.focus_neighbor_right = _start.get_path()
	_start.focus_neighbor_bottom = _start.get_path()
	_back.focus_neighbor_bottom = _back.get_path()
	_refresh_description()
	resized.connect(_resize)
	_resize()
	_focus_selected.call_deferred()

func _select(card: CircuitCard) -> void:
	selected_id = card.definition.identifier
	for candidate in cards: candidate.chosen = candidate == card
	_refresh_description()
	cue_requested.emit(&"confirm")
	selected.emit(selected_id)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event is InputEventJoypadMotion: return
	if event.axis == JOY_AXIS_LEFT_X: _stick.x = event.axis_value
	elif event.axis == JOY_AXIS_LEFT_Y: _stick.y = event.axis_value
	else: return
	var direction := ""
	if maxf(absf(_stick.x), absf(_stick.y)) > 0.55:
		if absf(_stick.x) >= absf(_stick.y): direction = "left" if _stick.x < 0 else "right"
		else: direction = "top" if _stick.y < 0 else "bottom"
	if direction != _stick_direction:
		_stick_direction = direction
		_repeat.stop()
		if not direction.is_empty():
			_move_stick_focus()
			_repeat.start(0.4)
	get_viewport().set_input_as_handled()

func _repeat_stick() -> void:
	if not is_visible_in_tree() or _stick_direction.is_empty(): return
	_move_stick_focus()
	_repeat.start(0.16)

func _move_stick_focus() -> void:
	var owner := get_viewport().gui_get_focus_owner()
	if owner not in focusables: return
	var path: NodePath = owner.get("focus_neighbor_" + _stick_direction)
	var target := owner.get_node_or_null(path) as Control
	if target: target.grab_focus()

func _refresh_description() -> void:
	for card in cards:
		if card.chosen: _description.text = card.definition.description
	_start.disabled = cards.is_empty()

func _focus_selected() -> void:
	if not is_inside_tree() or not is_visible_in_tree(): return
	for card in cards:
		if card.chosen:
			card.grab_focus()
			_start.focus_neighbor_top = card.get_path()
			_back.focus_neighbor_top = card.get_path()
			return

func _resize() -> void:
	var pad := 16 if size.x < 1000 else 32
	var width := minf(1560, size.x - pad * 2)
	var horizontal := roundi((size.x - width) / 2)
	for side in ["left", "right"]: _margin.add_theme_constant_override("margin_" + side, horizontal)
	for side in ["top", "bottom"]: _margin.add_theme_constant_override("margin_" + side, pad)
	var visible_count := mini(3, maxi(1, cards.size()))
	# Leave a pixel of slack for integer container rounding: three entries do
	# not need a horizontal scrollbar. More entries scroll in the same row.
	var card_width := maxf(200, floorf((width - 16 * (visible_count - 1)) / visible_count) - 1)
	var card_height := clampf(size.y - (255 if size.x < 1000 else 310), 120, 450)
	if cards.size() > visible_count: card_height = maxf(120, card_height - 18)
	for card in cards: card.custom_minimum_size = Vector2(card_width, card_height)
	_title.add_theme_font_size_override("font_size", 24 if size.x < 1000 else 34)
	_logo.custom_minimum_size = Vector2(130, 56) if size.x < 1000 else Vector2(180, 76)
