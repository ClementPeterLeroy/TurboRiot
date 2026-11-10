class_name AlphaMenu
extends Control
signal cue_requested(event: StringName)
var body := VBoxContainer.new()
var heading := Label.new()
var subtitle := Label.new()
var message := Label.new()
var focusables: Array[Control] = []
var _column := VBoxContainer.new()
var _background := ColorRect.new()
var _scroll := ScrollContainer.new()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = Theme.new()
	theme.default_font_size = 20
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("152b40") if state != "hover" else Color("254863")
		style.border_color = Color("ffd84d") if state == "focus" else Color("4dbbda")
		style.set_border_width_all(3 if state == "focus" else 1)
		style.set_corner_radius_all(6)
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 9
		style.content_margin_bottom = 9
		theme.set_stylebox(state, "Button", style)
		theme.set_stylebox(state, "OptionButton", style)
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 24)
	var horizontal := HBoxContainer.new()
	margin.add_child(horizontal)
	for index in 3:
		if index == 1:
			horizontal.add_child(_column)
		else:
			var spacer := Control.new()
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			horizontal.add_child(spacer)
	_column.add_theme_constant_override("separation", 12)
	heading.add_theme_font_size_override("font_size", 36)
	heading.modulate = Color("ffdc56")
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_column.add_child(heading)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.modulate = Color("95ddef")
	_column.add_child(subtitle)
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.follow_focus = true
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_column.add_child(_scroll)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	_scroll.add_child(body)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.modulate = Color("b7c8d8")
	_column.add_child(message)
	resized.connect(_resize)
	_resize()

func _resize() -> void:
	_column.custom_minimum_size.x = minf(640, maxf(260, size.x - 48))

func page(title: String, detail: String, overlay := false) -> void:
	visible = true
	heading.text = title
	subtitle.text = detail
	message.text = "Arrow keys / D-pad: navigate   Enter / A: confirm   Esc / B: back"
	_background.color = Color(0.025, 0.055, 0.09, 0.82 if overlay else 1.0)
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	focusables.clear()
	_scroll.scroll_vertical = 0

func text(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(label)
	return label

func focusable(control: Control) -> void:
	control.focus_mode = Control.FOCUS_ALL
	control.custom_minimum_size.y = 44
	focusables.append(control)
	control.focus_entered.connect(func() -> void: cue_requested.emit(&"navigate"))

func button(title: String, callback: Callable, back := false) -> Button:
	var control := Button.new()
	control.text = title
	body.add_child(control)
	focusable(control)
	control.pressed.connect(func() -> void:
		cue_requested.emit(&"back" if back else &"confirm")
		callback.call())
	return control

func option(title: String, entries: Array, selected: int) -> OptionButton:
	text(title)
	var control := OptionButton.new()
	for entry in entries: control.add_item(str(entry))
	control.select(clampi(selected, 0, maxi(0, entries.size() - 1)))
	body.add_child(control)
	focusable(control)
	control.item_selected.connect(func(_index: int) -> void: cue_requested.emit(&"navigate"))
	return control

func toggle(title: String, value: bool) -> CheckBox:
	var control := CheckBox.new()
	control.text = title
	control.button_pressed = value
	body.add_child(control)
	focusable(control)
	return control

func slider(title: String, value: float, minimum := 0.0, maximum := 1.0) -> HSlider:
	var label := text(title + "  %d%%" % roundi(value * 100))
	var control := HSlider.new()
	control.min_value = minimum
	control.max_value = maximum
	control.step = 0.01
	control.value = value
	body.add_child(control)
	focusable(control)
	control.value_changed.connect(func(amount: float) -> void:
		label.text = title + "  %d%%" % roundi(amount * 100)
		cue_requested.emit(&"navigate"))
	return control

func finish() -> void:
	for index in focusables.size():
		var control := focusables[index]
		control.focus_neighbor_top = focusables[posmod(index - 1, focusables.size())].get_path()
		control.focus_neighbor_bottom = focusables[(index + 1) % focusables.size()].get_path()
		control.focus_next = control.focus_neighbor_bottom
		control.focus_previous = control.focus_neighbor_top
	if not focusables.is_empty(): _focus_later.call_deferred(focusables[0])

func _focus_later(control: Control) -> void:
	if is_instance_valid(control) and control.is_inside_tree() and visible: control.grab_focus()
