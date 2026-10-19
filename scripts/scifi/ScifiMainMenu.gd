extends Control
## Real interactive sci-fi main menu. Presentation only: all actions are forwarded to ScifiUI.
signal action_requested(action: String)

const ART := "res://assets/sprites/ui/runtime/scifi/"
const MENU := ["open_loadout","open_meta","open_scores","open_settings","tutorial","open_credits","quit"]
const ICONS := ["deploy","workshop","records","settings","tutorial","credits","quit"]
const NAMES := ["出擊整備","永久改裝","歷次成績","音效與畫面","操作教學","製作資訊","離開遊戲"]
const SUBTITLES := ["DEPLOY","WORKSHOP","RECORDS","OPTIONS","TUTORIAL","CREDITS","EXIT"]
const GOLD := Color("f5bc66")
const PAPER := Color("f2f5f3")
const MUTED := Color("a8b9c3")
const CYAN := Color("7bcee9")
var progress: Dictionary = {}
var scores: Array = []
var intro_done := false

func configure(value: Dictionary, history: Array) -> void:
	progress = value.duplicate(true)
	scores = history.duplicate(true)
	if is_node_ready(): _rebuild()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_rebuild()

func _label(parent: Node, message: String, origin: Vector2, size_value: Vector2, font_size: int, color: Color, bold := false) -> Label:
	var item := Label.new()
	item.position = origin
	item.size = size_value
	item.text = message
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item.add_theme_font_size_override("font_size",font_size)
	item.add_theme_color_override("font_color",color)
	if bold:
		item.add_theme_constant_override("outline_size",2)
		item.add_theme_color_override("font_outline_color", Color(0.01,0.025,0.035,0.94))
	parent.add_child(item)
	return item

func _rect(parent: Node, origin: Vector2, extent: Vector2, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = origin
	rect.size = extent
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect

func _panel(parent: Node, origin: Vector2, extent: Vector2, background: Color, outline := CYAN) -> Panel:
	var pane := Panel.new()
	pane.position = origin
	pane.size = extent
	pane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = outline
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0.01,0.02,0.03,0.44)
	style.shadow_size = 7
	pane.add_theme_stylebox_override("panel",style)
	parent.add_child(pane)
	return pane

func _picture(parent: Node, path: String, origin: Vector2, extent: Vector2, use_linear := false) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = load(path)
	picture.position = origin
	picture.size = extent
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if use_linear else CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(picture)
	return picture

