extends CanvasLayer
## Runtime textured UI. Game rules and persistence belong to the game modules.

signal deploy_requested(loadout: Dictionary)
signal upgrade_selected(id: String)
signal skill_requested(slot: int)
signal purchase_requested(key: String)
signal retry_save_requested
signal menu_requested
signal quit_requested
signal pause_requested
signal settings_changed(value: Dictionary)
signal tutorial_finished

const C = preload("res://scripts/scifi/ScifiConfig.gd")
const ART := "res://assets/sprites/ui/runtime/scifi/"
const GOLD := Color("e3ba6b")
const PAPER := Color("e9eee6")
const MUTED := Color("9aada9")
const CYAN := Color("77d9d1")
const RED := Color("f19076")
const WEAPON_ORDER := ["rail", "grenade", "blade", "arc", "thermal", "frost"]
const SKILL_ORDER := ["dash", "pulse", "shield", "repair"]
const META_ORDER := ["hp", "damage", "weapon_cd", "skill_cd"]
const META_NAMES := {"hp":"結構補強 / ARMOR", "damage":"火控升級 / FIREPOWER", "weapon_cd":"供彈最佳化 / RELOAD", "skill_cd":"戰術運算 / TACTICS"}
const SCREEN_EN := {"loadout":"LOADOUT", "meta":"PERMANENT UPGRADES", "scores":"RECORDS", "credits":"CREDITS", "upgrade":"COMBAT UPGRADES", "pause":"PAUSED", "settings":"SETTINGS", "tutorial":"TUTORIAL", "result":"RUN RESULTS", "confirm":"CONFIRM"}
const WEAPON_EN := {"rail":"RAILGUN","grenade":"GRENADE","blade":"BLADE","arc":"ARC","thermal":"THERMAL","frost":"FROST"}
const SKILL_EN := {"dash":"DASH","pulse":"EMP","shield":"SHIELD","repair":"REPAIR"}
const BUTTON_EN := {"返回":"BACK","返回整備":"BACK TO HANGAR","開始出擊":"DEPLOY","離開遊戲":"EXIT","繼續作戰":"RESUME","選擇改裝":"SELECT","下一步":"NEXT","開始整備":"LOADOUT","跳過引導":"SKIP","確認離開":"LEAVE","重試儲存":"RETRY SAVE","關閉動態":"REDUCE MOTION","正常動態":"FULL MOTION","音效與畫面":"SETTINGS","已滿級":"MAXED"}
const META_EFFECTS := {"hp":"每級最大耐久 +12%", "damage":"每級武器傷害 +10%", "weapon_cd":"每級武器冷卻 −5%", "skill_cd":"每級技能冷卻 −5%"}
const WEAPON_INFO := {"rail":"精準直射最近目標\n進化後可貫穿敵陣", "grenade":"自動轟擊密集敵群\n進化後散出集束子彈", "blade":"弧線迴旋，多次命中\n進化後以雙刃掃場", "arc":"連鎖打擊相鄰敵人\n進化後增加連鎖數", "thermal":"向近敵噴出短程火焰\n進化後延伸並熔穿敵陣", "frost":"光束命中並緩速\n進化後加寬並強化緩速"}
const SKILL_INFO := {"dash":"短距衝刺，期間無敵", "pulse":"癱瘓附近敵人，緩速首領", "shield":"限時吸收傷害", "repair":"恢復 25% 最大耐久"}
const MOD_INFO := {"firecontrol":"磁軌傷害每層 +12%\n三級可解鎖穿甲進化", "blast":"爆炸半徑每層 +15%\n三級可解鎖集束進化", "propulsion":"迴旋彈速每層 +12%\n三級可解鎖雙刃進化", "capacitor":"電弧連鎖每層 +1\n三級可解鎖電網進化", "heat":"熱能持續每層 +15%\n三級可解鎖熔穿進化", "cooling":"緩速每層 +10 百分點\n三級可解鎖極寒進化"}

var root: Control
var hud: Control
var popup: Control
var notice: Label
var current_screen := "menu"
var selected_weapon := "rail"
var selected_skills: Array = ["dash", "repair"]
var cached_progress: Dictionary = {}
var cached_scores: Array = []
var hp_value: Label
var xp_value: Label
var hp_bar: TextureProgressBar
var xp_bar: TextureProgressBar
var stage_label: Label
var timer_label: Label
var kills_label: Label
var weapon_tray: HBoxContainer
var skill_buttons: Array = []
var boss_panel: Control
var boss_bar: TextureProgressBar
var weapon_signature := ""
var notice_left := 0.0
var previous_hp := -1.0
var hp_hit_tween: Tween
var audio_options: Dictionary = {"music":0.65,"effects":0.8,"shake":0.8,"reduce_motion":false}
var settings_return_screen := "menu"
var tutorial_page := 0

