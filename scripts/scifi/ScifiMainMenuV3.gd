extends Control
## Cinematic main menu v3 - opt-in preview. All real actions delegate to ScifiUI.
signal action_requested(action: String)

const ART := "res://assets/sprites/ui/runtime/scifi/"
const INK := Color("0a1520")
const PAPER := Color("edf2ed")
const MUTED := Color("a7b9c1")
const GOLD := Color("efba70")
const BLUE := Color("8ad6eb")
const ACTIONS := ["open_loadout","open_meta","open_scores","open_settings","tutorial","open_credits","quit"]
const ICONS := ["deploy","workshop","records","settings","tutorial","credits","quit"]
const NAMES := ["出擊整備","永久改裝","歷次成績","音效與畫面","操作教學","製作資訊","離開遊戲"]
const EN_NAMES := ["DEPLOY","WORKSHOP","RECORDS","SETTINGS","TUTORIAL","CREDITS","EXIT"]

@onready var environment: Control = $Environment
@onready var hero_display: Control = $HeroDisplay
@onready var main_ui: Control = $MainUI
@onready var animator: AnimationPlayer = $Animations
@onready var transition_layer: ColorRect = $TransitionLayer
var progress: Dictionary = {}
var scores: Array = []
var transitioning := false
var reduced_motion := false
var far_layer: TextureRect
var mid_layer: TextureRect
var near_layer: TextureRect
var rays: TextureRect
var crane: TextureRect
var nav: VBoxContainer
var hero: TextureRect
var main_actions: Array[Button] = []

func configure(value: Dictionary, history: Array) -> void:
	progress = value.duplicate(true)
	scores = history.duplicate(true)
	if is_node_ready(): _populate_data()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	reduced_motion = reduced_motion or OS.get_cmdline_user_args().has("--reduce-motion")
	_build_environment()
	_build_hero()
	_build_ui()
	_build_cycle()
	_populate_data()
	_play_intro()
	set_process(not reduced_motion)

func _exit_tree() -> void:
	if animator: animator.stop()
	# create_tween() is bound to the originating node, so child cleanup aborts callbacks.
	set_process(false)

func _process(_delta: float) -> void:
	if transitioning: return
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var offset: Vector2 = Vector2(clampf((mouse.x - 960.0) / 960.0, -1.0, 1.0), clampf((mouse.y - 540.0) / 540.0, -1.0, 1.0))
	if far_layer:
		far_layer.position = Vector2(-9.0,-7.0) + offset * 2.5
	if mid_layer:
		mid_layer.position = Vector2(-9.0,-7.0) - offset * 5.0
	if near_layer:
		near_layer.position = -offset * 7.0

func _image(parent: Node, name: String, file: String, at: Vector2, extent: Vector2, linear: bool = false) -> TextureRect:
	var item := TextureRect.new()
	item.name = name
	item.texture = load(ART + file)
	item.position = at
	item.size = extent
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.stretch_mode = TextureRect.STRETCH_SCALE
	item.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if linear else CanvasItem.TEXTURE_FILTER_NEAREST
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

