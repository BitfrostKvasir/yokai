extends Node

func _ready() -> void:
	_action_key("move_forward", KEY_W)
	_action_key("move_back", KEY_S)
	_action_key("move_left", KEY_A)
	_action_key("move_right", KEY_D)
	_action_key("attack", KEY_SPACE)
	_action_mouse("attack", MOUSE_BUTTON_LEFT)
	_action_key("dodge", KEY_SHIFT)
	_action_mouse("guard", MOUSE_BUTTON_RIGHT)
	_action_key("special", KEY_E)
	_action_key("interact", KEY_F)

func _action_key(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)

func _action_mouse(action: String, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
