extends DrivingInput
var assigned_device := -2
var suppress_item_until_release := false

func _ready() -> void:
	# Set up named actions once; all device access stays in this provider.
	_bind_keys("accelerate", [KEY_W, KEY_UP])
	_bind_keys("brake", [KEY_S, KEY_DOWN])
	_bind_keys("steer_left", [KEY_A, KEY_LEFT])
	_bind_keys("steer_right", [KEY_D, KEY_RIGHT])
	_bind_keys("reset_kart", [KEY_R])
	_bind_keys("drift", [KEY_SHIFT])
	_bind_keys("use_item", [KEY_SPACE])
	_bind_button("use_item", JOY_BUTTON_B)
	_bind_keys("start_race", [KEY_ENTER, KEY_SPACE])
	_bind_keys("restart_race", [KEY_F5])
	_bind_keys("debug_hud", [KEY_F3])
	_bind_keys("debug_ai", [KEY_F8])
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
	if assigned_device != -2:
		var gas := 0.0
		var brake := 0.0
		var steering := 0.0
		var drifting := false
		var item := false
		if assigned_device == -1:
			gas = 1.0 if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) else 0.0
			brake = 1.0 if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) else 0.0
			steering = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
			drifting = Input.is_physical_key_pressed(KEY_SHIFT)
			item = Input.is_physical_key_pressed(KEY_SPACE)
		elif assigned_device in Input.get_connected_joypads():
			gas = maxf(0, _axis_strength(Input.get_joy_axis(assigned_device, JOY_AXIS_TRIGGER_RIGHT), "accelerate"))
			brake = maxf(0, _axis_strength(Input.get_joy_axis(assigned_device, JOY_AXIS_TRIGGER_LEFT), "brake"))
			steering = _axis_strength(Input.get_joy_axis(assigned_device, JOY_AXIS_LEFT_X), "steer_right")
			drifting = Input.is_joy_button_pressed(assigned_device, JOY_BUTTON_LEFT_SHOULDER)
			item = Input.is_joy_button_pressed(assigned_device, JOY_BUTTON_B)
		if not item: suppress_item_until_release = false
		return DrivingCommand.new(gas, brake, steering, drifting, item and not suppress_item_until_release)
	if not Input.is_action_pressed("use_item"): suppress_item_until_release = false
	return DrivingCommand.new(Input.get_action_strength("accelerate"),
		Input.get_action_strength("brake"), Input.get_axis("steer_left", "steer_right"), Input.is_action_pressed("drift"), Input.is_action_pressed("use_item") and not suppress_item_until_release)

func _axis_strength(value: float, action: String) -> float:
	# Match InputMap normalization when polling one assigned device directly.
	var deadzone := InputMap.action_get_deadzone(action)
	return signf(value) * clampf((absf(value) - deadzone) / maxf(0.001, 1 - deadzone), 0, 1)

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
