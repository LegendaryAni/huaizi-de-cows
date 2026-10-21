extends Control
## Menu v2: authored industrial command terminal. All actions delegate to ScifiUI.
signal action_requested(action: String)

const ART := "res://assets/sprites/ui/runtime/scifi/"
const INK := Color("10191d")
const WHITE := Color("edf0e7")
const DUST := Color("a7b1aa")
const AMBER := Color("d5a56e")
const TEAL := Color("739a9b")
const ACTIONS := ["open_loadout","open_meta","open_scores","open_settings","tutorial","open_credits","quit"]
const GLYPHS := ["deploy","workshop","records","settings","tutorial","credits","quit"]
const LABELS := ["出擊整備","永久改裝","歷次成績","音效與畫面","操作教學","製作資訊","離開遊戲"]

var progress: Dictionary = {}
var scores: Array = []

func configure(value: Dictionary, history: Array) -> void:
	progress = value.duplicate(true)
	scores = history.duplicate(true)
	if is_node_ready(): _rebuild()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_rebuild()

func _label(parent: Node, value: String, pos: Vector2, extent: Vector2, size_value: int, color := WHITE) -> Label:
	var item := Label.new()
	item.position = pos
	item.size = extent
	item.text = value
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_theme_font_size_override("font_size", size_value)
	item.add_theme_color_override("font_color",color)
	parent.add_child(item)
	return item

func _strip(parent: Node, pos: Vector2, extent: Vector2, color: Color) -> ColorRect:
	var item := ColorRect.new()
	item.position = pos
	item.size = extent
	item.color = color
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

func _image(parent: Node, path: String, pos: Vector2, extent: Vector2, linear := false) -> TextureRect:
	var item := TextureRect.new()
	item.texture = load(path)
	item.position = pos
	item.size = extent
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if linear else CanvasItem.TEXTURE_FILTER_NEAREST
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

