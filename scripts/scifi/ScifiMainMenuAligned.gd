extends Control
## Aligned, interactive main menu. Data and actions remain delegated to ScifiUI.
signal action_requested(action: String)

const ART := "res://assets/sprites/ui/runtime/scifi/"
const WHITE := Color("e9ede7")
const MUTED := Color("a4b1ad")
const AMBER := Color("dfb075")
const TEAL := Color("789fa3")
const ACTIONS := ["open_loadout", "open_meta", "open_scores", "open_settings", "tutorial", "open_credits", "quit"]
const GLYPHS := ["deploy", "workshop", "records", "settings", "tutorial", "credits", "quit"]
const LABELS := ["出擊整備", "永久改裝", "歷次成績", "音效與畫面", "操作教學", "開發與素材來源", "離開遊戲"]

const LEFT := 96.0
const NAV_WIDTH := 540.0
const HEADER_TOP := 62.0
const MAIN_TOP := 282.0
const SUPPORT_TOP := 473.0
const ROW_HEIGHT := 62.0
const ROW_GAP := 7.0
const SYSTEM_TOP := 806.0
const FOOTER_TOP := 920.0

var progress: Dictionary = {}
var scores: Array = []

func configure(value: Dictionary, history: Array) -> void:
	progress = value.duplicate(true)
	scores = history.duplicate(true)
	if is_node_ready():
		_rebuild()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	# Full-rect anchors own the Control size; never override it in _ready().
	_rebuild()

func _label(parent: Node, value: String, pos: Vector2, extent: Vector2, font_size: int, color: Color = WHITE, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.name = "Text_" + str(parent.get_child_count())
	label.position = pos
	label.size = extent
	label.text = value
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	# Prevent long local save values from rendering outside their assigned cell.
	var font: Font = label.get_theme_font("font")
	if font != null and not value.contains("\n"):
		var chosen := font_size
		while chosen > 14 and font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, chosen).x > extent.x - 5.0:
			chosen -= 1
		if chosen != font_size: label.add_theme_font_size_override("font_size",chosen)
	return label

func _bar(parent: Node, pos: Vector2, extent: Vector2, color: Color) -> ColorRect:
	var shape := ColorRect.new()
	shape.position = pos
	shape.size = extent
	shape.color = color
	shape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(shape)
	return shape

func _picture(parent: Node, path: String, pos: Vector2, extent: Vector2, linear: bool = false) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = load(path)
	picture.position = pos
	picture.size = extent
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if linear else CanvasItem.TEXTURE_FILTER_NEAREST
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(picture)
	return picture

