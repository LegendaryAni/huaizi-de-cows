extends CanvasLayer

const GameConfig = preload("res://scripts/GameConfig.gd")

signal upgrade_selected(upgrade_id: String)
signal start_game_requested
signal scores_requested
signal restart_requested
signal resume_requested
signal exit_requested

var root: Control
var hud_nodes := []
var hp_fill: TextureRect
var xp_fill: TextureRect
var hp_fill_clip: Control
var xp_fill_clip: Control
var hp_label: Label
var wave_label: Label
var kills_label: Label
var kills_value_label: Label
var time_label: Label
var time_value_label: Label
var cat_icons: HBoxContainer
var dim: ColorRect
var menu_panel: Control
var scores_panel: Control
var developer_panel: Control
var upgrade_panel: Control
var result_panel: Control
var pause_panel: Control
var current_screen := ""
var hud_visible := true

const START_BUTTONS := ["开始游戏", "成绩", "开发团队"]
const DEVELOPER_NAMES := ["LegendaryAni"]
const ORIGINAL_PROJECT_CREDIT := "原始项目：mewamew/huaizi-de-cows\n原作者：HexBlank"
const SCORES_EMPTY_PLACEHOLDER := "？？?"
const POPUP_CONTENT_TOP := 265.0
const POPUP_SIDE_PAD := 84.0
const POPUP_BOTTOM_PAD := 90.0
const BUTTON_FONT_SIZE := 27
const BUTTON_TEXT_Y_OFFSET := 4.0
const RESULT_VICTORY_TITLE_COLOR := Color(1.0, 0.82, 0.26)
const RESULT_FAILURE_TITLE_COLOR := Color(1.0, 0.28, 0.22)

const HP_BAR_POS := Vector2(184, 80)
const XP_BAR_POS := Vector2(184, 121)
const HP_BAR_SIZE := Vector2(354, 12)
const XP_BAR_SIZE := Vector2(354, 8)

var icon_paths := {
	"orange": "res://assets/sprites/ui/runtime/legendaryani/small_icon_orange_cat.png",
	"black": "res://assets/sprites/ui/runtime/legendaryani/small_icon_black_cat.png",
	"cow": "res://assets/sprites/ui/runtime/legendaryani/small_icon_cow_cat.png"
}

func _ready() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	_build_hud()
	hud_nodes = root.get_children()
	_build_dim()

