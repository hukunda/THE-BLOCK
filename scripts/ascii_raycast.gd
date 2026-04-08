class_name AsciiRaycast
## Wolfenstein-style DDA + optional sprite strips (GAME_DESIGN.md §6).

## Distance → brightness steps (far = light/dither, near = heavy blocks).
const WALL_EW: String = "·:--==+##█"
const WALL_NS: String = "·:::||+##█"


static func is_solid(ch: String) -> bool:
	match ch:
		"#", "|", "1", "=", "d":
			return true
		_:
			return false


static func cell_at(map: PackedStringArray, ix: int, iy: int) -> String:
	if iy < 0 or iy >= map.size():
		return "#"
	var row: String = map[iy]
	if ix < 0 or ix >= row.length():
		return "#"
	return row[ix]


static func is_blocked_at(map: PackedStringArray, pos: Vector2) -> bool:
	var ix := int(floor(pos.x))
	var iy := int(floor(pos.y))
	return is_solid(cell_at(map, ix, iy))


static func move_slide(map: PackedStringArray, pos: Vector2, delta: Vector2) -> Vector2:
	var p := pos
	var nx := p.x + delta.x
	if not is_blocked_at(map, Vector2(nx, p.y)):
		p.x = nx
	var ny := p.y + delta.y
	if not is_blocked_at(map, Vector2(p.x, ny)):
		p.y = ny
	return p


static func _shade_index(dist: float) -> float:
	return 1.0 - clampf(dist / 20.0, 0.0, 1.0)


static func _wall_glyph_at(
	dist: float,
	side_ns: bool,
	tex_u: float,
	row_in_strip: int,
	screen_x: int,
	wall_cell: String
) -> int:
	var pal: String = WALL_NS if side_ns else WALL_EW
	var shade: float = _shade_index(dist)
	var base_idx: int = int(shade * float(pal.length() - 1))
	var u: int = int(tex_u * 24.0) % 6
	var v: int = row_in_strip % 4
	var xor_uv: int = (u + v + screen_x) % 2

	match wall_cell:
		"d":
			var frame: String = "|" if xor_uv == 0 else ":"
			return frame.unicode_at(0)
		"1":
			var bar: String = "+" if (int(tex_u * 8.0) % 2) == 0 else "|"
			return bar.unicode_at(0)
		"=":
			var fence: String = "-" if (row_in_strip % 2) == 0 else "+"
			return fence.unicode_at(0)
		_:
			var pick: int = base_idx
			if side_ns:
				pick = clampi(base_idx + (1 if xor_uv == 0 else 0), 0, pal.length() - 1)
			else:
				var band: int = (int(tex_u * 5.0) + row_in_strip / 2) % 3
				pick = clampi(base_idx + band - 1, 0, pal.length() - 1)
			return pal.unicode_at(pick)


static func _ceiling_glyph(r: int, half: int, screen_x: int) -> int:
	var k: float = 1.0 - float(r) / float(max(1, half))
	var stripe: int = (screen_x + r) % 5
	if k > 0.82:
		return ("`" if stripe != 0 else ".").unicode_at(0)
	if k > 0.55:
		return ("'" if stripe % 2 == 0 else "`").unicode_at(0)
	if k > 0.28:
		return ("." if stripe % 2 == 0 else ":").unicode_at(0)
	return (":" if stripe % 2 == 0 else ".").unicode_at(0)


static func _floor_glyph(r: int, half: int, rows: int, screen_x: int) -> int:
	var k: float = float(r - half) / float(max(1, rows - half))
	var stripe: int = (screen_x + r * 2) % 7
	if k < 0.22:
		return ("_" if stripe % 3 != 0 else ",").unicode_at(0)
	if k < 0.55:
		return ("," if stripe % 2 == 0 else ".").unicode_at(0)
	if k < 0.82:
		return ("." if stripe % 2 == 0 else "-").unicode_at(0)
	return ("-" if stripe % 2 == 0 else "=").unicode_at(0)