func _button_style(kind: int, state: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if kind == 0:
		style.bg_color = Color("483528") if state in ["hover", "focus"] else Color("352b24")
		style.border_color = Color("f3c888") if state in ["hover", "focus"] else AMBER
		style.border_width_left = 5
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
	else:
		style.bg_color = Color(0.14, 0.20, 0.22, 0.92) if state in ["hover", "focus"] else Color(0.06, 0.10, 0.12, 0.74)
		style.border_color = AMBER if state in ["hover", "focus"] else Color("425557")
		style.border_width_left = 3 if state in ["hover", "focus"] else 1
		style.border_width_bottom = 1
	if state == "pressed":
		style.bg_color = Color("4c4130")
	return style

func _navigation(index: int, pos: Vector2, dimensions: Vector2, kind: int) -> void:
	var action: String = ACTIONS[index]
	var button := Button.new()
	button.name = "Command_" + action
	button.text = ""
	button.position = pos
	button.size = dimensions
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.set_meta("scifi_action", action)
	button.set_meta("scifi_value", null)
	button.add_to_group("scifi_buttons")
	button.clip_contents = true
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, _button_style(kind, state))
	add_child(button)
	button.pressed.connect(func() -> void: action_requested.emit(action))
	var icon_size := 56.0 if kind == 0 else (34.0 if kind == 2 else 42.0)
	var icon_x := 17.0 if kind == 2 else 20.0
	var glyph_y := floorf((dimensions.y - icon_size) / 2.0)
	_picture(button, ART + "menu_icon_" + GLYPHS[index] + ".png", Vector2(icon_x, glyph_y), Vector2(icon_size, icon_size))
	var text_x := 77.0 if kind == 2 else 91.0
	var right_reserve := 40.0 if kind != 2 else 12.0
	var text_width := dimensions.x - text_x - right_reserve
	var heading_size := 23 if kind == 2 else (33 if kind == 0 else 26)
	if kind == 0:
		_label(button, LABELS[index], Vector2(text_x, 10), Vector2(text_width, 48), heading_size)
		_label(button, "選擇武器與技能", Vector2(text_x, 60), Vector2(text_width, 28), 17, Color("dfc6a0"))
	else:
		_label(button, LABELS[index], Vector2(text_x, 0), Vector2(text_width, dimensions.y), heading_size, WHITE if kind == 1 else MUTED)
	if kind != 2:
		_label(button, "›", Vector2(dimensions.x - 43, 0), Vector2(29, dimensions.y), 32, AMBER if kind == 0 else MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	button.mouse_entered.connect(func() -> void: _set_highlight(button, true))
	button.mouse_exited.connect(func() -> void: _set_highlight(button, false))
	button.focus_entered.connect(func() -> void: _set_highlight(button, true))
	button.focus_exited.connect(func() -> void: _set_highlight(button, false))

func _set_highlight(button: Button, is_active: bool) -> void:
	if not is_instance_valid(button):
		return
	var animation: Tween = button.get_meta("fade_tween") if button.has_meta("fade_tween") else null
	if animation != null and animation.is_running():
		animation.kill()
	var tween := button.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", Color(1.06, 1.05, 1.0) if is_active else Color.WHITE, 0.13)
	button.set_meta("fade_tween", tween)

func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var background := _picture(self, ART + "menu_backdrop_v2.jpg", Vector2.ZERO, Vector2(1920, 1080), true)
	background.name = "MaintenanceBay"
	background.stretch_mode = TextureRect.STRETCH_SCALE
	_picture(self, ART + "menu_mech_shadow.png", Vector2(912, 682), Vector2(570, 135), true)
	var mech := _picture(self, ART + "menu_mech_1103.png", Vector2(1008, 361), Vector2(370, 365))
	mech.name = "MainUnit1103"
	var breathing := mech.create_tween().set_loops()
	breathing.tween_property(mech, "position:y", 357.0, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breathing.tween_property(mech, "position:y", 361.0, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# The entire command column uses a single left edge and a fixed baseline rhythm.
	_bar(self, Vector2(LEFT, HEADER_TOP + 4), Vector2(5, 97), AMBER)
	_label(self, "傳奇倖存者", Vector2(LEFT + 23, HEADER_TOP), Vector2(630, 91), 65)
	_label(self, "前線終端  /  工業廢墟行動", Vector2(LEFT + 25, HEADER_TOP + 103), Vector2(555, 38), 21, MUTED)
	_bar(self, Vector2(LEFT + 21, 210), Vector2(NAV_WIDTH - 21, 1), Color("68706b"))
	_label(self, "出擊任務", Vector2(LEFT + 5, 240), Vector2(300, 33), 19, AMBER)
	_navigation(0, Vector2(LEFT, MAIN_TOP), Vector2(NAV_WIDTH, 105), 0)

	_label(self, "作戰支援", Vector2(LEFT + 5, 429), Vector2(300, 34), 19, MUTED)
	_bar(self, Vector2(LEFT + 5, 467), Vector2(NAV_WIDTH - 5, 1), Color("455254"))
	for index in range(1, 5):
		var y := SUPPORT_TOP + float(index - 1) * (ROW_HEIGHT + ROW_GAP)
		_navigation(index, Vector2(LEFT, y), Vector2(NAV_WIDTH, ROW_HEIGHT), 1)

	_label(self, "系統", Vector2(LEFT + 5, 765), Vector2(300, 29), 18, MUTED)
	_bar(self, Vector2(LEFT + 5, 801), Vector2(NAV_WIDTH - 5, 1), Color("455254"))
	_navigation(5, Vector2(LEFT, SYSTEM_TOP), Vector2(328, 68), 2)
	_navigation(6, Vector2(LEFT + 340, SYSTEM_TOP), Vector2(200, 68), 2)

	# Game progress is real local state, not an invented online profile.
	_bar(self, Vector2(1486, 47), Vector2(370, 150), Color(0.035, 0.060, 0.069, 0.92))
	_bar(self, Vector2(1507, 65), Vector2(4, 100), AMBER)
	_label(self, "本機檔案", Vector2(1529, 60), Vector2(299, 39), 25)
	_label(self, "作戰紀錄  %d 筆" % scores.size(), Vector2(1530, 103), Vector2(299, 31), 18, MUTED)
	_label(self, "信用點  %d" % int(progress.get("credits", 0)), Vector2(1530, 141), Vector2(299, 32), 21, AMBER)

	_bar(self, Vector2(1475, 702), Vector2(65, 2), AMBER)
	_label(self, "壁壘 / 1103", Vector2(1460, 711), Vector2(375, 46), 29)
	_label(self, "重裝型・前線機體", Vector2(1460, 758), Vector2(375, 31), 19, MUTED)

	# Baseline-aligned footer columns, with no live-service or placeholder news.
	_bar(self, Vector2(0, FOOTER_TOP), Vector2(1920, 160), Color(0.043, 0.071, 0.083, 0.94))
	_bar(self, Vector2(LEFT, 946), Vector2(5, 92), AMBER)
	_label(self, "本次行動", Vector2(LEFT + 26, 941), Vector2(350, 34), 19, AMBER)
	_label(self, "工業廢墟", Vector2(LEFT + 26, 975), Vector2(355, 57), 37)
	_bar(self, Vector2(580, 950), Vector2(1, 87), Color("526064"))
	_label(self, "最終目標", Vector2(614, 941), Vector2(340, 34), 19, MUTED)
	_label(self, "擊敗徵收者", Vector2(614, 980), Vector2(359, 50), 28)
	_bar(self, Vector2(1030, 950), Vector2(1, 87), Color("526064"))
	_label(self, "出擊前請選擇主武器與兩項技能", Vector2(1061, 960), Vector2(740, 48), 23, MUTED)
	_label(self, "開發預覽 v0.2", Vector2(1595, 1027), Vector2(265, 28), 17, Color("819392"), HORIZONTAL_ALIGNMENT_RIGHT)

	if not String(progress.get("save_error", "")).is_empty():
		_label(self, String(progress.get("save_error", "")), Vector2(742, 868), Vector2(870, 43), 21, Color("f0ab88"))
	if not progress.get("pending", {}).is_empty():
		var save := Button.new()
		save.name = "Command_retry_save"
		save.position = Vector2(1075, 840)
		save.size = Vector2(320, 61)
		save.text = "重試待保存結算"
		save.add_theme_font_size_override("font_size", 22)
		save.set_meta("scifi_action", "retry_save")
		save.add_to_group("scifi_buttons")
		save.pressed.connect(func() -> void: action_requested.emit("retry_save"))
		add_child(save)