func set_preferences(value: Dictionary) -> void:
	for key in ["music","effects","shake"]:
		audio_options[key] = clampf(float(value.get(key,audio_options[key])),0.0,1.0)
	audio_options["reduce_motion"] = bool(value.get("reduce_motion",false))


func _ready() -> void:
	add_to_group("scifi_ui")
	root = Control.new()
	root.name = "ScifiInterface"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft JhengHei", "Noto Sans CJK TC", "sans-serif"])
	theme.default_font = font
	theme.default_font_size = 25
	root.theme = theme
	add_child(root)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	_build_hud()
	popup = Control.new()
	popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(popup)
	notice = _label(root, "", Vector2(490, 985), Vector2(940, 72), 23, RED, HORIZONTAL_ALIGNMENT_CENTER)
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice.z_index = 100
	notice.visible = false

func _process(delta: float) -> void:
	if notice_left > 0:
		notice_left -= delta
		notice.visible = notice_left > 0

func _label(parent: Node, text: String, pos: Vector2, extent: Vector2, font_size := 25, color := PAPER, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = extent
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	parent.add_child(label)
	if not text.contains("\n"):
		var font: Font = label.get_theme_font("font")
		if font != null:
			var chosen := font_size
			while chosen > 15 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, chosen).x > extent.x - 8:
				chosen -= 1
			if chosen != font_size: label.add_theme_font_size_override("font_size",chosen)
	return label

func _panel(parent: Node, pos: Vector2, extent: Vector2, style := "panel") -> NinePatchRect:
	var panel := NinePatchRect.new()
	panel.texture = load(ART + style + ".png")
	panel.position = pos
	panel.size = extent
	panel.patch_margin_left = 16
	panel.patch_margin_right = 16
	panel.patch_margin_top = 16
	panel.patch_margin_bottom = 16
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel

func _image(parent: Node, path: String, pos: Vector2, extent: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = load(path)
	image.position = pos
	image.size = extent
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)
	return image

# UI-only motion: each control owns its tween so closing a popup also stops the animation.
func _button_hover(button: Button, hovered: bool) -> void:
	if not is_instance_valid(button): return
	var prior: Tween = button.get_meta("hover_motion") if button.has_meta("hover_motion") else null
	if prior != null and prior.is_running(): prior.kill()
	if button.disabled:
		button.modulate = Color.WHITE
		return
	var motion := button.create_tween()
	motion.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	motion.tween_property(button, "modulate", Color(1.08, 1.06, 0.98) if hovered else Color.WHITE, 0.14)
	button.set_meta("hover_motion", motion)

func _button_label(value: String) -> String:
	if BUTTON_EN.has(value): return value + " / " + String(BUTTON_EN[value])
	if value.begins_with("購買  "): return value + " / BUY"
	return value

func _button(parent: Node, text: String, pos: Vector2, extent: Vector2, callback: Callable, action := "", value: Variant = null) -> Button:
	var button := Button.new()
	button.text = _button_label(text)
	button.position = pos
	button.size = extent
	button.clip_text = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.set_meta("scifi_action", action)
	button.set_meta("scifi_value", value)
	button.add_to_group("scifi_buttons")
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := StyleBoxTexture.new()
		box.texture = load(ART + "button.png")
		box.texture_margin_left = 16
		box.texture_margin_right = 16
		box.texture_margin_top = 16
		box.texture_margin_bottom = 16
		box.modulate_color = Color(1.2, 1.2, 1.1) if state == "hover" else Color.WHITE
		if state == "pressed": box.modulate_color = CYAN
		if state == "disabled": box.modulate_color = Color(0.45, 0.45, 0.45)
		button.add_theme_stylebox_override(state, box)
	button.add_theme_color_override("font_color", PAPER)
	button.add_theme_color_override("font_hover_color", GOLD)
	button.add_theme_color_override("font_disabled_color", MUTED.darkened(0.3))
	button.add_theme_font_size_override("font_size", 20 if button.text != text else 25)
	button.pressed.connect(callback)
	button.pivot_offset = extent * 0.5
	button.mouse_entered.connect(func() -> void: _button_hover(button, true))
	button.mouse_exited.connect(func() -> void: _button_hover(button, false))
	button.focus_entered.connect(func() -> void: _button_hover(button, true))
	button.focus_exited.connect(func() -> void: _button_hover(button, false))
	parent.add_child(button)
	return button

