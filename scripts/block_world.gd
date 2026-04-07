class_name BlockWorld
## Deterministic simulation for all floors: entities, bosses, exits, doors.

signal floor_changed(index: int, title: String)
signal player_died
signal victory  # choose ending in UI
signal message(msg: String, duration: float)

var floor_index: int = 0
var map: PackedStringArray = PackedStringArray()
var player_pos: Vector2 = Vector2.ZERO
var player_angle: float = 0.0
var health: int = 8
var ammo: int = 18
var boss_defeated: bool = false
var entities: Array[Dictionary] = []
var boss: Dictionary = {}
var floor_glitch: float = 0.0
var floor_title: String = ""
var floor_blurb: String = ""
var _boss_id: String = ""

# Boss fight state
var _boss_timer: float = 0.0
var _knockback_vel: Vector2 = Vector2.ZERO
var _input_lag: float = 0.0
var _tenant_mirror: float = 0.0
var _roof_phase: int = 0
var _dmg_cd: float = 0.0
var _boss_dmg_cd: float = 0.0

# Floor 9 moving hazard
var _care_phase: float = 0.0
var _glitch_tick: int = 0

# New Game+
var new_game_plus: bool = false


func reset_run() -> void:
	new_game_plus = false
	health = 8
	ammo = 22
	floor_index = 0
	_load_floor(0, true)


func start_new_game_plus() -> void:
	new_game_plus = true
	health = mini(10, health + 2)
	ammo += 12
	floor_index = 0
	_load_floor(0, true)


func respawn_same_floor() -> void:
	health = 8
	_load_floor(floor_index, false)


func _load_floor(idx: int, grant_ammo: bool = true) -> void:
	floor_index = idx
	boss_defeated = false
	entities.clear()
	boss = {"active": false, "hp": 0, "pos": Vector2.ZERO}
	_knockback_vel = Vector2.ZERO
	_input_lag = 0.0
	_tenant_mirror = 0.0
	_roof_phase = 0
	_boss_timer = 0.0
	_care_phase = 0.0
	_dmg_cd = 0.0
	_boss_dmg_cd = 0.0

	var bundle: Dictionary = FloorCatalog.get_bundle(idx)
	floor_title = bundle["title"]
	floor_blurb = bundle["blurb"]
	floor_glitch = bundle["glitch"]
	if new_game_plus:
		floor_glitch = minf(0.45, floor_glitch + 0.08)
	_boss_id = bundle["boss_id"]

	var raw: PackedStringArray = bundle["map"].duplicate()
	map = _parse_map(raw)
	player_angle = deg_to_rad(-90.0)
	if grant_ammo:
		ammo += mini(8, 2 + floor_index)

	_configure_boss()
	emit_signal("floor_changed", floor_index, floor_title)
	emit_signal("message", floor_blurb, 5.0)


func _parse_map(raw: PackedStringArray) -> PackedStringArray:
	var spawn := Vector2(1.5, 1.5)
	var out: PackedStringArray = PackedStringArray()
	for y in raw.size():
		var line: String = raw[y]
		var row := ""
		for x in range(line.length()):
			var ch: String = line.substr(x, 1)
			if ch == "P":
				spawn = Vector2(float(x) + 0.5, float(y) + 0.5)
				row += "."
			elif ch == "@":
				entities.append({
					"pos": Vector2(float(x) + 0.5, float(y) + 0.5),
					"hp": _enemy_hp(),
					"speed": _enemy_speed(),
					"cd": 0.0,
					"kind": "resident",
				})
				row += "."
			elif ch == "&":
				boss["pos"] = Vector2(float(x) + 0.5, float(y) + 0.5)
				boss["active"] = true
				boss["hp"] = _boss_max_hp()
				boss["max_hp"] = boss["hp"]
				row += "."
			else:
				row += ch
		out.append(row)
	player_pos = spawn
	return out


func _enemy_hp() -> int:
	var t: int = 2 + floor_index / 3
	if new_game_plus:
		t += 1
	return t


func _enemy_speed() -> float:
	var s: float = 1.05 + float(floor_index) * 0.09
	if floor_index == 2:
		s += 0.35
	if floor_index == 3:
		s += 0.2
	return s


func _boss_max_hp() -> int:
	var h: int = 18 + floor_index * 5
	if new_game_plus:
		h = int(float(h) * 1.25)
	return h


func _configure_boss() -> void:
	match _boss_id:
		"doorman":
			boss["melee"] = true
			boss["slow"] = true
		"fall":
			boss["knockback"] = true
		"late_fee":
			boss["rush"] = true
		"player_one":
			boss["erratic"] = true
		"modem":
			boss["lag"] = true
		"remembers":
			boss["drain"] = true
		"ping":
			boss["blink"] = true
		"tenant":
			boss["mirror"] = true
		"caretaker":
			boss["shaft"] = true
		"the_block":
			boss["final"] = true