func _label(parent: Node, text: String, at: Vector2, extent: Vector2, font_size: int, color: Color = PAPER, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var item := Label.new()
	item.text = text
	item.position = at
	item.size = extent
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item.horizontal_alignment = align
	item.clip_text = true
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_theme_font_size_override("font_size",font_size)
	item.add_theme_color_override("font_color",color)
	parent.add_child(item)
	return item

func _build_environment() -> void:
	far_layer = _image(environment,"HangarFar","v3_hangar_far.jpg",Vector2(-9,-7),Vector2(1938,1094),true)
	mid_layer = _image(environment,"HangarMid","v3_hangar_mid.png",Vector2(-9,-7),Vector2(1938,1094),true)
	rays = _image(environment,"LightRays","v3_light_rays.png",Vector2.ZERO,Vector2(1920,1080),true)
	rays.modulate.a = 0.48
	crane = _image(environment,"HangarCrane","v3_crane.png",Vector2(1315,20),Vector2(530,175),true)
	var dust := GPUParticles2D.new()
	dust.name = "HangarDust"
	dust.texture = load(ART + "v3_dust.png")
	dust.amount = 28
	dust.lifetime = 11.0
	dust.speed_scale = 0.45
	dust.position = Vector2(1310,525)
	dust.visibility_rect = Rect2(-650,-460,1280,930)
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(520.0,350.0,0.0)
	material.gravity = Vector3(0.0,-2.0,0.0)
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 6.0
	material.scale_min = 0.6
	material.scale_max = 1.2
	dust.process_material = material
	dust.emitting = not reduced_motion
	environment.add_child(dust)

func _build_hero() -> void:
	_image(hero_display,"MechShadow","menu_mech_shadow.png",Vector2(1065,753),Vector2(790,190),true)
	var hero_rig := Node2D.new()
	hero_rig.name = "HeroRig"
	hero_rig.position = Vector2(830,-30)
	hero_rig.scale = Vector2.ONE * 0.66
	hero_rig.set_script(preload("res://scripts/scifi/MechIdleController.gd"))
	hero_display.add_child(hero_rig)
	hero_rig.set_reduced_motion(reduced_motion)
	# Independent high-resolution original limbs are driven by real joint pivots.
	_image(hero_display,"HeroGlow","v3_light_rays.png",Vector2(870,90),Vector2(870,830),true).modulate.a = 0.10
	near_layer = _image(hero_display,"ForegroundRails","v3_hangar_fore.png",Vector2.ZERO,Vector2(1920,1080),true)
	_label(hero_display,"壁壘  /  1103",Vector2(1518,747),Vector2(315,43),30,PAPER)
	_label(hero_display,"重裝型 · 前線待命",Vector2(1520,788),Vector2(315,31),18,MUTED)

func _make_navigation_button(action: String, caption: String, icon: String, kind: String, width: float, height: float) -> Button:
	var button := Button.new()
	button.name = "Command_" + action
	button.text = ""
	button.custom_minimum_size = Vector2(width,height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.focus_mode = Control.FOCUS_ALL
	button.set_meta("scifi_action",action)
	button.set_meta("scifi_value",null)
	button.set_meta("visual_kind",kind)
	button.add_to_group("scifi_buttons")
	var transparent := StyleBoxEmpty.new()
	for key in ["normal","hover","pressed","focus"]:
		button.add_theme_stylebox_override(key,transparent)
	var bg := _image(button,"ButtonArt","v3_"+kind+"_base.png",Vector2.ZERO,Vector2(width,height),true)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var content := MarginContainer.new()
	content.name = "ButtonContent"
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("margin_left",23)
	content.add_theme_constant_override("margin_right",23)
	content.add_theme_constant_override("margin_top",5 if kind=="utility" else 7)
	content.add_theme_constant_override("margin_bottom",5 if kind=="utility" else 7)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation",17)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(line)
	var glyph := TextureRect.new()
	glyph.name = "Glyph"
	glyph.texture = load(ART+"menu_icon_"+icon+".png")
	var icon_side := 59.0 if kind == "primary" else (37.0 if kind == "utility" else 45.0)
	glyph.custom_minimum_size = Vector2(icon_side,icon_side)
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(glyph)
	var title_area := VBoxContainer.new()
	title_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_area.alignment = BoxContainer.ALIGNMENT_CENTER
	title_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(title_area)
	var title := Label.new()
	title.text = caption
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",32 if kind=="primary" else (18 if kind=="utility" else 26))
	title.add_theme_color_override("font_color",PAPER)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_area.add_child(title)
	var subtitle := Label.new()
	subtitle.name = "EnglishLabel"
	subtitle.text = EN_NAMES[ACTIONS.find(action)]
	subtitle.add_theme_font_size_override("font_size",14 if kind=="primary" else (10 if kind=="utility" else 13))
	subtitle.add_theme_color_override("font_color", GOLD if kind=="primary" else BLUE)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_area.add_child(subtitle)
	if kind!="utility":
		var arrow := Label.new()
		arrow.name="Indicator"
		arrow.text = "›"
		arrow.add_theme_font_size_override("font_size",35)
		arrow.add_theme_color_override("font_color",GOLD if kind=="primary" else MUTED)
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(arrow)
	button.mouse_entered.connect(func() -> void: _focus_button(button,true))
	button.mouse_exited.connect(func() -> void: _focus_button(button,false))
	button.focus_entered.connect(func() -> void: _focus_button(button,true))
	button.focus_exited.connect(func() -> void: _focus_button(button,false))
	button.pressed.connect(func() -> void: _request_action(action))
	main_actions.append(button)
	return button

func _focus_button(button: Button, active: bool) -> void:
	if not is_instance_valid(button): return
	var kind: String = String(button.get_meta("visual_kind"))
	var back: TextureRect = button.get_node("ButtonArt")
	back.texture = load(ART+"v3_"+kind+"_"+("hover" if active else "base")+".png")
	var glyph: TextureRect = button.get_node("ButtonContent").find_child("Glyph",true,false) as TextureRect
	if glyph:
		var old: Tween = glyph.get_meta("glyph_anim") if glyph.has_meta("glyph_anim") else null
		if old and old.is_running(): old.kill()
		var tw := glyph.create_tween().set_trans(Tween.TRANS_SINE)
		tw.tween_property(glyph,"modulate",Color(1.28,1.21,1.02) if active else Color.WHITE,0.13)
		glyph.set_meta("glyph_anim",tw)

func _build_ui() -> void:
	_label(main_ui,"傳奇倖存者",Vector2(80,53),Vector2(635,102),76,PAPER)
	_label(main_ui,"LEGENDARY SURVIVOR / 工業廢墟行動",Vector2(87,163),Vector2(540,38),20,BLUE)
	var navigation := VBoxContainer.new()
	navigation.name="Navigation"
	navigation.position=Vector2(77,265)
	navigation.size=Vector2(520,531)
	navigation.add_theme_constant_override("separation",7)
	navigation.mouse_filter=Control.MOUSE_FILTER_IGNORE
	main_ui.add_child(navigation)
	nav=navigation
	navigation.add_child(_make_navigation_button(ACTIONS[0],NAMES[0],ICONS[0],"primary",520,102))
	var gap := Control.new()
	gap.custom_minimum_size.y=13
	gap.mouse_filter=Control.MOUSE_FILTER_IGNORE
	navigation.add_child(gap)
	for index in range(1,5):
		navigation.add_child(_make_navigation_button(ACTIONS[index],NAMES[index],ICONS[index],"secondary",520,68))
	var utility := HBoxContainer.new()
	utility.add_theme_constant_override("separation",14)
	utility.mouse_filter=Control.MOUSE_FILTER_IGNORE
	navigation.add_child(utility)
	for index in range(5,7):
		utility.add_child(_make_navigation_button(ACTIONS[index],NAMES[index],ICONS[index],"utility",253,64))
	# Actual save data is injected by ScifiUI after _ready().
	_image(main_ui,"ProfileFrame","v3_version_frame.png",Vector2(1500,33),Vector2(344,107),true)
	_image(main_ui,"ProfileMark","menu_icon_deploy.png",Vector2(1517,58),Vector2(54,54))
	_label(main_ui,"本機檔案 / LOCAL DATA",Vector2(1582,43),Vector2(245,37),20,PAPER)
	_label(main_ui,"作戰紀錄 / RUNS  0",Vector2(1583,85),Vector2(243,27),17,MUTED).name="HistoryCount"
	_label(main_ui,"信用點 / CREDITS  0",Vector2(1583,111),Vector2(243,25),17,GOLD).name="CreditCount"
	var mission := Button.new()
	mission.name="MissionBanner"
	mission.text=""
	mission.position=Vector2(70,851)
	mission.size=Vector2(650,155)
	mission.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	mission.focus_mode=Control.FOCUS_ALL
	var no_style:=StyleBoxEmpty.new()
	for st in ["normal","hover","pressed","focus"]:
		mission.add_theme_stylebox_override(st,no_style)
	main_ui.add_child(mission)
	var backdrop:=_image(mission,"BannerArt","v3_mission_frame.png",Vector2.ZERO,Vector2(650,155),true)
	_label(mission,"作戰任務 / MAIN OPERATION",Vector2(38,13),Vector2(530,28),17,GOLD)
	_label(mission,"工業廢墟 / INDUSTRIAL RUINS",Vector2(39,44),Vector2(530,57),27,PAPER)
	_label(mission,"最終目標：徵收者 / TARGET: COLLECTOR",Vector2(41,105),Vector2(540,29),18,MUTED)
	mission.pressed.connect(func() -> void: _request_action("open_loadout"))
	mission.mouse_entered.connect(func() -> void: backdrop.modulate=Color(1.17,1.10,1.0))
	mission.mouse_exited.connect(func() -> void: backdrop.modulate=Color.WHITE)
	_image(main_ui,"VersionFrame","v3_version_frame.png",Vector2(1382,861),Vector2(462,144),true)
	_label(main_ui,"版本資訊 / BUILD INFO",Vector2(1417,876),Vector2(390,34),22,PAPER)
	_label(main_ui,"工業廢墟 · 單人作戰 / SOLO RUN",Vector2(1418,915),Vector2(393,30),18,MUTED)
	_label(main_ui,"開發預覽 / PREVIEW v0.2",Vector2(1418,954),Vector2(395,30),17,BLUE)
	_label(main_ui,"",Vector2(744,1006),Vector2(550,41),21,GOLD).name="SaveError"

func _populate_data() -> void:
	if not is_instance_valid(main_ui): return
	var history: Label = main_ui.get_node_or_null("HistoryCount") as Label
	var credits: Label = main_ui.get_node_or_null("CreditCount") as Label
	var errors: Label = main_ui.get_node_or_null("SaveError") as Label
	if history: history.text = "作戰紀錄 / RUNS  %d" % scores.size()
	if credits: credits.text = "信用點 / CREDITS  %d" % int(progress.get("credits",0))
	if errors: errors.text = String(progress.get("save_error",""))
	var pending: Dictionary=progress.get("pending",{})
	if not pending.is_empty() and main_ui.get_node_or_null("RetrySave")==null:
		var retry:=Button.new()
		retry.name="RetrySave"
		retry.text="重試保存 / RETRY SAVE"
		retry.position=Vector2(768,944)
		retry.size=Vector2(330,60)
		retry.add_theme_font_size_override("font_size",23)
		main_ui.add_child(retry)
		retry.pressed.connect(func() -> void:_request_action("retry_save"))

func _build_cycle() -> void:
	if reduced_motion: return
	var animation := Animation.new()
	animation.length = 12.0
	animation.loop_mode = Animation.LOOP_LINEAR
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track,NodePath("Environment/LightRays:modulate:a"))
	animation.track_insert_key(track,0.0,0.28)
	animation.track_insert_key(track,3.0,0.56)
	animation.track_insert_key(track,6.0,0.28)
	animation.track_insert_key(track,9.0,0.56)
	animation.track_insert_key(track,12.0,0.28)
	var crane_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(crane_track,NodePath("Environment/HangarCrane:position:x"))
	animation.track_insert_key(crane_track,0.0,1315.0)
	animation.track_insert_key(crane_track,3.0,1350.0)
	animation.track_insert_key(crane_track,5.0,1350.0)
	animation.track_insert_key(crane_track,9.0,1315.0)
	animation.track_insert_key(crane_track,12.0,1315.0)
	var library := AnimationLibrary.new()
	library.add_animation("ambient_light",animation)
	animator.add_animation_library("",library)
	animator.play("ambient_light")

func set_reduce_motion(value: bool) -> void:
	reduced_motion = value
	if not is_node_ready(): return
	set_process(not value)
	if animator.is_playing() and value: animator.stop()
	if crane and value: crane.position.x = 1315.0
	if rays: rays.modulate.a = 0.30 if value else 0.48
	var particles: GPUParticles2D = environment.get_node_or_null("HangarDust") as GPUParticles2D
	if particles: particles.emitting = not value
	var rig: Node2D = hero_display.get_node_or_null("HeroRig") as Node2D
	if rig: rig.call("set_reduced_motion", value)

func _play_intro() -> void:
	var seen := bool(get_tree().get_meta("v3_menu_intro_seen",false))
	if seen or reduced_motion: return
	get_tree().set_meta("v3_menu_intro_seen",true)
	main_ui.modulate.a=0
	var reveal:=main_ui.create_tween()
	reveal.tween_property(main_ui,"modulate:a",1.0,0.32).set_trans(Tween.TRANS_CUBIC)
	hero_display.modulate.a=0.45
	var hero_reveal:=hero_display.create_tween()
	hero_reveal.tween_property(hero_display,"modulate:a",1.0,0.65).set_trans(Tween.TRANS_SINE)

func _request_action(action: String) -> void:
	if transitioning: return
	var owner_game: Node = get_parent().get_parent().get_parent().get_parent()
	var bus: Node = owner_game.get("sound") if owner_game != null else null
	if bus != null: bus.call("play_event","ui_select")
	transitioning=true
	for btn in main_actions: btn.disabled=true
	if reduced_motion:
		action_requested.emit(action)
		return
	transition_layer.visible=true
	transition_layer.color=Color(0.015,0.03,0.05,0.0)
	var fade:=transition_layer.create_tween()
	fade.tween_property(transition_layer,"color:a",0.80,0.23 if action!="open_loadout" else 0.36)
	fade.finished.connect(func() -> void:
		if is_inside_tree(): action_requested.emit(action))