func _button_styles(normal: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = normal
	style.border_color = border
	style.border_width_left = 4
	style.border_width_top = 1
	style.border_width_right = 2
	style.border_width_bottom = 1
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_top_left = 3
	style.corner_radius_bottom_left = 3
	style.shadow_color = Color(0.05,0.12,0.15,0.4)
	style.shadow_size = 3
	return style

func _navigation_button(index: int) -> void:
	var action: String = MENU[index]
	var gold := index == 0
	var button := Button.new()
	button.name = "Menu_%s" % action
	button.position = Vector2(94,252+index*77)
	button.size = Vector2(560,68)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.focus_mode = Control.FOCUS_ALL
	button.pivot_offset = Vector2(0,34)
	button.text = ""
	button.set_meta("scifi_action",action)
	button.set_meta("scifi_value",null)
	button.add_to_group("scifi_buttons")
	button.add_theme_stylebox_override("normal",_button_styles(Color(0.025,0.052,0.078,0.89) if not gold else Color(0.20,0.13,0.045,0.93), CYAN.darkened(0.55) if not gold else GOLD))
	button.add_theme_stylebox_override("hover",_button_styles(Color(0.17,0.13,0.067,0.95),GOLD))
	button.add_theme_stylebox_override("pressed",_button_styles(Color(0.21,0.18,0.091,0.99),GOLD.lightened(0.2)))
	button.add_theme_stylebox_override("focus",_button_styles(Color(0.09,0.09,0.084,0.9),GOLD))
	# Decorative children ignore mouse events; the Button remains the sole hit target.
	add_child(button)
	_picture(button,ART+"menu_icon_"+ICONS[index]+".png",Vector2(18,8),Vector2(50,50))
	_rect(button,Vector2(85,12),Vector2(2,43),GOLD if gold else CYAN.darkened(0.5))
	_label(button,NAMES[index],Vector2(102,6),Vector2(355,36),27,GOLD if gold else PAPER,true)
	_label(button,SUBTITLES[index],Vector2(104,39),Vector2(340,23),14,GOLD.darkened(0.15) if gold else MUTED)
	_label(button,"›",Vector2(498,1),Vector2(52,61),45,GOLD if gold else CYAN)
	button.pressed.connect(func() -> void: action_requested.emit(action))
	button.mouse_entered.connect(func() -> void: _highlight(button,true))
	button.mouse_exited.connect(func() -> void: _highlight(button,false))
	button.focus_entered.connect(func() -> void: _highlight(button,true))
	button.focus_exited.connect(func() -> void: _highlight(button,false))
	button.modulate.a = 0.0
	button.position.x -= 24
	var entry := button.create_tween()
	entry.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	entry.tween_interval(float(index)*0.036)
	entry.tween_property(button,"position:x",94.0,0.25)
	entry.parallel().tween_property(button,"modulate:a",1.0,0.25)

func _highlight(button: Button, active: bool) -> void:
	var previous: Tween = button.get_meta("menu_hover") if button.has_meta("menu_hover") else null
	if previous != null and previous.is_running(): previous.kill()
	var animation := button.create_tween()
	animation.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	animation.tween_property(button,"position:x",102.0 if active else 94.0,0.16)
	button.set_meta("menu_hover",animation)

func _small_action(action: String, message: String, origin: Vector2, extent: Vector2) -> void:
	var button := Button.new()
	button.name = "Menu_%s_secondary" % action
	button.text = message
	button.position = origin
	button.size = extent
	button.add_theme_font_size_override("font_size",18)
	button.add_theme_color_override("font_color",PAPER)
	button.add_theme_stylebox_override("normal",_button_styles(Color(0.035,0.063,0.080,0.94),CYAN.darkened(0.38)))
	button.add_theme_stylebox_override("hover",_button_styles(Color(0.12,0.13,0.12,1),GOLD))
	button.set_meta("scifi_action",action)
	button.add_to_group("scifi_buttons")
	button.pressed.connect(func() -> void: action_requested.emit(action))
	add_child(button)

func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var background := TextureRect.new()
	background.name = "CinematicHangar"
	background.position = Vector2.ZERO
	background.size = Vector2(1920,1080)
	background.texture = load(ART+"menu_backdrop.jpg")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	_rect(self,Vector2(0,0),Vector2(1920,4),CYAN.darkened(0.42))
	_rect(self,Vector2(76,68),Vector2(7,132),GOLD)
	_label(self,"傳奇倖存者",Vector2(96,55),Vector2(900,112),76,PAPER,true)
	_label(self,"LEGENDARY SURVIVOR   //   工業廢墟行動 / 科幻像素生存戰",Vector2(98,160),Vector2(930,37),22,CYAN)
	_rect(self,Vector2(98,204),Vector2(555,2),GOLD.darkened(0.22))
	for index in range(MENU.size()): _navigation_button(index)
	# Profile strip uses only actual local data; no invented online account, inbox or level.
	var profile := _panel(self,Vector2(1466,37),Vector2(390,108),Color(0.012,0.027,0.042,0.91),CYAN.darkened(0.18))
	_picture(profile,ART+"menu_icon_deploy.png",Vector2(16,16),Vector2(66,66))
	_label(profile,"本機指揮官",Vector2(99,14),Vector2(210,33),24,PAPER,true)
	_label(profile,"本機檔案  /  歷次成績 %d 筆" % scores.size(),Vector2(99,54),Vector2(270,26),17,MUTED)
	_small_action("open_settings","設定",Vector2(1751,100),Vector2(97,35))
	# Mech display annotation is decorative; all main art remains part of the background layer.
	var unit_card := _panel(self,Vector2(1410,653),Vector2(435,175),Color(0.012,0.025,0.039,0.91),CYAN.darkened(0.45))
	_rect(unit_card,Vector2(19,20),Vector2(4,130),GOLD)
	_label(unit_card,"UNIT // 1103",Vector2(40,14),Vector2(368,27),19,GOLD)
	_label(unit_card,"壁壘  ·  重裝型",Vector2(40,47),Vector2(365,52),29,PAPER,true)
	_label(unit_card,"重型裝甲 / 現役機體",Vector2(40,109),Vector2(370,32),19,MUTED)
	# Event card: actual currently available map, not a fictitious online promotion.
	var event_card := _panel(self,Vector2(78,866),Vector2(660,144),Color(0.024,0.048,0.067,0.93),GOLD.darkened(0.25))
	_rect(event_card,Vector2(0,0),Vector2(140,29),GOLD)
	_label(event_card,"任務簡報",Vector2(14,0),Vector2(133,28),17,Color("0c1a24"),true)
	_label(event_card,"工業廢墟  /  最終徵收者",Vector2(24,33),Vector2(600,48),29,PAPER,true)
	_label(event_card,"五階段生存戰・準備好裝備後即可出擊",Vector2(27,91),Vector2(590,38),19,MUTED)
	_small_action("open_loadout","查看任務 ›",Vector2(563,929),Vector2(160,53))
	# Updates panel contains only local milestone text. No external news or fake dates.
	var news := _panel(self,Vector2(1192,865),Vector2(654,146),Color(0.018,0.038,0.058,0.91),CYAN.darkened(0.22))
	_label(news,"本機更新  /  PROJECT STATUS",Vector2(18,7),Vector2(610,34),19,CYAN,true)
	_rect(news,Vector2(20,46),Vector2(607,1),CYAN.darkened(0.6))
	_label(news,"•  已加入地圖障礙物實體碰撞",Vector2(24,49),Vector2(610,27),17,PAPER)
	_label(news,"•  已更新科幻武器音效與打擊回饋",Vector2(24,77),Vector2(610,27),17,PAPER)
	_label(news,"•  主選單視覺改版（本機預覽）",Vector2(24,104),Vector2(610,27),17,MUTED)
	_label(self,"信用點  %d" % int(progress.get("credits",0)),Vector2(1546,1019),Vector2(315,40),25,GOLD,true)
	if not String(progress.get("save_error","")).is_empty():
		_label(self,String(progress.save_error),Vector2(764,979),Vector2(394,45),20,Color("f19076"))
	if not progress.get("pending",{}).is_empty():
		_small_action("retry_save","重試待保存結算",Vector2(767,929),Vector2(380,54))
