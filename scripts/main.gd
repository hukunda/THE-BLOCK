extends Control
## Full game shell: title, 10 floors, victory endings, web-friendly.

@onready var ascii_view: Label = $AsciiView
@onready var touch_layer: CanvasLayer = $TouchLayer

var world: BlockWorld = BlockWorld.new()

var message: String = ""
var message_ttl: float = 0.0
var fire_flash: float = 0.0
var _want_fire: bool = false
var _want_interact: bool = false

var move_touch_idx: int = -1
var move_origin: Vector2 = Vector2.ZERO
var move_vector: Vector2 = Vector2.ZERO
const STICK_MAX: float = 96.0

const MIN_COLS: int = 80
const MIN_VIEW_ROWS: int = 22
const HUD_ROWS: int = 8


func _ready() -> void:
	world.floor_changed.connect(_on_floor_changed)
	world.player_died.connect(_on_player_died)
	world.victory.connect(_on_victory)
	world.message.connect(_on_world_message)
	var f: Resource = load("res://fonts/NotoSansMono-Regular.ttf")
	if f is Font:
		ascii_view.add_theme_font_override("font", f as Font)
	_connect_touch_buttons()
	_touch_setup()
	ascii_view.text = _title_text()


func _on_floor_changed(_i: int, _t: String) -> void:
	pass


func _on_player_died() -> void:
	message = "You fold. The building does not."
	message_ttl = 3.5
	world.respawn_same_floor()


func _on_victory() -> void:
	GameState.victory_screen = true
	GameState.paused = false
	message = "Choose."
	message_ttl = 99.0


func _on_world_message(msg: String, duration: float) -> void:
	message = msg
	message_ttl = maxf(message_ttl, duration)


func _connect_touch_buttons() -> void:
	var bar := touch_layer.get_node_or_null("TouchBar")
	if bar == null:
		return
	var tl: Button = bar.get_node_or_null("TurnL") as Button
	var tr: Button = bar.get_node_or_null("TurnR") as Button
	var fi: Button = bar.get_node_or_null("Fire") as Button
	var us: Button = bar.get_node_or_null("Use") as Button
	if tl:
		tl.pressed.connect(_on_touch_turn_left)
	if tr:
		tr.pressed.connect(_on_touch_turn_right)
	if fi:
		fi.pressed.connect(_on_touch_fire)
	if us:
		us.pressed.connect(_on_touch_interact)


func _touch_setup() -> void:
	var touch := DisplayServer.has_feature(DisplayServer.FEATURE_TOUCHSCREEN)
	touch_layer.visible = touch or OS.has_feature("mobile")


func _physics_process(delta: float) -> void:
	if GameState.show_title or GameState.victory_screen:
		return
	if GameState.paused:
		message_ttl = maxf(0.0, message_ttl - delta)
		return

	var fb: float = Input.get_axis("move_backward", "move_forward")
	var lr: float = Input.get_axis("strafe_left", "strafe_right")
	var turn: float = Input.get_axis("turn_left", "turn_right")
	var pads := Input.get_connected_joypads()
	if not pads.is_empty():
		var ji: int = pads[0]
		fb -= Input.get_joy_axis(ji, JOY_AXIS_LEFT_Y)
		lr += Input.get_joy_axis(ji, JOY_AXIS_LEFT_X)
	if move_touch_idx >= 0:
		fb -= move_vector.y
		lr += move_vector.x

	var wf: bool = Input.is_action_just_pressed("fire") or _want_fire
	_want_fire = false
	var wi: bool = Input.is_action_just_pressed("interact") or _want_interact
	_want_interact = false
	world.physics_step(delta, fb, lr, turn, wf, wi)
	if wf:
		fire_flash = 0.12

	message_ttl = maxf(0.0, message_ttl - delta)
	fire_flash = maxf(0.0, fire_flash - delta)


func _process(_delta: float) -> void:
	_redraw_ascii()


func _redraw_ascii() -> void:
	if GameState.show_title:
		ascii_view.text = _title_text()
		return
	if GameState.victory_screen:
		ascii_view.text = _victory_text()
		return

	var cell: Vector2 = _cell_size()
	var cols: int = maxi(MIN_COLS, int(size.x / cell.x))
	var total_rows: int = maxi(MIN_VIEW_ROWS + HUD_ROWS, int(size.y / cell.y))
	var view_rows: int = clampi(total_rows - HUD_ROWS, MIN_VIEW_ROWS, total_rows - 1)
	if world.roof_hud_strip():
		view_rows = maxi(MIN_VIEW_ROWS - 4, view_rows - 4)

	var res: Dictionary = AsciiRaycast.render(
		world.map,
		world.player_pos,
		world.player_angle,
		cols,
		view_rows,
		world.collect_sprites(),
		fire_flash * 2.25,
		world.floor_glitch,
		float(Engine.get_process_frames() % 100000) * 0.002
	)
	var world_str: String = res["text"]
	ascii_view.text = world_str + "\n" + _build_hud(cols)


