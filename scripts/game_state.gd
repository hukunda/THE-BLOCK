extends Node
## Autoload: input map + high-level UI mode (title / play / victory).

var show_title: bool = true
var paused: bool = false
var victory_screen: bool = false


func _ready() -> void:
	_setup_input_actions()


func _setup_input_actions() -> void:
	var fire_keys: Array = [KEY_CTRL]
	if OS.has_feature("web"):
		fire_keys.append(KEY_SPACE)
	var specs: Dictionary = {
		"move_forward": [KEY_W, KEY_UP],
		"move_backward": [KEY_S, KEY_DOWN],
		"strafe_left": [KEY_A],
		"strafe_right": [KEY_D],
		"turn_left": [KEY_Q, KEY_LEFT],
		"turn_right": [KEY_E, KEY_RIGHT],
		"fire": fire_keys,
		"interact": [KEY_F],
		"use_item": [KEY_R],
		"pause": [KEY_ESCAPE],
	}
	for action: String in specs.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.25)
		for keycode: int in specs[action]:
			var ev := InputEventKey.new()
			ev.keycode = keycode as Key
			ev.physical_keycode = keycode as Key
			if not _map_has_event(action, ev):
				InputMap.action_add_event(action, ev)
	_bind_gamepad_actions()
	_bind_digit_endings()


func _bind_digit_endings() -> void:
	for action: String in ["ending_leave", "ending_shutdown", "ending_stay"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.5)
	if not _action_has_key("ending_leave", KEY_1):
		var e1 := InputEventKey.new()
		e1.keycode = KEY_1
		e1.physical_keycode = KEY_1
		InputMap.action_add_event("ending_leave", e1)
	if not _action_has_key("ending_shutdown", KEY_2):
		var e2 := InputEventKey.new()
		e2.keycode = KEY_2
		e2.physical_keycode = KEY_2
		InputMap.action_add_event("ending_shutdown", e2)
	if not _action_has_key("ending_stay", KEY_3):
		var e3 := InputEventKey.new()
		e3.keycode = KEY_3
		e3.physical_keycode = KEY_3
		InputMap.action_add_event("ending_stay", e3)


func _action_has_key(action: String, code: Key) -> bool:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and (ev as InputEventKey).keycode == code:
			return true
	return false


func _map_has_event(action: String, needle: InputEventKey) -> bool:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and (ev as InputEventKey).keycode == needle.keycode:
			return true
	return false


func _bind_gamepad_actions() -> void:
	_add_joy_axis("turn_left", JOY_AXIS_RIGHT_X, -1.0)
	_add_joy_axis("turn_right", JOY_AXIS_RIGHT_X, 1.0)
	_add_joy_button("turn_left", JOY_BUTTON_LEFT_SHOULDER)
	_add_joy_button("turn_right", JOY_BUTTON_RIGHT_SHOULDER)
	_add_joy_button("fire", JOY_BUTTON_A)
	_add_joy_button("interact", JOY_BUTTON_X)
	_add_joy_button("use_item", JOY_BUTTON_Y)
	_add_joy_button("pause", JOY_BUTTON_START)


func _add_joy_axis(action: String, axis: JoyAxis, sign_dir: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = sign_dir
	InputMap.action_add_event(action, ev)


func _add_joy_button(action: String, button: JoyButton) -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