static func render(
	map: PackedStringArray,
	pos: Vector2,
	angle: float,
	cols: int,
	view_rows: int,
	sprites: Array = []
) -> Dictionary:
	if cols < 8 or view_rows < 8:
		return {"text": "", "depth": []}
	var dir := Vector2(cos(angle), sin(angle))
	var plane := Vector2(-dir.y, dir.x) * tan(deg_to_rad(70.0) * 0.5)
	var half: int = view_rows / 2
	var grid: Array[Array] = []
	grid.resize(view_rows)
	for r in view_rows:
		var row: Array[int] = []
		row.resize(cols)
		for c in cols:
			row[c] = 32
		grid[r] = row

	var map_h: int = map.size()
	var depth_buffer: Array = []
	depth_buffer.resize(cols)
	for _i in range(cols):
		depth_buffer[_i] = 0.0

	for x in cols:
		var camera_x: float = 2.0 * float(x) / float(max(1, cols - 1)) - 1.0
		var ray_dir := dir + plane * camera_x
		var ray_x := ray_dir.x
		var ray_y := ray_dir.y
		var map_x := int(floor(pos.x))
		var map_y := int(floor(pos.y))

		var side_dist_x: float
		var side_dist_y: float
		var delta_dist_x: float = abs(1.0 / ray_x) if abs(ray_x) > 1e-6 else 1e30
		var delta_dist_y: float = abs(1.0 / ray_y) if abs(ray_y) > 1e-6 else 1e30
		var step_x: int
		var step_y: int
		var hit: bool = false
		var side: int = 0

		if ray_x < 0.0:
			step_x = -1
			side_dist_x = (pos.x - float(map_x)) * delta_dist_x
		else:
			step_x = 1
			side_dist_x = (float(map_x) + 1.0 - pos.x) * delta_dist_x
		if ray_y < 0.0:
			step_y = -1
			side_dist_y = (pos.y - float(map_y)) * delta_dist_y
		else:
			step_y = 1
			side_dist_y = (float(map_y) + 1.0 - pos.y) * delta_dist_y

		var guard: int = 0
		while not hit and guard < 512:
			guard += 1
			if side_dist_x < side_dist_y:
				side_dist_x += delta_dist_x
				map_x += step_x
				side = 0
			else:
				side_dist_y += delta_dist_y
				map_y += step_y
				side = 1
			if map_y < 0 or map_y >= map_h or map_x < 0 or map_x >= map[map_y].length():
				hit = true
			elif is_solid(cell_at(map, map_x, map_y)):
				hit = true

		var perp: float
		if side == 0:
			perp = (side_dist_x - delta_dist_x) if abs(ray_x) > 1e-6 else 1e30
		else:
			perp = (side_dist_y - delta_dist_y) if abs(ray_y) > 1e-6 else 1e30
		perp = maxf(perp, 0.05)
		depth_buffer[x] = perp

		var line_h: int = int(float(view_rows) * 0.85 / perp)
		line_h = clampi(line_h, 1, view_rows)
		var draw_start: int = half - line_h / 2
		var draw_end: int = half + line_h / 2
		draw_start = clampi(draw_start, 0, view_rows - 1)
		draw_end = clampi(draw_end, 0, view_rows - 1)

		var side_ns: bool = side == 1
		var wall_cell: String = cell_at(map, map_x, map_y)
		var tex_u: float = 0.5
		if side == 0:
			var wy: float = pos.y + perp * ray_y
			tex_u = wy - floor(wy)
		else:
			var wx: float = pos.x + perp * ray_x
			tex_u = wx - floor(wx)

		for r in view_rows:
			var ch: int
			if r < draw_start:
				ch = _ceiling_glyph(r, half, x)
			elif r > draw_end:
				ch = _floor_glyph(r, half, view_rows, x)
			else:
				var row_in_strip: int = r - draw_start
				ch = _wall_glyph_at(perp, side_ns, tex_u, row_in_strip, x, wall_cell)
			grid[r][x] = ch

	if sprites.size() > 0:
		_draw_sprites(grid, depth_buffer, view_rows, half, cols, pos, dir, plane, sprites)

	var out := ""
	for r in view_rows:
		for c in cols:
			out += String.chr(grid[r][c])
		if r + 1 < view_rows:
			out += "\n"
	return {"text": out, "depth": depth_buffer}