func _cell_size() -> Vector2:
	var f: Font = ascii_view.get_theme_font("font")
	var fs: int = ascii_view.get_theme_font_size("font_size")
	if f:
		var sz: Vector2 = f.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		return Vector2(maxf(sz.x, 1.0), maxf(sz.y, 1.0))
	return Vector2(9.0, 16.0)


func _build_hud(cols: int) -> String:
	if world.roof_hud_strip():
		var line0: String = _pad_line("SIGNAL LOST — RULES BEND", cols)
		return line0 + "\n" + _build_hud_body(cols)
	return _build_hud_body(cols)


func _build_hud_body(cols: int) -> String:
	var hp_bar: String = _hp_bar()
	var floor_line: String = "FL %d/10  %s" % [world.floor_index + 1, world.floor_title]
	var line1: String = "HP [%-12s]  AMMO %-3d  %s" % [hp_bar, world.ammo, floor_line]
	var sub: String = message if message_ttl > 0 else world.floor_blurb
	if GameState.paused:
		sub = "PAUSED — pause (Esc) to continue."
	var line2: String = "> " + sub
	return _pad_line(line1, cols) + "\n" + _pad_line(line2, cols)


func _hp_bar() -> String:
	var segments: int = 10
	var mx: int = 10
	var filled: int = clampi(int(round((float(world.health) / float(mx)) * float(segments))), 0, segments)
	return _repeat("|", filled) + _repeat(" ", segments - filled)


func _repeat(ch: String, count: int) -> String:
	var s := ""
	for _i in count:
		s += ch
	return s


func _pad_line(s: String, cols: int) -> String:
	if s.length() >= cols:
		return s.substr(0, cols)
	return s + _repeat(" ", cols - s.length())


func _title_text() -> String:
	return """████████████████████████████████████████
              THE BLOCK

        An ASCII urban nightmare
                1995–2004

        > TAP / KEY / GAMEPAD TO START <

████████████████████████████████████████"""


func _victory_text() -> String:
	return """THE ROOF PAID IN FULL.

No perfect outcome. Pick one:

  [1] LEAVE — walk out while it pretends not to watch.
  [2] SHUT DOWN — starve the lights. Cold exit.
  [3] STAY — NG+ (the building keeps receipts.)

  Touch: << = LEAVE   FIRE = SHUT DOWN   USE = STAY (NG+)
████████████████████████████████████████"""


func _input(event: InputEvent) -> void:
	if GameState.show_title:
		if event is InputEventKey and event.pressed and not event.echo:
			GameState.show_title = false
			world.reset_run()
			get_viewport().set_input_as_handled()
		elif event is InputEventScreenTouch and event.pressed:
			GameState.show_title = false
			world.reset_run()
			get_viewport().set_input_as_handled()
		return

	if GameState.victory_screen:
		if event.is_action_pressed("ending_leave") or (event is InputEventKey and event.keycode == KEY_1 and event.pressed):
			_do_leave()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ending_shutdown") or (event is InputEventKey and event.keycode == KEY_2 and event.pressed):
			_do_shutdown()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ending_stay") or (event is InputEventKey and event.keycode == KEY_3 and event.pressed):
			_do_stay()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("pause"):
		GameState.paused = not GameState.paused
		get_viewport().set_input_as_handled()


func _do_leave() -> void:
	GameState.victory_screen = false
	get_tree().quit()


func _do_shutdown() -> void:
	GameState.victory_screen = false
	GameState.show_title = true
	message = ""
	message_ttl = 0.0


func _do_stay() -> void:
	GameState.victory_screen = false
	world.start_new_game_plus()
	message = "Again. The walls remember harder."
	message_ttl = 4.0


func _unhandled_input(event: InputEvent) -> void:
	_handle_touch_move(event)


func _handle_touch_move(event: InputEvent) -> void:
	if not touch_layer.visible:
		return
	var rect: Vector2 = get_viewport_rect().size
	var zone := Rect2(0.0, rect.y * 0.62, rect.x * 0.44, rect.y * 0.38)
	if event is InputEventScreenTouch:
		if event.pressed and zone.has_point(event.position):
			move_touch_idx = event.index
			move_origin = event.position
			move_vector = Vector2.ZERO
		elif not event.pressed and event.index == move_touch_idx:
			move_touch_idx = -1
			move_vector = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == move_touch_idx:
		var d: Vector2 = event.position - move_origin
		move_vector = Vector2(
			clampf(d.x / STICK_MAX, -1.0, 1.0),
			clampf(d.y / STICK_MAX, -1.0, 1.0)
		)


func _on_touch_turn_left() -> void:
	if GameState.victory_screen:
		_do_leave()
		return
	if GameState.show_title or GameState.paused:
		return
	world.player_angle -= deg_to_rad(22.0)


func _on_touch_turn_right() -> void:
	if GameState.victory_screen:
		return
	if GameState.show_title or GameState.paused:
		return
	world.player_angle += deg_to_rad(22.0)


func _on_touch_fire() -> void:
	if GameState.victory_screen:
		_do_shutdown()
		return
	if GameState.show_title or GameState.paused:
		return
	_want_fire = true


func _on_touch_interact() -> void:
	if GameState.victory_screen:
		_do_stay()
		return
	if GameState.show_title or GameState.paused:
		return
	_want_interact = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