func _build_hud() -> void:
	var left_back := NinePatchRect.new()
	left_back.texture = load("res://assets/sprites/ui/runtime/legendaryani/notice_panel_wide.9.png")
	left_back.position = Vector2(22, 18)
	left_back.size = Vector2(560, 205)
	left_back.patch_margin_left = 32
	left_back.patch_margin_right = 32
	left_back.patch_margin_top = 28
	left_back.patch_margin_bottom = 28
	left_back.modulate.a = 1.0
	root.add_child(left_back)
	var wave_back := NinePatchRect.new()
	wave_back.texture = load("res://assets/sprites/ui/runtime/legendaryani/notice_panel_wide.9.png")
	wave_back.position = Vector2(720, 18)
	wave_back.size = Vector2(480, 92)
	wave_back.patch_margin_left = 32
	wave_back.patch_margin_right = 32
	wave_back.patch_margin_top = 28
	wave_back.patch_margin_bottom = 28
	wave_back.modulate.a = 1.0
	root.add_child(wave_back)
	var stats_back := NinePatchRect.new()
	stats_back.texture = load("res://assets/sprites/ui/runtime/legendaryani/notice_panel_wide.9.png")
	stats_back.position = Vector2(1488, 20)
	stats_back.size = Vector2(390, 130)
	stats_back.patch_margin_left = 32
	stats_back.patch_margin_right = 32
	stats_back.patch_margin_top = 28
	stats_back.patch_margin_bottom = 28
	stats_back.modulate.a = 1.0
	root.add_child(stats_back)
	var avatar := TextureRect.new()
	avatar.texture = load("res://assets/sprites/ui/runtime/legendaryani/hud_avatar_frame.png")
	avatar.position = Vector2(36, 30)
	avatar.custom_minimum_size = Vector2(116, 116)
	avatar.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	root.add_child(avatar)
	var face := AnimatedSprite2D.new()
	face.sprite_frames = load("res://assets/sprites/legendaryani/huazi_8dir_192x192.spriteframes.tres")
	face.animation = "idle_s"
	face.play()
	face.position = Vector2(94, 88)
	face.scale = Vector2(0.42, 0.42)
	avatar.add_child(face)

	hp_label = Label.new()
	hp_label.position = Vector2(166, 31)
	hp_label.text = "花子"
	hp_label.add_theme_font_size_override("font_size", 28)
	root.add_child(hp_label)

	var hp_frame := NinePatchRect.new()
	hp_frame.texture = load("res://assets/sprites/ui/runtime/legendaryani/hud_bar_frame.9.png")
	hp_frame.position = Vector2(166, 68)
	hp_frame.size = Vector2(390, 36)
	hp_frame.patch_margin_left = 16
	hp_frame.patch_margin_right = 16
	hp_frame.patch_margin_top = 10
	hp_frame.patch_margin_bottom = 10
	hp_frame.z_index = 2
	root.add_child(hp_frame)
	var hp_empty := TextureRect.new()
	hp_empty.texture = load("res://assets/sprites/ui/runtime/legendaryani/bar_empty.png")
	hp_empty.position = HP_BAR_POS
	hp_empty.size = HP_BAR_SIZE
	hp_empty.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hp_empty.stretch_mode = TextureRect.STRETCH_SCALE
	hp_empty.modulate = Color(0.45, 0.42, 0.38, 0.92)
	hp_empty.z_index = 1
	root.add_child(hp_empty)
	hp_fill_clip = Control.new()
	hp_fill_clip.position = hp_empty.position
	hp_fill_clip.size = HP_BAR_SIZE
	hp_fill_clip.clip_contents = true
	hp_fill_clip.z_index = 1
	root.add_child(hp_fill_clip)
	hp_fill = TextureRect.new()
	hp_fill.texture = load("res://assets/sprites/ui/runtime/legendaryani/bar_fill_health.png")
	hp_fill.position = Vector2.ZERO
	hp_fill.size = HP_BAR_SIZE
	hp_fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hp_fill.stretch_mode = TextureRect.STRETCH_SCALE
	hp_fill_clip.add_child(hp_fill)

	var xp_frame := NinePatchRect.new()
	xp_frame.texture = load("res://assets/sprites/ui/runtime/legendaryani/hud_bar_frame.9.png")
	xp_frame.position = Vector2(166, 111)
	xp_frame.size = Vector2(390, 28)
	xp_frame.patch_margin_left = 16
	xp_frame.patch_margin_right = 16
	xp_frame.patch_margin_top = 10
	xp_frame.patch_margin_bottom = 10
	xp_frame.z_index = 2
	root.add_child(xp_frame)
	var xp_empty := TextureRect.new()
	xp_empty.texture = load("res://assets/sprites/ui/runtime/legendaryani/bar_empty.png")
	xp_empty.position = XP_BAR_POS
	xp_empty.size = XP_BAR_SIZE
	xp_empty.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	xp_empty.stretch_mode = TextureRect.STRETCH_SCALE
	xp_empty.modulate = Color(0.45, 0.42, 0.38, 0.9)
	xp_empty.z_index = 1
	root.add_child(xp_empty)
	xp_fill_clip = Control.new()
	xp_fill_clip.position = xp_empty.position
	xp_fill_clip.size = XP_BAR_SIZE
	xp_fill_clip.clip_contents = true
	xp_fill_clip.z_index = 1
	root.add_child(xp_fill_clip)
	xp_fill = TextureRect.new()
	xp_fill.texture = load("res://assets/sprites/ui/runtime/legendaryani/bar_fill_xp.png")
	xp_fill.position = Vector2.ZERO
	xp_fill.size = XP_BAR_SIZE
	xp_fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	xp_fill.stretch_mode = TextureRect.STRETCH_SCALE
	xp_fill_clip.add_child(xp_fill)

	cat_icons = HBoxContainer.new()
	cat_icons.position = Vector2(166, 150)
	cat_icons.add_theme_constant_override("separation", 12)
	root.add_child(cat_icons)

	wave_label = Label.new()
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.position = Vector2(710, 46)
	wave_label.size = Vector2(500, 60)
	wave_label.add_theme_font_size_override("font_size", 34)
	root.add_child(wave_label)

	kills_label = Label.new()
	kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	kills_label.position = Vector2(1530, 48)
	kills_label.size = Vector2(112, 40)
	kills_label.text = "击败"
	kills_label.add_theme_font_size_override("font_size", 28)
	root.add_child(kills_label)
	kills_value_label = Label.new()
	kills_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	kills_value_label.position = Vector2(1660, 48)
	kills_value_label.size = Vector2(180, 40)
	kills_value_label.add_theme_font_size_override("font_size", 28)
	root.add_child(kills_value_label)
	time_label = Label.new()
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.position = Vector2(1530, 94)
	time_label.size = Vector2(112, 40)
	time_label.text = "时间"
	time_label.add_theme_font_size_override("font_size", 28)
	root.add_child(time_label)
	time_value_label = Label.new()
	time_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	time_value_label.position = Vector2(1660, 94)
	time_value_label.size = Vector2(180, 40)
	time_value_label.add_theme_font_size_override("font_size", 28)
	root.add_child(time_value_label)

