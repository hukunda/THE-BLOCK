extends Control
## Prototype: render a tiny 3D SubViewport, read pixels, show 1-bit dither ASCII.
## Run: open scenes/proto_3d_ascii.tscn → Run Current Scene (do not change main game entry).

@export var ascii_cols: int = 88
@export var ascii_rows: int = 28
@export var spin_deg_per_sec: float = 18.0

@onready var _vp: SubViewport = $SubViewport
@onready var _out: RichTextLabel = $AsciiView
@onready var _pivot: Node3D = $SubViewport/World/Pivot

var _warmup_frames: int = 0


func _ready() -> void:
	var f: Resource = load("res://fonts/NotoSansMono-Regular.ttf")
	if f is Font:
		_out.add_theme_font_override("normal_font", f as Font)
	_out.bbcode_enabled = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS


func _process(delta: float) -> void:
	if _pivot:
		_pivot.rotate_y(deg_to_rad(spin_deg_per_sec * delta))

	_warmup_frames += 1
	if _warmup_frames < 4:
		return

	var tex: ViewportTexture = _vp.get_texture()
	if tex == null:
		return
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		return

	var w: int = img.get_width()
	var h: int = img.get_height()
	if w < 2 or h < 2:
		return

	var sb: String = ""
	for ay in ascii_rows:
		for ax in ascii_cols:
			var sx: int = clampi(int((float(ax) + 0.5) * float(w) / float(ascii_cols)), 0, w - 1)
			var sy: int = clampi(int((float(ay) + 0.5) * float(h) / float(ascii_rows)), 0, h - 1)
			# Viewport images are often Y-flipped vs screen space.
			sy = (h - 1) - sy
			var lum: float = img.get_pixel(sx, sy).get_luminance()
			lum = sqrt(lum)
			var ch: int = AsciiRaycast._dither_char(lum, ay, ax)
			sb += String.chr(ch)
		if ay + 1 < ascii_rows:
			sb += "\n"

	_out.text = "[center][color=#ffffff]" + sb + "[/color][/center]"