func physics_step(delta: float, move_fb: float, move_lr: float, turn: float, want_fire: bool, want_interact: bool) -> void:
	_glitch_tick += 1
	if health <= 0:
		return
	_dmg_cd = maxf(0.0, _dmg_cd - delta)
	_boss_dmg_cd = maxf(0.0, _boss_dmg_cd - delta)
	_boss_timer += delta
	_care_phase += delta

	var lag_mul: float = 1.0
	if _input_lag > 0.0:
		_input_lag -= delta
		lag_mul = 0.35
	if boss.get("lag", false) and boss["active"] and boss["hp"] > 0:
		lag_mul *= 0.55

	player_angle += turn * 2.35 * lag_mul * delta
	var forward := Vector2(cos(player_angle), sin(player_angle))
	var right := Vector2(-forward.y, forward.x)
	var vel := (forward * move_fb + right * move_lr) * 3.2 * lag_mul
	player_pos = AsciiRaycast.move_slide(map, player_pos, vel * delta)
	player_pos = AsciiRaycast.move_slide(map, player_pos, _knockback_vel * delta)
	_knockback_vel = _knockback_vel.move_toward(Vector2.ZERO, 8.0 * delta)

	if want_interact:
		_try_toggle_door()

	if want_fire:
		_fire()

	_sim_enemies(delta)
	_sim_boss(delta)
	_check_exit()


func _try_toggle_door() -> void:
	var ix := int(floor(player_pos.x))
	var iy := int(floor(player_pos.y))
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for d in dirs:
		var tx: int = ix + d.x
		var ty: int = iy + d.y
		var ch: String = AsciiRaycast.cell_at(map, tx, ty)
		if ch == "d":
			_set_cell(tx, ty, "o")
			emit_signal("message", "Unlatched.", 1.2)
			return
		elif ch == "o":
			_set_cell(tx, ty, "d")
			emit_signal("message", "Closed.", 1.0)
			return


func _set_cell(x: int, y: int, ch: String) -> void:
	if y < 0 or y >= map.size():
		return
	var row: String = map[y]
	if x < 0 or x >= row.length():
		return
	map[y] = row.substr(0, x) + ch + row.substr(x + 1)


func _fire() -> void:
	if ammo <= 0:
		emit_signal("message", "Dry click.", 1.5)
		return
	ammo -= 1
	var hit: Dictionary = _hitscan_target()
	var k: String = hit.get("kind", "none")
	if k == "boss":
		var dmg: int = 2 + (1 if new_game_plus else 0)
		boss["hp"] = boss["hp"] - dmg
		emit_signal("message", "The mass thins.", 1.2)
		if boss["hp"] <= 0:
			_on_boss_dead()
	elif k == "enemy":
		var i: int = hit["idx"]
		entities[i]["hp"] = entities[i]["hp"] - (2 if new_game_plus else 1)
		if entities[i]["hp"] <= 0:
			emit_signal("message", "Something stops moving.", 1.4)
		else:
			emit_signal("message", "Hit.", 0.8)
	else:
		emit_signal("message", "Round finds masonry.", 1.0)


func _hitscan_target() -> Dictionary:
	var dir := Vector2(cos(player_angle), sin(player_angle))
	var best_d: float = 99.0
	var best_i: int = -1
	for i in entities.size():
		if entities[i]["hp"] <= 0:
			continue
		var to_e: Vector2 = entities[i]["pos"] - player_pos
		var d: float = to_e.length()
		if d > 14.5 or d < 0.02:
			continue
		to_e /= d
		var dot: float = clampf(dir.dot(to_e), -1.0, 1.0)
		var ang: float = acos(dot)
		if ang < 0.32 and d < best_d:
			best_d = d
			best_i = i

	if boss.get("active", false) and boss["hp"] > 0:
		var visible: bool = true
		if boss.get("blink", false):
			visible = int(_boss_timer * 3.0) % 2 == 0
		if visible:
			var to_b: Vector2 = boss["pos"] - player_pos
			var db: float = to_b.length()
			if db < 17.0 and db > 0.02:
				to_b /= db
				var ad: float = acos(clampf(dir.dot(to_b), -1.0, 1.0))
				if ad < 0.26 and db < best_d:
					return {"kind": "boss", "idx": -1}

	if best_i >= 0:
		return {"kind": "enemy", "idx": best_i}
	return {"kind": "none"}


func _on_boss_dead() -> void:
	boss_defeated = true
	boss["active"] = false
	emit_signal("message", "Silence invoices you.", 2.5)
	if floor_index >= FloorCatalog.floor_count() - 1:
		emit_signal("victory")


func _check_exit() -> void:
	var ix := int(floor(player_pos.x))
	var iy := int(floor(player_pos.y))
	var ch: String = AsciiRaycast.cell_at(map, ix, iy)
	if ch != "!":
		return
	if not boss_defeated:
		emit_signal("message", "Not yet.", 1.2)
		return
	if floor_index >= FloorCatalog.floor_count() - 1:
		return
	_load_floor(floor_index + 1, true)