func _build_dim() -> void:
	dim = ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.01, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	root.add_child(dim)

func set_hud_visible(value: bool) -> void:
	hud_visible = value
	for node in hud_nodes:
		if is_instance_valid(node):
			node.visible = value

func _viewport_size() -> Vector2:
	var view_size := get_viewport().get_visible_rect().size
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		return Vector2(GameConfig.VIEWPORT_SIZE)
	return view_size

func _center_pos(panel_size: Vector2) -> Vector2:
	var view_size := _viewport_size()
	return Vector2(
		round((view_size.x - panel_size.x) * 0.5),
		round((view_size.y - panel_size.y) * 0.5)
	)

func _content_rect(panel_pos: Vector2, panel_size: Vector2) -> Rect2:
	return _content_rect_with_top(panel_pos, panel_size, POPUP_CONTENT_TOP)

func _content_rect_with_top(panel_pos: Vector2, panel_size: Vector2, top_offset: float) -> Rect2:
	return Rect2(
		panel_pos + Vector2(POPUP_SIDE_PAD, top_offset),
		panel_size - Vector2(POPUP_SIDE_PAD * 2.0, top_offset + POPUP_BOTTOM_PAD)
	)

func show_main_menu() -> void:
	clear_popups()
	set_hud_visible(false)
	current_screen = "main_menu"
	dim.visible = true
	menu_panel = Control.new()
	menu_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(menu_panel)
	var panel_size := Vector2(720, 720)
	var panel_pos := _center_pos(panel_size)
	var content := _content_rect(panel_pos, panel_size)
	_add_panel(menu_panel, panel_pos, panel_size, "warm")
	var title := Label.new()
	title.text = String(ProjectSettings.get_setting("application/config/name"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.position = content.position
	title.size = Vector2(content.size.x, 56)
	title.add_theme_font_size_override("font_size", 42)
	menu_panel.add_child(title)
	var button_size := Vector2(320, 76)
	var button_x := content.position.x + (content.size.x - button_size.x) * 0.5
	_add_textured_button(menu_panel, "开始游戏", Vector2(button_x, content.position.y + 78), button_size, func() -> void: start_game_requested.emit())
	_add_textured_button(menu_panel, "成绩", Vector2(button_x, content.position.y + 172), button_size, func() -> void: scores_requested.emit())
	_add_textured_button(menu_panel, "开发团队", Vector2(button_x, content.position.y + 266), button_size, func() -> void: show_developers())

func show_scores(scores: Array) -> void:
	clear_popups()
	set_hud_visible(false)
	current_screen = "scores"
	dim.visible = true
	scores_panel = Control.new()
	scores_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(scores_panel)
	var panel_size := Vector2(720, 780)
	var panel_pos := _center_pos(panel_size)
	var content := _content_rect(panel_pos, panel_size)
	_add_panel(scores_panel, panel_pos, panel_size, "warm")
	var title := Label.new()
	title.text = "成绩"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.position = content.position
	title.size = Vector2(content.size.x, 56)
	title.add_theme_font_size_override("font_size", 42)
	scores_panel.add_child(title)
	var button_size := Vector2(250, 68)
	var button_pos := Vector2(content.position.x + (content.size.x - button_size.x) * 0.5, content.end.y - button_size.y)
	var list_top := content.position.y + 76
	var list_bottom := button_pos.y - 24
	var list_rect := Rect2(content.position.x + 42, list_top, content.size.x - 84, min(248.0, max(120.0, list_bottom - list_top)))
	if scores.is_empty():
		var empty := Label.new()
		empty.text = SCORES_EMPTY_PLACEHOLDER
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.position = list_rect.position
		empty.size = list_rect.size
		empty.add_theme_font_size_override("font_size", 54)
		scores_panel.add_child(empty)
	else:
		var scroll := ScrollContainer.new()
		scroll.position = list_rect.position
		scroll.size = list_rect.size
		scroll.clip_contents = true
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		scores_panel.add_child(scroll)
		var list := VBoxContainer.new()
		list.size = Vector2(list_rect.size.x, 0)
		list.add_theme_constant_override("separation", 4)
		scroll.add_child(list)
		for i in min(scores.size(), int(GameConfig.SCORE["max_entries"])):
			var item: Dictionary = scores[i]
			_add_score_row(list, i + 1, int(item.get("score", 0)))
	_add_textured_button(scores_panel, "返回", button_pos, button_size, func() -> void: show_main_menu())

func show_developers() -> void:
	clear_popups()
	set_hud_visible(false)
	current_screen = "developers"
	dim.visible = true
	developer_panel = Control.new()
	developer_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(developer_panel)
	var panel_size := Vector2(620, 650)
	var panel_pos := _center_pos(panel_size)
	var content := _content_rect(panel_pos, panel_size)
	_add_panel(developer_panel, panel_pos, panel_size, "warm")
	var title := Label.new()
	title.text = "开发团队"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.position = content.position
	title.size = Vector2(content.size.x, 54)
	title.add_theme_font_size_override("font_size", 40)
	developer_panel.add_child(title)
	var names := Label.new()
	names.text = "\n".join(DEVELOPER_NAMES)
	names.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	names.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	names.position = Vector2(content.position.x, content.position.y + 78)
	names.size = Vector2(content.size.x, 112)
	names.add_theme_font_size_override("font_size", 32)
	developer_panel.add_child(names)
	var source_credit := Label.new()
	source_credit.text = ORIGINAL_PROJECT_CREDIT
	source_credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	source_credit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	source_credit.position = Vector2(content.position.x, content.position.y + 214)
	source_credit.size = Vector2(content.size.x, 92)
	source_credit.add_theme_font_size_override("font_size", 18)
	source_credit.modulate = Color(0.86, 0.82, 0.72)
	developer_panel.add_child(source_credit)
	var button_size := Vector2(250, 68)
	var button_pos := Vector2(content.position.x + (content.size.x - button_size.x) * 0.5, content.end.y - button_size.y)
	_add_textured_button(developer_panel, "返回", button_pos, button_size, func() -> void: show_main_menu())

func _add_panel(parent: Control, pos: Vector2, panel_size: Vector2, style: String) -> NinePatchRect:
	var panel := NinePatchRect.new()
	panel.texture = load("res://assets/sprites/ui/runtime/legendaryani/panel_result_dark.9.png" if style == "dark" else "res://assets/sprites/ui/runtime/legendaryani/panel_result_warm.9.png")
	panel.position = pos
	panel.size = panel_size
	panel.patch_margin_left = 42
	panel.patch_margin_right = 42
	panel.patch_margin_top = 42
	panel.patch_margin_bottom = 42
	parent.add_child(panel)
	return panel

func _add_textured_button(parent: Control, text: String, pos: Vector2, button_size: Vector2, pressed: Callable) -> Button:
	var button_bg := NinePatchRect.new()
	button_bg.texture = load("res://assets/sprites/ui/runtime/legendaryani/button_primary.9.png")
	button_bg.position = pos
	button_bg.size = button_size
	button_bg.patch_margin_left = 24
	button_bg.patch_margin_right = 24
	button_bg.patch_margin_top = 18
	button_bg.patch_margin_bottom = 18
	parent.add_child(button_bg)
	var button := Button.new()
	button.text = ""
	button.flat = true
	button.position = pos
	button.size = button_size
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(pressed)
	parent.add_child(button)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = pos + Vector2(0, BUTTON_TEXT_Y_OFFSET)
	label.size = button_size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	parent.add_child(label)
	return button

func _add_score_row(parent: VBoxContainer, rank: int, score: int) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(480, 32)
	row.add_theme_constant_override("separation", 18)
	parent.add_child(row)
	var rank_label := Label.new()
	rank_label.text = "%02d：" % rank
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rank_label.custom_minimum_size = Vector2(165, 32)
	rank_label.add_theme_font_size_override("font_size", 27)
	row.add_child(rank_label)
	var score_label := Label.new()
	score_label.text = str(score)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	score_label.custom_minimum_size = Vector2(240, 32)
	score_label.add_theme_font_size_override("font_size", 27)
	row.add_child(score_label)

func update_hud(snapshot: Dictionary) -> void:
	var hp_ratio: float = clamp(snapshot.player_hp / max(1.0, snapshot.player_max_hp), 0.0, 1.0)
	var xp_ratio: float = clamp(float(snapshot.xp) / max(1.0, float(snapshot.xp_needed)), 0.0, 1.0)
	_set_progress_fill(hp_fill_clip, hp_fill, HP_BAR_SIZE, hp_ratio)
	_set_progress_fill(xp_fill_clip, xp_fill, XP_BAR_SIZE, xp_ratio)
	hp_label.text = "花子  %d / %d" % [roundi(snapshot.player_hp), roundi(snapshot.player_max_hp)]
	wave_label.text = "第 %d 波  %d%%" % [snapshot.current_wave, roundi(snapshot.wave_progress * 100.0)]
	kills_value_label.text = str(snapshot.kills)
	time_value_label.text = format_time(snapshot.game_time)
	_refresh_cat_icons(snapshot.unlocked_weapons)
	if not hud_visible:
		set_hud_visible(false)

func _set_progress_fill(clip: Control, fill: TextureRect, full_size: Vector2, ratio: float) -> void:
	var clipped_width: float = full_size.x * clamp(ratio, 0.0, 1.0)
	clip.visible = clipped_width > 0.5
	clip.size = full_size
	fill.position = Vector2.ZERO
	fill.size = Vector2(clipped_width, full_size.y)

func _refresh_cat_icons(unlocked: Array) -> void:
	var existing := []
	for child in cat_icons.get_children():
		existing.append(child.name)
	for key in unlocked:
		if existing.has(key):
			continue
		var icon := TextureRect.new()
		icon.name = key
		icon.texture = load(icon_paths[key])
		icon.custom_minimum_size = Vector2(54, 54)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		cat_icons.add_child(icon)

func show_upgrade(options: Array, levels: Dictionary) -> void:
	clear_popups()
	set_hud_visible(true)
	current_screen = "upgrade"
	dim.visible = true
	upgrade_panel = Control.new()
	upgrade_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(upgrade_panel)
	var view_size := _viewport_size()
	var group_height := 650.0
	var top_y: float = round((view_size.y - group_height) * 0.5)
	var title := Label.new()
	title.text = "选择一次升级"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.position = Vector2(round((view_size.x - 700.0) * 0.5), top_y)
	title.size = Vector2(700, 58)
	title.add_theme_font_size_override("font_size", 44)
	upgrade_panel.add_child(title)
	var total_width: int = options.size() * 320 + max(0, options.size() - 1) * 38
	var start_x: float = round((view_size.x - float(total_width)) * 0.5)
	for i in options.size():
		var id: String = options[i]
		var data: Dictionary = GameConfig.UPGRADES[id]
		var card := _make_upgrade_card(id, data, levels.get(id, 0), Vector2(start_x + i * 358, top_y + 115), i)
		upgrade_panel.add_child(card)

func _make_upgrade_card(id: String, data: Dictionary, level: int, pos: Vector2, index: int) -> Control:
	var card := Control.new()
	card.position = pos
	card.size = Vector2(320, 520)
	var bg := NinePatchRect.new()
	bg.texture = load(["res://assets/sprites/ui/runtime/legendaryani/upgrade_card_gold.9.png", "res://assets/sprites/ui/runtime/legendaryani/upgrade_card_normal.9.png", "res://assets/sprites/ui/runtime/legendaryani/upgrade_card_red.9.png"][index % 3])
	bg.size = card.size
	bg.patch_margin_left = 32
	bg.patch_margin_right = 32
	bg.patch_margin_top = 32
	bg.patch_margin_bottom = 32
	card.add_child(bg)
	var icon := TextureRect.new()
	icon.texture = load(data.icon)
	icon.position = Vector2(86, 58)
	icon.size = Vector2(148, 148)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	card.add_child(icon)
	var name_label := Label.new()
	name_label.text = data.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(28, 228)
	name_label.size = Vector2(264, 46)
	name_label.add_theme_font_size_override("font_size", 32)
	card.add_child(name_label)
	var desc := Label.new()
	desc.text = "%s\n当前 %d / %d\n倍率 %.2fx" % [data.desc, level, data.max, pow(float(data.factor), level)]
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.position = Vector2(34, 306)
	desc.size = Vector2(252, 116)
	desc.add_theme_font_size_override("font_size", 22)
	card.add_child(desc)
	var medal := TextureRect.new()
	medal.texture = load("res://assets/sprites/ui/runtime/legendaryani/medal_cow_cat.png" if id == "U04" else "res://assets/sprites/ui/runtime/legendaryani/medal_orange_cat.png")
	medal.position = Vector2(126, 432)
	medal.size = Vector2(68, 68)
	medal.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	card.add_child(medal)
	var btn := Button.new()
	btn.text = ""
	btn.flat = true
	btn.position = Vector2.ZERO
	btn.size = card.size
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(func() -> void: upgrade_selected.emit(id))
	card.add_child(btn)
	return card

func show_result(result: String, snapshot: Dictionary) -> void:
	clear_popups()
	set_hud_visible(true)
	current_screen = "result_%s" % result
	dim.visible = true
	result_panel = Control.new()
	result_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(result_panel)
	var panel_size := Vector2(700, 820)
	var panel_pos := _center_pos(panel_size)
	var content := _content_rect_with_top(panel_pos, panel_size, 295.0)
	_add_panel(result_panel, panel_pos, panel_size, "warm" if result == "victory" else "dark")
	var title := Label.new()
	title.text = "胜利" if result == "victory" else "失败"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.position = content.position
	title.size = Vector2(content.size.x, 58)
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", RESULT_VICTORY_TITLE_COLOR if result == "victory" else RESULT_FAILURE_TITLE_COLOR)
	result_panel.add_child(title)
	var button_size := Vector2(230, 70)
	var button_y := content.end.y - button_size.y
	var stats_top := content.position.y + 62
	var stats_scroll := ScrollContainer.new()
	stats_scroll.position = Vector2(content.position.x, stats_top)
	stats_scroll.size = Vector2(content.size.x, max(140.0, button_y - stats_top - 22.0))
	stats_scroll.clip_contents = true
	stats_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stats_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	result_panel.add_child(stats_scroll)
	var stats := VBoxContainer.new()
	stats.size = Vector2(content.size.x, 0)
	stats.add_theme_constant_override("separation", 2)
	stats_scroll.add_child(stats)
	_add_result_stat_row(stats, "分数", str(int(snapshot.get("score", 0))))
	_add_result_stat_row(stats, "破纪录", "是" if bool(snapshot.get("is_new_record", false)) else "否")
	_add_result_stat_row(stats, "存活时间", format_time(snapshot.game_time))
	_add_result_stat_row(stats, "击败敌人", str(snapshot.kills))
	_add_result_stat_row(stats, "放出猫", str(snapshot.cats_fired))
	_add_result_stat_row(stats, "最常用猫", snapshot.favorite_cat)
	_add_result_stat_row(stats, "升级次数", str(snapshot.upgrade_count))
	_add_textured_button(result_panel, "退出", Vector2(content.position.x + 30, button_y), button_size, func() -> void: exit_requested.emit())
	_add_textured_button(result_panel, "重玩", Vector2(content.end.x - button_size.x - 30, button_y), button_size, func() -> void: restart_requested.emit())

func _add_result_stat_row(parent: VBoxContainer, title_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(480, 32)
	row.add_theme_constant_override("separation", 18)
	parent.add_child(row)
	var title := Label.new()
	title.text = title_text + "："
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title.custom_minimum_size = Vector2(170, 32)
	title.add_theme_font_size_override("font_size", 27)
	row.add_child(title)
	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	value.custom_minimum_size = Vector2(250, 32)
	value.add_theme_font_size_override("font_size", 27)
	row.add_child(value)

func show_pause() -> void:
	clear_popups()
	set_hud_visible(true)
	current_screen = "pause"
	dim.visible = true
	pause_panel = Control.new()
	pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(pause_panel)
	var panel_size := Vector2(500, 250)
	var panel_pos := _center_pos(panel_size)
	var panel := NinePatchRect.new()
	panel.texture = load("res://assets/sprites/ui/runtime/legendaryani/notice_panel_wide.9.png")
	panel.position = panel_pos
	panel.size = panel_size
	panel.patch_margin_left = 32
	panel.patch_margin_right = 32
	panel.patch_margin_top = 32
	panel.patch_margin_bottom = 32
	pause_panel.add_child(panel)
	var label := Label.new()
	label.text = "已暂停"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = panel_pos + Vector2(80, 42)
	label.size = Vector2(340, 60)
	label.add_theme_font_size_override("font_size", 46)
	pause_panel.add_child(label)
	_add_textured_button(pause_panel, "继续", panel_pos + Vector2(125, 140), Vector2(250, 66), func() -> void: resume_requested.emit())

func clear_popups() -> void:
	for node in [menu_panel, scores_panel, developer_panel, upgrade_panel, result_panel, pause_panel]:
		if node != null:
			node.queue_free()
	menu_panel = null
	scores_panel = null
	developer_panel = null
	upgrade_panel = null
	result_panel = null
	pause_panel = null
	dim.visible = false
	current_screen = ""

func format_time(seconds: float) -> String:
	var total := int(max(0.0, seconds))
	return "%02d:%02d" % [total / 60, total % 60]
