class_name CircuitCard
extends Button
var definition: TrackDefinition
var chosen := false:
	set(value):
		chosen = value
		queue_redraw()
var outline := CircuitOutline.new()
var caption := Label.new()

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	add_child(outline)
	add_child(caption)
	caption.text = definition.display_name
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 27)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	outline.configure(definition.preview_curve(), definition.accent)
	outline.configure_branches(definition.preview_branches())
	resized.connect(_layout)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	_layout()

func _layout() -> void:
	outline.position = Vector2(12, 44)
	outline.size = Vector2(size.x - 24, maxf(20, size.y - 112))
	caption.position = Vector2(16, size.y - 57)
	caption.size = Vector2(size.x - 32, 40)
	caption.add_theme_font_size_override("font_size", 22 if size.x < 320 else 27)

func _draw() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("142c40") if is_hovered() or has_focus() else Color("102235")
	panel.border_color = Color("ffdc56") if chosen else Color("446174")
	panel.set_border_width_all(3 if chosen else 1)
	panel.set_corner_radius_all(16)
	draw_style_box(panel, Rect2(Vector2.ONE * 4, size - Vector2.ONE * 8))
	draw_line(Vector2(24, size.y - 70), Vector2(size.x - 24, size.y - 70), Color("29465b"), 1)
	draw_line(Vector2(25, 26), Vector2(61, 26), definition.accent, 4, true)
	if chosen:
		draw_string(ThemeDB.fallback_font, Vector2(maxf(70, size.x - 116), 32), "SELECTED", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ffdc56"))
	if has_focus():
		var ring := StyleBoxFlat.new()
		ring.bg_color = Color.TRANSPARENT
		ring.border_color = Color("40d5e5")
		ring.set_border_width_all(2)
		ring.set_corner_radius_all(19)
		draw_style_box(ring, Rect2(Vector2.ONE, size - Vector2.ONE * 2))