static func _sprite_transform(pos: Vector2, angle: float, sp: Vector2, dir: Vector2, plane: Vector2) -> Vector2:
	var sprite_x: float = sp.x - pos.x
	var sprite_y: float = sp.y - pos.y
	var inv_det: float = 1.0 / (plane.x * dir.y - dir.x * plane.y)
	var transform_x: float = inv_det * (dir.y * sprite_x - dir.x * sprite_y)
	var transform_y: float = inv_det * (-plane.y * sprite_x + plane.x * sprite_y)
	return Vector2(transform_x, transform_y)


static func _draw_sprites(
	grid: Array,
	depth_buffer: Array,
	view_rows: int,
	half: int,
	cols: int,
	pos: Vector2,
	dir: Vector2,
	plane: Vector2,
	sprites: Array
) -> void:
	var dir_x := dir.x
	var dir_y := dir.y
	var plane_x := plane.x
	var plane_y := plane.y
	var inv_det: float = 1.0 / (plane_x * dir_y - dir_x * plane_y)

	var scored: Array[Dictionary] = []
	for sp in sprites:
		if not sp.get("alive", true):
			continue
		var p: Vector2 = sp["pos"]
		var sprite_x: float = p.x - pos.x
		var sprite_y: float = p.y - pos.y
		var transform_x: float = inv_det * (dir_y * sprite_x - dir_x * sprite_y)
		var transform_y: float = inv_det * (-plane_y * sprite_x + plane_x * sprite_y)
		if transform_y <= 0.02:
			continue
		scored.append({"sp": sp, "ty": transform_y, "tx": transform_x})

	scored.sort_custom(func(a, b): return a["ty"] > b["ty"])

	for item in scored:
		var sp: Dictionary = item["sp"]
		var transform_x: float = item["tx"]
		var transform_y: float = item["ty"]
		var boss: bool = sp.get("boss", false)
		var sprite_screen_x: int = int((float(cols) / 2.0) * (1.0 + transform_x / transform_y))
		var h_scale: float = 1.0 if not boss else 1.85
		var w_scale: float = 1.0 if not boss else 2.1
		var sprite_height: int = int(float(view_rows) * 0.55 * h_scale / transform_y)
		sprite_height = clampi(sprite_height, 2, view_rows - 1)
		var sprite_width: int = maxi(1, int(float(cols) * 0.09 * w_scale / transform_y))
		var draw_start: int = clampi(half - sprite_height / 2, 0, view_rows - 1)
		var draw_end: int = clampi(half + sprite_height / 2, 0, view_rows - 1)

		for stripe in range(sprite_screen_x - sprite_width / 2, sprite_screen_x + sprite_width / 2 + 1):
			if stripe < 0 or stripe >= cols:
				continue
			if transform_y >= depth_buffer[stripe]:
				continue
			for r in range(draw_start, draw_end + 1):
				var ch: int
				if boss:
					var mid: bool = abs(r - half) < sprite_height / 4
					if mid and (stripe + r) % 2 == 0:
						ch = "█".unicode_at(0)
					elif (stripe + r) % 3 == 0:
						ch = "=".unicode_at(0)
					else:
						ch = "#".unicode_at(0)
				else:
					ch = "@".unicode_at(0) if (r + stripe) % 2 == 0 else "0".unicode_at(0)
				grid[r][stripe] = ch
			depth_buffer[stripe] = transform_y


static func hitscan_wall(map: PackedStringArray, pos: Vector2, angle: float, max_dist: float) -> Dictionary:
	var dir := Vector2(cos(angle), sin(angle))
	var p := pos
	var step: float = 0.04
	var d: float = 0.0
	while d < max_dist:
		p += dir * step
		d += step
		if is_blocked_at(map, p):
			return {"hit": true, "dist": d, "at": p}
	return {"hit": false, "dist": max_dist, "at": p}