func _sim_enemies(delta: float) -> void:
	var i := 0
	while i < entities.size():
		var e: Dictionary = entities[i]
		if e["hp"] <= 0:
			i += 1
			continue
		var to_p: Vector2 = player_pos - e["pos"]
		var dist: float = to_p.length()
		if dist > 0.08:
			to_p /= dist
			e["pos"] += to_p * e["speed"] * delta
			if AsciiRaycast.is_blocked_at(map, e["pos"]):
				e["pos"] -= to_p * e["speed"] * delta * 1.1
		e["cd"] = maxf(0.0, e["cd"] - delta)
		if dist < 0.42 and _dmg_cd <= 0.0:
			health -= 1
			_dmg_cd = 1.1
			emit_signal("message", "Contact.", 1.0)
			if health <= 0:
				emit_signal("player_died")
		i += 1


func _sim_boss(delta: float) -> void:
	if not boss.get("active", false) or boss["hp"] <= 0:
		return
	var bpos: Vector2 = boss["pos"]
	var to_p: Vector2 = player_pos - bpos
	var dist: float = to_p.length()

	if boss.get("slow", false):
		if dist > 0.06:
			to_p /= dist
			boss["pos"] += to_p * 0.85 * delta
	elif boss.get("rush", false):
		if dist > 0.05:
			to_p /= dist
			boss["pos"] += to_p * 2.6 * delta
	elif boss.get("erratic", false):
		var j := Vector2(sin(_boss_timer * 2.7), cos(_boss_timer * 1.9))
		boss["pos"] += j * 1.8 * delta
	elif boss.get("blink", false):
		if int(_boss_timer * 2.0) % 7 == 0:
			boss["pos"] += Vector2(randf_range(-0.8, 0.8), randf_range(-0.8, 0.8))
	else:
		if dist > 0.07:
			to_p /= dist
			boss["pos"] += to_p * 1.35 * delta

	if AsciiRaycast.is_blocked_at(map, boss["pos"]):
		boss["pos"] = bpos

	if boss.get("knockback", false) and int(_boss_timer) % 4 == 0 and fmod(_boss_timer, delta) < delta:
		var away: Vector2 = player_pos - bpos
		if away.length() > 0.1:
			_knockback_vel += away.normalized() * 3.5

	if boss.get("lag", false):
		_input_lag = 0.18

	if boss.get("drain", false):
		if dist < 5.0 and int(_boss_timer * 2.0) % 5 == 0:
			ammo = maxi(0, ammo - 1)
			emit_signal("message", "Ammo forgets you.", 1.2)

	if boss.get("mirror", false):
		_tenant_mirror += delta
		if _tenant_mirror > 2.0:
			_tenant_mirror = 0.0
			player_angle += PI * 0.15

	if boss.get("shaft", false):
		var sh: float = sin(_care_phase * 1.1) * 2.2
		_knockback_vel += Vector2(sh, cos(_care_phase * 0.9)) * delta * 0.9

	if boss.get("final", false):
		var mh: int = maxi(1, int(boss.get("max_hp", 40)))
		var r: float = float(boss["hp"]) / float(mh)
		_roof_phase = 0
		if r < 0.66:
			_roof_phase = 1
		if r < 0.38:
			_roof_phase = 2
		if r < 0.12:
			_roof_phase = 3
		if _roof_phase >= 2:
			_input_lag = 0.12

	if dist < 0.52 and _boss_dmg_cd <= 0.0:
		health -= 2
		_boss_dmg_cd = 1.35
		emit_signal("message", "Boss contact.", 1.0)
		if health <= 0:
			emit_signal("player_died")


func collect_sprites() -> Array:
	var out: Array = []
	for e in entities:
		if e["hp"] > 0:
			out.append({"pos": e["pos"], "alive": true, "boss": false})
	if boss.get("active", false) and boss["hp"] > 0:
		var bp: Vector2 = boss["pos"]
		if boss.get("blink", false) and int(_boss_timer * 3.0) % 2 != 0:
			pass
		else:
			out.append({"pos": bp, "alive": true, "boss": true})
	return out


func apply_glitch_visual(s: String) -> String:
	if floor_glitch <= 0.001 and _roof_phase < 1:
		return s
	var g: float = floor_glitch
	if _boss_id == "the_block" and boss.get("active", false):
		g = minf(0.55, g + 0.2)
	var chars := [":", ".", "-", "|", "#", "%", "&", "?"]
	var out := ""
	for i in range(s.length()):
		var ch: String = s.substr(i, 1)
		if ch == "\n":
			out += ch
			continue
		var h: int = int(abs(sin(float(_glitch_tick + i) * 0.17 + float(floor_index))) * 1000.0) % 97
		if float(h) / 1000.0 < g * 0.12:
			var pick: int = int(abs(cos(float(i + _glitch_tick) * 0.31))) * 1000 % chars.size()
			out += chars[pick]
		else:
			out += ch
	return out


func roof_hud_strip() -> bool:
	return _boss_id == "the_block" and boss.get("active", false) and boss["hp"] > 0 and _roof_phase >= 1