func _style(background: Color, outline: Color, primary: bool, focus := false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = background
	sb.border_color = outline
	sb.border_width_bottom = 1
	sb.border_width_top = 1 if primary else 0
	sb.border_width_left = 5 if primary else 2
	sb.border_width_right = 1 if primary else 0
	if focus: sb.set_corner_radius_all(2)
	sb.content_margin_left = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	sb.content_margin_right = 0
	return sb

func _interactive(action: String, pos: Vector2, extent: Vector2, mode: int = 0) -> Button:
	var button := Button.new()
	button.name = "Command_" + action
	button.text = ""
	button.position = pos
	button.size = extent
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.set_meta("scifi_action",action)
	button.set_meta("scifi_value",null)
	button.add_to_group("scifi_buttons")
	if mode == 0:
		button.add_theme_stylebox_override("normal",_style(Color("3a3028"),AMBER,true))
		button.add_theme_stylebox_override("hover",_style(Color("52402f"),Color("efd09a"),true))
		button.add_theme_stylebox_override("pressed",_style(Color("241e1a"),Color("f4d49b"),true))
		button.add_theme_stylebox_override("focus",_style(Color("423229"),WHITE,true,true))
	elif mode == 1:
		button.add_theme_stylebox_override("normal",_style(Color("131c21"),Color("38474a"),false))
		button.add_theme_stylebox_override("hover",_style(Color("253234"),AMBER,false))
		button.add_theme_stylebox_override("pressed",_style(Color("302c25"),AMBER,false))
		button.add_theme_stylebox_override("focus",_style(Color("233239"),TEAL,false,true))
	else:
		button.add_theme_stylebox_override("normal",_style(Color(0.06,0.09,0.10,0.70),Color("415255"),false))
		button.add_theme_stylebox_override("hover",_style(Color("253034"),AMBER,false))
		button.add_theme_stylebox_override("pressed",_style(Color("2d2d2a"),AMBER,false))
		button.add_theme_stylebox_override("focus",_style(Color("253034"),WHITE,false,true))
	button.pressed.connect(func() -> void: action_requested.emit(action))
	button.mouse_entered.connect(func() -> void: _hover(button,true))
	button.mouse_exited.connect(func() -> void: _hover(button,false))
	button.focus_entered.connect(func() -> void: _hover(button,true))
	button.focus_exited.connect(func() -> void: _hover(button,false))
	add_child(button)
	return button

func _hover(button: Button, over: bool) -> void:
	if not is_instance_valid(button): return
	var old: Tween = button.get_meta("menu_tween") if button.has_meta("menu_tween") else null
	if old != null and old.is_running(): old.kill()
	var animation := button.create_tween()
	animation.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	animation.tween_property(button, "position:x", float(button.get_meta("home_x")) + (5.0 if over else 0.0), 0.12)
	button.set_meta("menu_tween",animation)

func _attach_text(button: Button, index: int, primary: bool) -> void:
	var action: String = ACTIONS[index]
	_image(button,ART+"menu_icon_"+GLYPHS[index]+".png",Vector2(17,14) if primary else Vector2(19,9),Vector2(56,56) if primary else Vector2(39,39))
	var x := 95.0 if primary else 85.0
	var y := 6.0 if primary else 7.0
	_label(button,LABELS[index],Vector2(x,y),Vector2(button.size.x-x-53,52),35 if primary else 25, WHITE)
	if primary:
		_label(button,"進入作戰整備",Vector2(x,54),Vector2(285,28),17,Color("e0c39b"))
		_label(button,"→",Vector2(button.size.x-76,19),Vector2(52,56),35,AMBER)
	else:
		_label(button,"›",Vector2(button.size.x-49,2),Vector2(42,60),31,Color("97a09b"))

func _entry(index: int, pos: Vector2, extent: Vector2, mode: int) -> void:
	var b := _interactive(ACTIONS[index],pos,extent,mode)
	b.set_meta("home_x",pos.x)
	if mode == 2:
		_image(b,ART+"menu_icon_"+GLYPHS[index]+".png",Vector2(15,12),Vector2(28,28))
		_label(b,LABELS[index],Vector2(53,6),Vector2(extent.x-63,50),19,DUST)
	else:
		_attach_text(b,index,mode==0)
	# Restrained one-time reveal: not a synchronized cascade of identical cards.
	b.modulate.a = 0.0
	var fade := b.create_tween()
	fade.tween_property(b,"modulate:a",1.0,0.24)

func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	# The 1103 sprite is an independent NEAREST-filtered layer, never JPG-compressed.
	var environment := TextureRect.new()
	environment.name = "MaintenanceBay"
	environment.texture = load(ART+"menu_backdrop_v2.jpg")
	environment.position = Vector2.ZERO
	environment.size = Vector2(1920,1080)
	environment.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	environment.stretch_mode = TextureRect.STRETCH_SCALE
	environment.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	environment.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(environment)
	_image(self,ART+"menu_mech_shadow.png",Vector2(918,680),Vector2(570,135),true)
	var mech := _image(self,ART+"menu_mech_1103.png",Vector2(1010,361),Vector2(370,365))
	mech.name = "MainUnit1103"
	# Art remains authentic pixel art. Subtle float gives it life without blur.
	var float_tween := mech.create_tween().set_loops()
	float_tween.tween_property(mech,"position:y",357.0,2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(mech,"position:y",361.0,2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_strip(self,Vector2(80,68),Vector2(5,95),AMBER)
	_label(self,"傳奇倖存者",Vector2(101,64),Vector2(770,86),67,WHITE)
	_label(self,"前線終端  /  工業廢墟行動",Vector2(106,161),Vector2(630,39),22,DUST)
	_strip(self,Vector2(104,208),Vector2(525,1),Color("686b5f"))
	_label(self,"01   出擊任務",Vector2(103,241),Vector2(520,27),17,AMBER)
	_entry(0,Vector2(101,281),Vector2(537,101),0)

	_label(self,"作戰支援",Vector2(106,418),Vector2(235,35),19,DUST)
	_strip(self,Vector2(107,461),Vector2(520,1),Color("455153"))
	for k in range(1,5):
		_entry(k,Vector2(101,472+(k-1)*69),Vector2(522,62),1)
	_label(self,"系統",Vector2(107,750),Vector2(180,31),18,Color("8c9996"))
	_strip(self,Vector2(107,786),Vector2(520,1),Color("455153"))
	_entry(5,Vector2(101,803),Vector2(317,55),2)
	_entry(6,Vector2(430,803),Vector2(197,55),2)

	# A quiet legibility scrim is integrated into the girder, not another floating card.
	_strip(self,Vector2(1486,48),Vector2(360,148),Color(0.035,0.060,0.069,0.88))
	# Unboxed header shows real local status, not a fabricated online avatar.
	_strip(self,Vector2(1504,66),Vector2(4,87),AMBER)
	_label(self,"本機檔案",Vector2(1523,62),Vector2(300,42),24,WHITE)
	_label(self,"作戰紀錄  %d 筆" % scores.size(),Vector2(1525,108),Vector2(300,29),18,DUST)
	_label(self,"信用點   %d" % int(progress.get("credits",0)),Vector2(1525,145),Vector2(315,32),22,AMBER)

	# Short machine identification, no generic stand-alone hero status card.
	_strip(self,Vector2(1478,697),Vector2(65,2),AMBER)
	_label(self,"壁壘  /  1103",Vector2(1463,706),Vector2(405,48),30,WHITE)
	_label(self,"重裝型 · 前線機體",Vector2(1465,755),Vector2(405,31),18,DUST)

	# One integrated footer, made of real battle terminology instead of faux news.
	_strip(self,Vector2(0,917),Vector2(1920,163),Color("0b1318cc"))
	_strip(self,Vector2(101,947),Vector2(4,92),AMBER)
	_label(self,"本次行動",Vector2(125,947),Vector2(190,31),19,AMBER)
	_label(self,"工業廢墟",Vector2(125,977),Vector2(355,56),38,WHITE)
	_strip(self,Vector2(580,952),Vector2(1,86),Color("526064"))
	_label(self,"最終目標",Vector2(612,951),Vector2(260,30),17,DUST)
	_label(self,"擊敗徵收者",Vector2(609,984),Vector2(375,45),27,WHITE)
	_strip(self,Vector2(1028,952),Vector2(1,86),Color("526064"))
	_label(self,"出擊前請選定主武器與兩項技能",Vector2(1056,962),Vector2(700,56),23,DUST)
	_label(self,"開發預覽  v0.2",Vector2(1596,1028),Vector2(267,30),17,Color("819392"))

	if not String(progress.get("save_error","")).is_empty():
		_label(self,String(progress.get("save_error","")),Vector2(780,864),Vector2(815,43),21,Color("f0ab88"))
	if not progress.get("pending",{}).is_empty():
		var save_button := _interactive("retry_save",Vector2(1026,839),Vector2(320,58),2)
		save_button.set_meta("home_x",1026.0)
		_label(save_button,"重試待儲存結算",Vector2(25,7),Vector2(285,44),23,AMBER)