func _bar(parent: Node, pos: Vector2, extent: Vector2, color: Color) -> TextureProgressBar:
	var bar := TextureProgressBar.new()
	bar.position = pos
	bar.size = extent
	bar.texture_under = load(ART + "bar_fill.png")
	bar.texture_progress = load(ART + "bar_fill.png")
	bar.tint_under = Color("263536")
	bar.tint_progress = color
	bar.nine_patch_stretch = true
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bar)
	return bar

func _build_hud() -> void:
	_panel(hud, Vector2(28, 24), Vector2(590, 205))
	_image(hud, "res://assets/sprites/scifi/units/1103/portrait.png", Vector2(48, 46), Vector2(138, 138))
	_label(hud, "壁壘  /  重灌型", Vector2(205, 43), Vector2(365, 35), 27, GOLD)
	hp_value = _label(hud, "耐久 / HP", Vector2(205, 82), Vector2(350, 27), 21)
	hp_bar = _bar(hud, Vector2(205, 118), Vector2(350, 17), RED)
	xp_value = _label(hud, "作戰經驗 / XP", Vector2(205, 142), Vector2(350, 28), 20, MUTED)
	xp_bar = _bar(hud, Vector2(205, 178), Vector2(350, 10), CYAN)
	_panel(hud, Vector2(722, 24), Vector2(476, 82))
	stage_label = _label(hud, "工業廢墟 / INDUSTRIAL RUINS", Vector2(742, 43), Vector2(436, 40), 27, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_panel(hud, Vector2(1475, 24), Vector2(415, 132))
	timer_label = _label(hud, "00:00", Vector2(1505, 42), Vector2(350, 46), 36, PAPER, HORIZONTAL_ALIGNMENT_RIGHT)
	kills_label = _label(hud, "擊破 / KILLS 0", Vector2(1505, 96), Vector2(350, 33), 23, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	weapon_tray = HBoxContainer.new()
	weapon_tray.position = Vector2(34, 242)
	weapon_tray.size = Vector2(585, 86)
	weapon_tray.add_theme_constant_override("separation", 10)
	hud.add_child(weapon_tray)
	for slot in range(2):
		var button := _button(hud, "", Vector2(667 + slot * 296, 942), Vector2(282, 104), func() -> void: skill_requested.emit(slot), "skill", slot)
		skill_buttons.append(button)
	boss_panel = _panel(hud, Vector2(650, 117), Vector2(620, 96))
	_label(boss_panel, "徵收者 / THE COLLECTOR", Vector2(30, 15), Vector2(560, 32), 23, RED, HORIZONTAL_ALIGNMENT_CENTER)
	boss_bar = _bar(boss_panel, Vector2(32, 56), Vector2(556, 14), RED)
	boss_panel.visible = false
	_label(hud, "WASD 移動 MOVE   Space / E 技能 SKILLS   Esc 暫停 PAUSE", Vector2(1240, 1003), Vector2(650, 45), 20, MUTED, HORIZONTAL_ALIGNMENT_RIGHT)

func _clear() -> void:
	for child in popup.get_children():
		popup.remove_child(child)
		child.queue_free()

func clear_popups() -> void:
	_clear()
	hud.visible = true
	current_screen = "playing"

func _screen(title: String, subtitle: String, extent: Vector2, screen: String) -> NinePatchRect:
	_clear()
	current_screen = screen
	hud.visible = screen in ["upgrade", "pause", "result", "confirm"]
	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.025, 0.03, 0.80 if screen in ["menu", "loadout", "meta", "scores", "credits"] else 0.65)
	dim.size = Vector2(1920, 1080)
	popup.add_child(dim)
	var panel := _panel(popup, (Vector2(1920,1080)-extent)/2, extent)
	_label(panel, title + "  /  " + String(SCREEN_EN.get(screen,"")), Vector2(52, 36), Vector2(extent.x-104, 65), 35, GOLD)
	_label(panel, subtitle, Vector2(52, 110), Vector2(extent.x-104, 42), 22, MUTED)
	return panel

func show_menu(progress: Dictionary, scores: Array = []) -> void:
	cached_progress = progress.duplicate(true)
	cached_scores = scores.duplicate(true)
	_clear()
	current_screen = "menu"
	hud.visible = false
	var args := OS.get_cmdline_user_args()
	# The separately named v3 Windows preview opens its candidate menu on double-click.
	# The regular game executable and Godot project keep the existing main menu.
	var preview_executable := OS.get_executable_path().get_file().to_lower().contains("cinematicmenu_v3_preview")
	var v3_preview := args.has("--menu-v3-preview") or args.has("--scifi-test=menu-v3") or args.has("--scifi-test=menu-v3-motion") or args.has("--scifi-test=menu-v3-perf") or preview_executable
	var menu_scene: PackedScene = preload("res://scenes/ui/ScifiMainMenuV3.tscn") if v3_preview else preload("res://scenes/ui/ScifiMainMenu.tscn")
	var view: Control = menu_scene.instantiate()
	if v3_preview: view.set("reduced_motion",bool(audio_options.get("reduce_motion",false)))
	view.name = "MainMenuView"
	popup.add_child(view)
	view.configure(cached_progress,cached_scores)
	view.action_requested.connect(_on_main_menu_action)
	if not String(progress.get("save_error","")).is_empty():
		show_notice(String(progress.get("save_error","")))

func _on_main_menu_action(action: String) -> void:
	match action:
		"open_loadout": show_loadout(cached_progress.get("loadout", {"weapon":"rail","skills":["dash","repair"]}))
		"open_meta": show_meta(cached_progress)
		"open_scores": show_scores()
		"open_settings": show_settings("menu")
		"tutorial": show_tutorial(0)
		"open_credits": show_credits()
		"quit": quit_requested.emit()
		"retry_save": retry_save_requested.emit()

func show_loadout(loadout: Dictionary) -> void:
	selected_weapon = String(loadout.get("weapon", "rail"))
	if not C.WEAPONS.has(selected_weapon): selected_weapon = "rail"
	selected_skills = loadout.get("skills", ["dash", "repair"]).duplicate()
	var panel := _screen("出擊整備", "選一把起始武器與兩個主動技能。局內最多裝備三把武器。", Vector2(1660, 948), "loadout")
	for index in range(6):
		var key: String = WEAPON_ORDER[index]
		var pos := Vector2(52 + (index%3)*520, 182 + (index/3)*182)
		var b := _button(panel, "", pos, Vector2(502, 164), func() -> void:
			show_loadout({"weapon":key,"skills":selected_skills}), "select_weapon", key)
		if key == selected_weapon: b.modulate = Color(1.2, 1.12, 0.76)
		_image(b, ART+"icon_"+key+".png", Vector2(20,35), Vector2(90,90))
		_label(b, ("◆ " if key==selected_weapon else "")+String(C.WEAPONS[key].name) + " / " + String(WEAPON_EN[key]), Vector2(128,21), Vector2(350,40), 22, GOLD if key==selected_weapon else PAPER)
		_label(b, WEAPON_INFO[key], Vector2(128,67), Vector2(350,72), 21, MUTED)
	_label(panel, "主動技能 / ACTIVE SKILLS · 選擇兩項", Vector2(52, 560), Vector2(700, 40), 28, CYAN)
	for index in range(4):
		var key: String = SKILL_ORDER[index]
		var b := _button(panel, "", Vector2(52+index*390,619), Vector2(372,160), func() -> void:
			var next := selected_skills.duplicate()
			if next.has(key): next.erase(key)
			elif next.size()<2: next.append(key)
			else:
				next.pop_front()
				next.append(key)
			show_loadout({"weapon":selected_weapon,"skills":next}), "select_skill", key)
		if selected_skills.has(key): b.modulate = Color(0.8,1.2,1.18)
		_image(b, ART+"icon_"+key+".png", Vector2(16,24), Vector2(72,72))
		var prefix := ""
		if selected_skills.has(key): prefix = ("Space  " if selected_skills.find(key)==0 else "E  ")
		_label(b, prefix+String(C.SKILLS[key].name) + " / " + String(SKILL_EN[key]), Vector2(102,23), Vector2(250,35), 21, CYAN if selected_skills.has(key) else PAPER)
		_label(b, SKILL_INFO[key], Vector2(18,110), Vector2(340,29), 19, MUTED)
	_label(panel, "8 分鐘迎戰最終首領，擊敗後通關。死亡也能帶回本局信用點。", Vector2(52, 801), Vector2(1040,55), 24, MUTED)
	_button(panel, "返回", Vector2(52,865), Vector2(260,58), func() -> void: menu_requested.emit(), "menu")
	var deploy := _button(panel, "開始出擊", Vector2(1260,842), Vector2(340,78), func() -> void:
		deploy_requested.emit({"weapon":selected_weapon,"skills":selected_skills.duplicate()}), "deploy")
	deploy.disabled = selected_skills.size()!=2

func show_meta(progress: Dictionary) -> void:
	cached_progress = progress.duplicate(true)
	var panel := _screen("永久改裝", "改裝效果保留至下次出擊；四項各有五級上限。", Vector2(1360, 900), "meta")
	_label(panel, "信用點 / CREDITS  %d" % int(progress.get("credits",0)), Vector2(905,55), Vector2(390,50), 30, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	var upgrades: Dictionary = progress.get("upgrades", {})
	for index in range(4):
		var key: String = META_ORDER[index]
		var current := int(upgrades.get(key,0))
		var y := 187.0+index*143
		_panel(panel, Vector2(48,y), Vector2(1264,125), "button")
		var icon_key: String = ["shield","rail","grenade","pulse"][index]
		_image(panel, ART+"icon_"+icon_key+".png", Vector2(72,y+23), Vector2(76,76))
		_label(panel, META_NAMES[key]+"  %d / 5"%current, Vector2(175,y+18), Vector2(570,44), 29, GOLD)
		_label(panel, META_EFFECTS[key], Vector2(175,y+67), Vector2(650,34), 22, MUTED)
		var cost := int(C.ECONOMY.prices[current]) if current<5 else 0
		var b := _button(panel, "已滿級" if current>=5 else "購買  %d"%cost, Vector2(963,y+29), Vector2(304,67), func() -> void: purchase_requested.emit(key), "purchase", key)
		b.disabled = current>=5 or int(progress.get("credits",0))<cost or not String(progress.get("save_error", "")).is_empty()
	_button(panel,"返回整備",Vector2(48,795),Vector2(320,70),func() -> void: menu_requested.emit(),"menu")
	_label(panel,"每次擊破與存活都能累積信用點。通關額外獲得 200 點。",Vector2(410,801),Vector2(860,52),22,MUTED,HORIZONTAL_ALIGNMENT_RIGHT)
	if not String(progress.get("save_error", "")).is_empty(): show_notice(String(progress.save_error))

func show_scores() -> void:
	var panel := _screen("歷次成績", "保留先前版本的本機成績紀錄。", Vector2(1160, 850), "scores")
	if cached_scores.is_empty(): _label(panel,"尚無成績。完成一次出擊，留下第一筆紀錄。",Vector2(60,270),Vector2(1040,80),30,MUTED,HORIZONTAL_ALIGNMENT_CENTER)
	for index in range(min(10,cached_scores.size())):
		var record: Dictionary = cached_scores[index]
		var text := "%02d    %s 分    擊破 %d    %s" % [index+1,str(record.get("score",0)),int(record.get("kills",0)),format_time(float(record.get("game_time",0)))]
		_label(panel,text,Vector2(75,186+index*48),Vector2(1010,44),26,PAPER)
	_button(panel,"返回",Vector2(70,733),Vector2(300,70),func() -> void: menu_requested.emit(),"menu")

func show_credits() -> void:
	var panel := _screen("製作資訊", "傳奇倖存者 / LEGENDARY SURVIVOR · v0.2", Vector2(1250, 800), "credits")
	_label(panel,"傳奇倖存者  /  LEGENDARY SURVIVOR",Vector2(70,186),Vector2(1090,65),33,GOLD)
	_label(panel,"本版開發與整合 / DEVELOPMENT & INTEGRATION",Vector2(70,267),Vector2(1090,35),23,MUTED)
	_label(panel,"LegendaryAni",Vector2(70,306),Vector2(1060,51),33,PAPER)
	_label(panel,"科幻戰鬥系統、機庫 UI、機甲待機動畫、作戰流程與音效設計\nCOMBAT SYSTEMS · HANGAR UI · MECH ANIMATION · AUDIO",Vector2(70,377),Vector2(1110,93),21,PAPER)
	_label(panel,"授權與素材來源  /  LICENSES & ACKNOWLEDGMENTS",Vector2(70,497),Vector2(1110,38),22,GOLD)
	_label(panel,"部分基礎程式源自 mewamew/huaizi-de-cows（原始 Git 作者：HexBlank）\nSome project foundations are adapted from mewamew/huaizi-de-cows.\n詳細來源 / Details: assets/sprites/scifi/README.md · assets/audio/LICENSES.md",Vector2(70,544),Vector2(1100,107),19,MUTED)
	_button(panel,"返回",Vector2(70,695),Vector2(300,65),func() -> void: menu_requested.emit(),"menu")

func update_hud(snapshot: Dictionary) -> void:
	var state := String(snapshot.get("state", "menu"))
	hud.visible = state in ["playing", "battle", "upgrade", "paused", "pause", "won", "lost", "result", "victory", "defeat"]
	var player: Dictionary = snapshot.get("player", {})
	var health := float(snapshot.get("hp",player.get("hp",120)))
	var maximum := maxf(1,float(snapshot.get("max_hp",player.get("max_hp",120))))
	if previous_hp >= 0.0 and health < previous_hp - 0.05 and state in ["playing", "battle"]:
		if hp_hit_tween != null and hp_hit_tween.is_running(): hp_hit_tween.kill()
		hp_bar.modulate = Color(1.0, 0.38, 0.30)
		hp_hit_tween = hp_bar.create_tween()
		hp_hit_tween.tween_property(hp_bar, "modulate", Color.WHITE, 0.42).set_trans(Tween.TRANS_SINE)
	previous_hp = health
	hp_value.text = "耐久 / HP  %d / %d"%[ceili(health),ceili(maximum)]
	hp_bar.value = clampf(100*health/maximum,0,100)
	var experience := int(snapshot.get("xp",0))
	var needed := maxi(1,int(snapshot.get("xp_needed",snapshot.get("xp_required",25))))
	xp_value.text = "等級 / LV %d    經驗 / XP %d / %d"%[int(snapshot.get("level",1)),experience,needed]
	xp_bar.value = clampf(100.0*experience/needed,0,100)
	timer_label.text = format_time(float(snapshot.get("time",0)))
	kills_label.text = "擊破 / KILLS %d    信用點 / CREDITS %d"%[int(snapshot.get("kills",0)),int(snapshot.get("credits",snapshot.get("run_credits",0)))]
	var phase := int(snapshot.get("stage",0))
	stage_label.text = "最終交戰 / BOSS: COLLECTOR" if phase>=4 else "工業廢墟 / PHASE %d"%(phase+1)
	var weapons: Dictionary = snapshot.get("weapons",{})
	# Cooldowns vary every tick; tray changes only when levels or evolutions change.
	var stable := ""
	for key in weapons: stable += "%s:%s:%s;"%[key,weapons[key].get("level",1),weapons[key].get("evolved",false)]
	if stable != weapon_signature:
		weapon_signature = stable
		for child in weapon_tray.get_children():
			weapon_tray.remove_child(child)
			child.queue_free()
		for key in weapons:
			var cell := Control.new()
			cell.custom_minimum_size = Vector2(185,82)
			weapon_tray.add_child(cell)
			_panel(cell,Vector2.ZERO,Vector2(185,82),"button")
			_image(cell,ART+"icon_"+String(key)+".png",Vector2(12,14),Vector2(51,51))
			_label(cell,("進化" if weapons[key].get("evolved",false) else "Lv.%d"%int(weapons[key].get("level",1))),Vector2(76,14),Vector2(98,51),23,GOLD)
	var equipped: Array = snapshot.get("skills",[])
	for index in range(2):
		var button: Button = skill_buttons[index]
		if index>=equipped.size():
			button.visible=false
			continue
		button.visible=true
		var skill: Dictionary = equipped[index]
		var key := String(skill.get("key","dash"))
		var remaining := float(skill.get("remaining",0))
		button.text = ("Space  " if index==0 else "E  ")+String(C.SKILLS[key].name)+("  %.1fs"%remaining if remaining>0 else "  就緒")
		button.modulate = Color(0.6,0.7,0.72) if remaining>0 else Color.WHITE
	var boss: Dictionary = snapshot.get("boss",{})
	boss_panel.visible = float(boss.get("max_hp",0))>0 and float(boss.get("hp",0))>0
	if boss_panel.visible: boss_bar.value=100*float(boss.hp)/maxf(1,float(boss.max_hp))

func show_upgrade(options: Array) -> void:
	_clear()
	current_screen = "upgrade"
	hud.visible=true
	var dim := ColorRect.new()
	dim.color=Color(0.015,0.025,0.03,0.76)
	dim.size=Vector2(1920,1080)
	popup.add_child(dim)
	_label(popup,"選擇作戰改裝",Vector2(370,150),Vector2(1180,80),46,GOLD,HORIZONTAL_ALIGNMENT_CENTER)
	_label(popup,"戰鬥已暫停，選擇後立即生效。",Vector2(370,228),Vector2(1180,45),25,MUTED,HORIZONTAL_ALIGNMENT_CENTER)
	var count := mini(3,options.size())
	var total := count*360.0+(count-1)*34.0
	for index in range(count):
		var card: Dictionary=options[index]
		var id := String(card.get("id",""))
		var key := String(card.get("key","rail"))
		var kind := String(card.get("kind",card.get("type","weapon")))
		var panel:=_panel(popup,Vector2((1920-total)/2+index*394,319),Vector2(360,572),"card")
		var heading:= "進化改裝" if kind in ["evolve","evolution"] else ("武器系統" if kind in ["weapon","new","upgrade"] else "作戰模組")
		_label(panel,heading,Vector2(29,29),Vector2(302,34),22,CYAN,HORIZONTAL_ALIGNMENT_CENTER)
		var icon := ART+"icon_"+key+".png"
		if not ResourceLoader.exists(icon):
			var matched := "pulse"
			for weapon in WEAPON_ORDER:
				if C.WEAPONS[weapon].mod == key: matched=weapon
			icon=ART+"icon_"+matched+".png"
		_image(panel,icon,Vector2(90,88),Vector2(180,180))
		var title:=String(card.get("title",card.get("name",C.WEAPONS.get(key,{}).get("name",C.MODS.get(key,"補給")))))
		_label(panel,title,Vector2(24,287),Vector2(312,55),30,GOLD,HORIZONTAL_ALIGNMENT_CENTER)
		var rank := int(card.get("level",1))
		var tier := ""
		if kind=="weapon": tier="新武器  /  等級 1・上限 5"
		elif kind=="upgrade": tier="等級 %d → %d  /  上限 5"%[rank-1,rank]
		elif kind=="mod": tier="層數 %d → %d  /  上限 3"%[rank-1,rank]
		elif kind in ["evolve","evolution"]: tier="武器 5 / 5 ＋ 對應改裝 3 / 3"
		_label(panel,tier,Vector2(22,340),Vector2(316,30),19,CYAN,HORIZONTAL_ALIGNMENT_CENTER)
		var description:=String(card.get("description",card.get("desc","強化本次出擊的作戰能力。")))
		if kind=="mod": description=MOD_INFO.get(key,description)
		elif kind=="weapon": description=WEAPON_INFO.get(key,description)
		elif kind=="upgrade": description="傷害 ×1.35\n發射冷卻 ×0.90"
		var info:=_label(panel,description,Vector2(30,380),Vector2(300,86),23,PAPER,HORIZONTAL_ALIGNMENT_CENTER)
		info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		_button(panel,"選擇改裝",Vector2(34,480),Vector2(292,61),func() -> void: upgrade_selected.emit(id),"choose_card",id)

func show_pause() -> void:
	var panel:=_screen("作戰暫停","戰鬥、刷怪與技能冷卻已停止。",Vector2(790,590),"pause")
	_button(panel,"繼續作戰",Vector2(65,182),Vector2(660,72),func() -> void: pause_requested.emit(),"resume")
	_button(panel,"音效與畫面",Vector2(65,277),Vector2(660,72),func() -> void: show_settings("pause"),"open_settings")
	_button(panel,"返回整備",Vector2(65,372),Vector2(660,72),func() -> void: menu_requested.emit(),"menu")
	_button(panel,"離開遊戲",Vector2(65,467),Vector2(660,72),func() -> void: quit_requested.emit(),"quit")

func show_settings(origin: String = "menu") -> void:
	settings_return_screen = origin
	var panel := _screen("音效與畫面", "調整背景音樂、音效、震屏與選單動態效果。", Vector2(1010,740), "settings")
	var labels := {"music":"背景音樂 / MUSIC","effects":"音效音量 / SFX","shake":"畫面震動 / SHAKE"}
	for index in range(3):
		var key: String = ["music","effects","shake"][index]
		var y := 206.0 + index * 109
		_label(panel,labels[key],Vector2(65,y),Vector2(380,50),28,PAPER)
		_button(panel,"−",Vector2(510,y-4),Vector2(92,62),func() -> void: _adjust_option(key,-0.1), "adjust_"+key+"_down")
		_label(panel,"%d%%" % roundi(100*float(audio_options[key])),Vector2(621,y-4),Vector2(128,62),29,CYAN,HORIZONTAL_ALIGNMENT_CENTER)
		_button(panel,"＋",Vector2(785,y-4),Vector2(92,62),func() -> void: _adjust_option(key,0.1), "adjust_"+key+"_up")
	_label(panel,"減少動態效果 / REDUCE MOTION",Vector2(65,533),Vector2(445,55),23,PAPER)
	_button(panel,"關閉動態" if bool(audio_options.get("reduce_motion",false)) else "正常動態",Vector2(510,532),Vector2(367,61),func() -> void: _toggle_reduced_motion(),"toggle_reduce_motion")
	_label(panel,"隻影響主選單動畫，不改戰鬥判定或數值。",Vector2(65,613),Vector2(860,33),20,MUTED)
	_button(panel,"返回",Vector2(65,654),Vector2(270,65),func() -> void:
		if settings_return_screen == "pause": show_pause()
		else: show_menu(cached_progress,cached_scores), "close_settings")

func _toggle_reduced_motion() -> void:
	audio_options["reduce_motion"] = not bool(audio_options.get("reduce_motion",false))
	settings_changed.emit(audio_options.duplicate())
	show_settings(settings_return_screen)

func _adjust_option(key: String, amount: float) -> void:
	audio_options[key] = clampf(snappedf(float(audio_options[key]) + amount,0.1),0.0,1.0)
	settings_changed.emit(audio_options.duplicate())
	show_settings(settings_return_screen)

func show_tutorial(page: int = 0) -> void:
	tutorial_page = clampi(page,0,2)
	var panel := _screen("行動指引 / TUTORIAL  %d / 3" % (tutorial_page+1), "每一步都可以重新從主選單檢視。",Vector2(1060,790),"tutorial")
	var title: String = ["01  出擊整備 / DEPLOY","02  自動交戰 / COMBAT","03  升級與成長 / UPGRADES"][tutorial_page]
	var copy: String = ["選擇一把起始武器，再挑選兩個主動技能。\n六把武器有不同攻擊方式，出擊後仍會獲得新武器。","用 WASD 或方向鍵閃避敵人。武器自動尋找目標。\nSpace 和 E 是已選技能；下方按鈕會顯示冷卻時間。","收集藍色經驗晶體以提升等級。戰鬥暫停時選擇改裝卡。\n被擊敗也能保留信用點，再到「永久改裝」升級。"][tutorial_page]
	var icon: String = ["rail","dash","shield"][tutorial_page]
	_image(panel,ART+"icon_"+icon+".png",Vector2(70,190),Vector2(240,240))
	_label(panel,title,Vector2(355,198),Vector2(625,69),39,GOLD)
	var description := _label(panel,copy,Vector2(355,292),Vector2(615,235),27,PAPER)
	description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_button(panel,"跳過引導",Vector2(74,645),Vector2(300,73),_complete_tutorial,"skip_tutorial")
	_button(panel,"開始整備" if tutorial_page==2 else "下一步",Vector2(690,645),Vector2(300,73),func() -> void:
		if tutorial_page < 2: show_tutorial(tutorial_page+1)
		else:
			_complete_tutorial()
			show_loadout(cached_progress.get("loadout",{"weapon":"rail","skills":["dash","repair"]})), "next_tutorial")

func _complete_tutorial() -> void:
	tutorial_finished.emit()
	show_menu(cached_progress,cached_scores)

func show_result(summary: Dictionary) -> void:
	var won: bool = bool(summary.get("won",summary.get("victory",false))) or String(summary.get("result","")) in ["victory","win","won"]
	var saved: bool = String(summary.get("save_error","")).is_empty() and summary.get("saved",true)!=false
	if saved: show_notice("")
	var panel:=_screen("任務完成" if won else "機體失聯","收益已帶回。調整配裝與永久改裝，再次出擊。" if saved else "收益尚未儲存，請保留視窗並重試。",Vector2(1100,850),"result")
	var lines: Array = [
		["存活時間 / SURVIVAL",format_time(float(summary.get("time",summary.get("game_time",0))))],
		["擊破敵人 / KILLS",str(summary.get("kills",0))],
		["作戰等級 / LEVEL",str(summary.get("level",1))],
		["本局信用點 / CREDITS",str(summary.get("credits",summary.get("reward",summary.get("run_credits",0))))],
		["儲存狀態 / SAVED","等待重試" if not String(summary.get("save_error","")).is_empty() or summary.get("saved",true)==false else "已儲存"]]
	for index in range(lines.size()):
		_label(panel,String(lines[index][0]),Vector2(75,205+index*77),Vector2(480,52),28,MUTED)
		_label(panel,String(lines[index][1]),Vector2(560,205+index*77),Vector2(465,52),30,GOLD,HORIZONTAL_ALIGNMENT_RIGHT)
	if not String(summary.get("save_error","")).is_empty() or summary.get("saved",true)==false:
		_button(panel,"重試儲存",Vector2(75,637),Vector2(950,70),func() -> void: retry_save_requested.emit(),"retry_save")
	_button(panel,"返回整備",Vector2(75,745),Vector2(440,66),func() -> void: menu_requested.emit(),"menu")
	_button(panel,"離開遊戲",Vector2(585,745),Vector2(440,66),func() -> void: quit_requested.emit(),"quit")

func show_confirm(message: String, accept: Callable) -> void:
	var panel:=_screen("離開本次出擊？", "本版不儲存進行中的戰局。",Vector2(950,530),"confirm")
	var text:=_label(panel,message,Vector2(62,177),Vector2(826,140),28,PAPER)
	text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_button(panel,"繼續作戰",Vector2(62,373),Vector2(385,77),func() -> void:
		pause_requested.emit(),"cancel_leave")
	_button(panel,"確認離開",Vector2(500,373),Vector2(385,77),accept,"confirm_leave")

func show_notice(message: String) -> void:
	if notice==null: return
	notice.text=message
	notice.visible=not message.is_empty()
	notice_left=9.0 if notice.visible else 0.0

func format_time(seconds: float) -> String:
	var whole:=maxi(0,int(seconds))
	return "%02d:%02d"%[whole/60,whole%60]
