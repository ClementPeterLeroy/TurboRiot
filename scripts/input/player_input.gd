extends DrivingInput

func _ready() -> void:
	# Set up named actions once; all device access stays in this provider.
	_bind_keys("accelerate", [KEY_W, KEY_UP])
	_bind_keys("brake", [KEY_S, KEY_DOWN])
	_bind_keys("steer_left", [KEY_A, KEY_LEFT])
	_bind_keys("steer_right", [KEY_D, KEY_RIGHT])
	_bind_keys("reset_kart", [KEY_R])
	_bind_keys("drift", [KEY_SHIFT])
	_bind_keys("start_race", [KEY_ENTER, KEY_SPACE])
	_bind_keys("restart_race", [KEY_F5])
	_bind_keys("debug_hud", [KEY_F3])
	_bind_keys("exit_game", [KEY_ESCAPE])
	_bind_axis("steer_left", JOY_AXIS_LEFT_X, -1.0)
	_bind_axis("steer_right", JOY_AXIS_LEFT_X, 1.0)
	_bind_axis("accelerate", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_bind_axis("brake", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_bind_button("reset_kart", JOY_BUTTON_Y)
	_bind_button("drift", JOY_BUTTON_LEFT_SHOULDER)
	_bind_button("start_race", JOY_BUTTON_A)
	_bind_button("restart_race", JOY_BUTTON_X)
	_bind_button("debug_hud", JOY_BUTTON_BACK)
	_bind_button("exit_game", JOY_BUTTON_START)

func get_command() -> DrivingCommand:
	return DrivingCommand.new(Input.get_action_strength("accelerate"),
		Input.get_action_strength("brake"), Input.get_axis("steer_left", "steer_right"), Input.is_action_pressed("drift"))

func _bind_keys(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.12)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)

func _bind_axis(action: String, axis: JoyAxis, direction: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = direction
	event.device = -1
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)

func _bind_button(action: String, button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.device = -1
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)
