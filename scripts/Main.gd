extends Node2D

const GameConfig := preload("res://scripts/GameConfig.gd")
const ValidationTools := preload("res://scripts/ValidationTools.gd")
const ScoreStore := preload("res://scripts/ScoreStore.gd")
const PlayerScene := preload("res://scripts/Player.gd")
const EnemyScene := preload("res://scripts/Enemy.gd")
const CatScene := preload("res://scripts/CatProjectile.gd")
const MilkScene := preload("res://scripts/MilkDrop.gd")
const XpScene := preload("res://scripts/XpOrb.gd")
const GameUIScene := preload("res://scripts/GameUI.gd")
const SfxBusScene := preload("res://scripts/SfxBus.gd")

const ENEMY_SEPARATION_CELL_SIZE := 160.0
const ENEMY_SEPARATION_RADIUS_SCALE := 0.92
const ENEMY_SEPARATION_PUSH_STRENGTH := 0.72
const ENEMY_SEPARATION_MAX_PUSH_SPEED := 260.0

var rng := RandomNumberGenerator.new()
var args := {}
var game_state := "menu"
var previous_state := "menu"
var game_time := 0.0
var current_wave := 1
var previous_wave := 1
var spawn_timer := 0.0
var kills := 0
var xp := 0
var level_index := 0
var upgrade_count := 0
var cats_fired := 0
var cat_fire_counts := {"orange": 0, "black": 0, "cow": 0}
var cat_damage_done := {"orange": 0.0, "black": 0.0, "cow": 0.0}
var unlocked_weapons := ["orange"]
var upgrade_levels := {"U01": 0, "U02": 0, "U03": 0, "U04": 0}
var weapon_cooldowns := {"orange": 0.0, "black": 0.0, "cow": 0.0}
var queued_upgrade := false
var capture_elapsed := 0.0
var capture_count := 0
var run_elapsed := 0.0
var report_written := false
var debug_overlay := false
var shake_left := 0.0
var event_counts := {}
var event_log := []
var wave_spawn_counts := {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0}
var validation_probe := {}
var probe_mode := ""
var score_save_path := ""
var last_result_summary := {}
var exit_requested := false
var quit_intercepted := false
var probe_elapsed := 0.0
var probe_sample_elapsed := 0.0
var movement_probe_reported := false
var pause_probe_reported := false
var xp_probe_reported := false

var world: Node2D
var enemy_layer: Node2D
var projectile_layer: Node2D
var milk_layer: Node2D
var xp_layer: Node2D
var vfx_layer: Node2D
var decor_layer: Node2D
var player
var ui
var sfx

var enemies := []
var cats := []
var milk_drops := []
var xp_orbs := []
var vfx_items := []

func _ready() -> void:
	args = ValidationTools.parse_args()
	Engine.time_scale = float(args.time_scale)
	rng.seed = int(args.seed)
	debug_overlay = bool(args.debug_overlay)
	score_save_path = String(args.score_save_path)
	if score_save_path.is_empty():
		score_save_path = "user://huazi_scores_probe.json" if _uses_probe_score_file(String(args.debug_mode)) else String(GameConfig.SCORE["save_path"])
	get_tree().paused = false
	_setup_world()
	_setup_pools()
	_setup_ui_and_audio()
	if _starts_from_menu():
		_prepare_menu_state()
		ui.show_main_menu()
	else:
		start_new_run()
	_apply_debug_mode()
	if not String(args.capture_dir).is_empty():
		ValidationTools.ensure_dir(args.capture_dir)
		await get_tree().process_frame
		_capture_named(_capture_name_for_state())

func _setup_world() -> void:
	world = Node2D.new()
	add_child(world)
	var map := Sprite2D.new()
	map.name = "FullOutdoorMap"
	map.texture = load("res://assets/sprites/full_outdoor_map_painted_4096x2305.png")
	map.centered = false
	world.add_child(map)
	decor_layer = Node2D.new()
	decor_layer.name = "EnvironmentDecor"
	world.add_child(decor_layer)
	_build_environment_decor()
	enemy_layer = Node2D.new()
	enemy_layer.name = "Enemies"
	world.add_child(enemy_layer)
	projectile_layer = Node2D.new()
	projectile_layer.name = "CatProjectiles"
	world.add_child(projectile_layer)
	milk_layer = Node2D.new()
	milk_layer.name = "MilkDrops"
	world.add_child(milk_layer)
	xp_layer = Node2D.new()
	xp_layer.name = "XpOrbs"
	world.add_child(xp_layer)
	vfx_layer = Node2D.new()
	vfx_layer.name = "Vfx"
	world.add_child(vfx_layer)
	player = PlayerScene.new()
	player.name = "Huazi"
	world.add_child(player)

func _build_environment_decor() -> void:
	var rng_decor := RandomNumberGenerator.new()
	rng_decor.seed = 20260614
	var sheet = load("res://assets/sprites/environment_assets_painted.png")
	var small_regions := [
		Rect2(0, 298, 82, 114),
		Rect2(88, 292, 82, 118),
		Rect2(178, 282, 84, 130),
		Rect2(274, 292, 82, 118),
		Rect2(374, 302, 76, 104),
		Rect2(480, 310, 76, 92),
		Rect2(580, 304, 74, 98),
		Rect2(690, 300, 116, 112),
		Rect2(810, 298, 122, 118),
		Rect2(950, 300, 126, 122),
		Rect2(40, 462, 110, 104),
		Rect2(165, 452, 170, 124),
		Rect2(350, 466, 128, 100),
		Rect2(520, 454, 132, 118),
		Rect2(676, 462, 128, 116)
	]
	for i in 70:
		var sprite := Sprite2D.new()
		var region := AtlasTexture.new()
		region.atlas = sheet
		region.region = small_regions[rng_decor.randi_range(0, small_regions.size() - 1)]
		sprite.texture = region
		sprite.position = Vector2(rng_decor.randf_range(140.0, GameConfig.MAP_SIZE.x - 140.0), rng_decor.randf_range(140.0, GameConfig.MAP_SIZE.y - 140.0))
		sprite.rotation = rng_decor.randf_range(-0.35, 0.35)
		sprite.scale = Vector2.ONE * rng_decor.randf_range(0.58, 1.05)
		sprite.modulate.a = rng_decor.randf_range(0.72, 0.96)
		decor_layer.add_child(sprite)
	for i in 11:
		_add_boundary_decor(Vector2(210 + i * 355, 94), Rect2(390, 594, 350, 126), 0.98)
		_add_boundary_decor(Vector2(210 + i * 355, GameConfig.MAP_SIZE.y - 94), Rect2(390, 594, 350, 126), 0.98)
	for i in 6:
		_add_boundary_decor(Vector2(94, 250 + i * 300), Rect2(0, 592, 185, 160), 1.0)
		_add_boundary_decor(Vector2(GameConfig.MAP_SIZE.x - 94, 250 + i * 300), Rect2(0, 592, 185, 160), 1.0)
	for i in 5:
		_add_boundary_decor(Vector2(620 + i * 620, GameConfig.MAP_SIZE.y - 190), Rect2(830, 594, 650, 170), 0.78)
	_add_sheet_decor(Vector2(780, 520), Rect2(1110, 455, 360, 150), 0.82, 0.96)
	_add_sheet_decor(Vector2(3270, 540), Rect2(1110, 455, 360, 150), 0.74, 0.94)
	_add_sheet_decor(Vector2(3050, 1780), Rect2(545, 820, 690, 200), 0.98, 0.96)

func _add_boundary_decor(pos: Vector2, region_rect: Rect2, scale_value: float) -> void:
	_add_sheet_decor(pos, region_rect, scale_value, 0.94)

func _add_sheet_decor(pos: Vector2, region_rect: Rect2, scale_value: float, alpha := 0.94) -> void:
	var sprite := Sprite2D.new()
	var region := AtlasTexture.new()
	region.atlas = load("res://assets/sprites/environment_assets_painted.png")
	region.region = region_rect
	sprite.texture = region
	sprite.position = pos
	sprite.scale = Vector2.ONE * scale_value
	sprite.modulate.a = alpha
	decor_layer.add_child(sprite)

func _setup_pools() -> void:
	for i in GameConfig.LIMITS["enemies"]:
		var enemy = EnemyScene.new()
		enemy.deactivate()
		enemy.request_milk.connect(_spawn_milk)
		enemy_layer.add_child(enemy)
		enemies.append(enemy)
	for i in GameConfig.LIMITS["cats"]:
		var cat = CatScene.new()
		cat.deactivate()
		projectile_layer.add_child(cat)
		cats.append(cat)
	for i in GameConfig.LIMITS["milk"]:
		var milk = MilkScene.new()
		milk.deactivate()
		milk_layer.add_child(milk)
		milk_drops.append(milk)
	for i in GameConfig.LIMITS["xp"]:
		var orb = XpScene.new()
		orb.deactivate()
		xp_layer.add_child(orb)
		xp_orbs.append(orb)

func _setup_ui_and_audio() -> void:
	ui = GameUIScene.new()
	add_child(ui)
	ui.start_game_requested.connect(_on_start_game_requested)
	ui.scores_requested.connect(_on_scores_requested)
	ui.upgrade_selected.connect(_on_upgrade_selected)
	ui.restart_requested.connect(start_new_run)
	ui.resume_requested.connect(_resume_from_pause)
	ui.exit_requested.connect(_request_exit)
	sfx = SfxBusScene.new()
	add_child(sfx)
	sfx.start_bgm()

func _starts_from_menu() -> bool:
	var mode := String(args.debug_mode)
	return mode.is_empty() or mode == "menu_probe" or mode == "scores_probe" or mode == "bgm_probe"

func _uses_probe_score_file(mode: String) -> bool:
	return mode == "menu_probe" or mode == "scores_probe" or mode == "failure_score_probe"

func _prepare_menu_state() -> void:
	game_state = "menu"
	previous_state = "menu"
	game_time = 0.0
	run_elapsed = 0.0
	current_wave = 1
	previous_wave = 1
	spawn_timer = 0.0
	kills = 0
	xp = 0
	level_index = 0
	upgrade_count = 0
	cats_fired = 0
	cat_fire_counts = {"orange": 0, "black": 0, "cow": 0}
	cat_damage_done = {"orange": 0.0, "black": 0.0, "cow": 0.0}
	unlocked_weapons = ["orange"]
	upgrade_levels = {"U01": 0, "U02": 0, "U03": 0, "U04": 0}
	weapon_cooldowns = {"orange": 0.0, "black": 0.0, "cow": 0.0}
	queued_upgrade = false
	get_tree().paused = false
	_deactivate_run_nodes()
	player.reset_player()
	ui.set_hud_visible(false)
	ui.update_hud(make_snapshot())

func _deactivate_run_nodes() -> void:
	for enemy in enemies:
		enemy.deactivate()
	for cat in cats:
		cat.deactivate()
	for milk in milk_drops:
		milk.deactivate()
	for orb in xp_orbs:
		orb.deactivate()
	for item in vfx_items:
		if is_instance_valid(item):
			item.queue_free()
	vfx_items.clear()

func start_new_run() -> void:
	game_state = "combat"
	previous_state = "combat"
	game_time = 0.0
	run_elapsed = 0.0
	current_wave = 1
	previous_wave = 1
	spawn_timer = 0.0
	kills = 0
	xp = 0
	level_index = 0
	upgrade_count = 0
	cats_fired = 0
	cat_fire_counts = {"orange": 0, "black": 0, "cow": 0}
	cat_damage_done = {"orange": 0.0, "black": 0.0, "cow": 0.0}
	unlocked_weapons = ["orange"]
	upgrade_levels = {"U01": 0, "U02": 0, "U03": 0, "U04": 0}
	weapon_cooldowns = {"orange": 0.0, "black": 0.0, "cow": 0.0}
	queued_upgrade = false
	report_written = false
	capture_count = 0
	capture_elapsed = 0.0
	event_counts = {}
	event_log = []
	wave_spawn_counts = {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0}
	probe_mode = ""
	probe_elapsed = 0.0
	probe_sample_elapsed = 0.0
	movement_probe_reported = false
	pause_probe_reported = false
	xp_probe_reported = false
	last_result_summary = {}
	exit_requested = false
	quit_intercepted = false
	get_tree().paused = false
	_deactivate_run_nodes()
	player.reset_player()
	ui.set_hud_visible(true)
	ui.clear_popups()
	ui.update_hud(make_snapshot())
	_record_event("run_started", {"seed": int(args.seed)})
	sfx.play_event("wave_start")

func _apply_debug_mode() -> void:
	var mode := String(args.debug_mode)
	if mode == "menu_probe":
		_run_menu_probe()
	elif mode == "scores_probe":
		_run_scores_probe()
	elif mode == "failure_score_probe":
		_run_failure_score_probe()
	elif mode == "bgm_probe":
		_run_bgm_probe()
	elif mode == "upgrade":
		_spawn_debug_enemies(6)
		xp = GameConfig.xp_needed(level_index)
		_trigger_upgrade()
	elif mode == "victory":
		game_time = 239.4
		current_wave = 5
		previous_wave = 5
		unlocked_weapons = ["orange", "black", "cow"]
		_spawn_debug_enemies(10)
	elif mode == "failure":
		player.hp = 8.0
		_spawn_enemy("calf", player.global_position + Vector2(70, 0))
	elif mode == "wave5" or mode == "combat_pressure":
		game_time = 190.0
		current_wave = 5
		previous_wave = 5
		unlocked_weapons = ["orange", "black", "cow"]
		for id in upgrade_levels.keys():
			upgrade_levels[id] = min(2, GameConfig.UPGRADES[id]["max"])
		_apply_upgrade_multipliers()
		_spawn_debug_enemies(30)
	elif mode == "pause_probe" or mode == "pause_probe_esc":
		_start_pause_probe("Esc")
	elif mode == "pause_probe_p":
		_start_pause_probe("P")
	elif mode == "restart_victory":
		_run_restart_probe("victory")
	elif mode == "restart_failure":
		_run_restart_probe("failure")
	elif mode == "movement_probe":
		_start_movement_probe()
	elif mode == "input_probe":
		_run_input_probe()
	elif mode == "xp_probe":
		_start_xp_probe()
	elif mode == "combat_showcase":
		_setup_combat_showcase()
	elif mode == "hud_probe":
		_setup_hud_probe()
	elif mode == "map_water":
		_move_player_for_capture(Vector2(850, 540))
	elif mode == "map_boundary":
		_move_player_for_capture(Vector2(GameConfig.MAP_SIZE.x - 150.0, 1152.0))
	ui.update_hud(make_snapshot())

func _process(delta: float) -> void:
	run_elapsed += delta
	if Input.is_action_just_pressed("pause_game"):
		_toggle_pause()
	if game_state == "combat":
		_step_combat(delta)
	elif game_state == "paused":
		pass
	ui.update_hud(make_snapshot())
	_step_validation_probe(delta)
	_step_vfx(delta)
	_step_capture(delta)
	if debug_overlay:
		queue_redraw()
	if float(args.run_seconds) > 0.0 and run_elapsed >= float(args.run_seconds):
		_finish_validation_and_quit()

func _step_combat(delta: float) -> void:
	game_time += delta
	_update_wave_and_unlocks()
	player.step_player(delta, true, _validation_move_vector() if String(args.debug_mode) == "movement_probe" else (_auto_play_vector() if bool(args.auto_play) else Vector2.ZERO))
	_step_spawning(delta)
	_step_weapons(delta)
	for enemy in enemies:
		enemy.step_enemy(delta, player.global_position)
	_resolve_enemy_separation(delta)
	for cat in cats:
		cat.step_projectile(delta)
	for milk in milk_drops:
		milk.step_milk(delta)
	for orb in xp_orbs:
		if orb.step_xp(delta, player.global_position):
			_collect_xp(orb)
	_handle_collisions()
	if player.hp <= 0.0:
		_finish_run("failure")
	elif game_time >= 240.0:
		_finish_run("victory")

func _update_wave_and_unlocks() -> void:
	var wave := GameConfig.wave_for_time(game_time)
	current_wave = int(wave["index"])
	if current_wave != previous_wave:
		var old_wave: Dictionary = GameConfig.WAVES[previous_wave - 1]
		var unlock := String(old_wave.get("unlock", ""))
		if not unlock.is_empty() and not unlocked_weapons.has(unlock):
			unlocked_weapons.append(unlock)
			sfx.play_event("weapon_unlock")
			_record_event("weapon_unlocked", {"weapon": unlock, "wave": current_wave})
			_spawn_notice_vfx(player.global_position + Vector2(0, -120), "解锁%s" % GameConfig.CAT_STATS[unlock]["name"])
		previous_wave = current_wave
		spawn_timer = 0.0
		sfx.play_event("wave_start")
		_record_event("wave_started", {"wave": current_wave, "time": game_time})

func _step_spawning(delta: float) -> void:
	spawn_timer -= delta
	var wave := GameConfig.wave_for_time(game_time)
	var wave_key := str(int(wave["index"]))
	var target_spawns := int(wave.get("target_spawns", -1))
	while spawn_timer <= 0.0:
		if target_spawns >= 0 and int(wave_spawn_counts.get(wave_key, 0)) >= target_spawns:
			spawn_timer = 0.0
			return
		spawn_timer += float(wave["spawn_interval"])
		if _active_count(enemies) >= GameConfig.LIMITS["enemies"]:
			return
		var enemy = _spawn_enemy(_pick_enemy_type(wave["weights"]), _spawn_position())
		if enemy != null:
			wave_spawn_counts[wave_key] = int(wave_spawn_counts.get(wave_key, 0)) + 1

func _step_weapons(delta: float) -> void:
	for kind in unlocked_weapons:
		weapon_cooldowns[kind] = max(0.0, float(weapon_cooldowns[kind]) - delta)
		if weapon_cooldowns[kind] <= 0.0:
			if _active_cat_count(kind) < GameConfig.CAT_STATS[kind]["limit"]:
				if _fire_cat(kind):
					weapon_cooldowns[kind] = _cat_stat(kind, "cooldown")

func _fire_cat(kind: String) -> bool:
	var target = _find_target_for_cat(kind)
	if target == null:
		return false
	var target_pos: Vector2 = target.global_position
	var direction: Vector2 = (target_pos - player.global_position).normalized()
	if direction.length_squared() < 0.01:
		direction = Vector2.RIGHT
	var cat = _inactive_cat()
	if cat == null:
		return false
	var spawn_pos: Vector2 = player.global_position + direction * 54.0
	cat.setup(kind, spawn_pos, direction, _cat_stat(kind, "damage"), _cat_stat(kind, "speed"), target_pos)
	cats_fired += 1
	cat_fire_counts[kind] = int(cat_fire_counts[kind]) + 1
	sfx.play_event(GameConfig.CAT_STATS[kind]["sfx"])
	_record_event("cat_fired", {
		"kind": kind,
		"damage": cat.damage,
		"speed": _cat_stat(kind, "speed"),
		"from": _point(player.global_position),
		"target": _point(target_pos)
	})
	return true

func _find_target_for_cat(kind: String):
	var active := _active_enemies()
	if active.is_empty():
		return null
	if kind == "black":
		var best = active[0]
		var best_score := -1
		for enemy in active:
			var score := 0
			for other in active:
				if enemy.global_position.distance_to(other.global_position) <= 260.0:
					score += 1
			if score > best_score:
				best_score = score
				best = enemy
		return best
	var nearest = active[0]
	var nearest_dist := INF
	for enemy in active:
		var dist: float = enemy.global_position.distance_squared_to(player.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest

func _resolve_enemy_separation(delta: float) -> void:
	var active := _active_enemies()
	if active.size() < 2:
		return
	var cells := {}
	var pushes := {}
	for enemy in active:
		var id: int = enemy.get_instance_id()
		pushes[id] = Vector2.ZERO
		var cell := _enemy_separation_cell(enemy.global_position)
		var key := _enemy_separation_key(cell)
		if not cells.has(key):
			cells[key] = []
		cells[key].append(enemy)
	for enemy in active:
		var enemy_id: int = enemy.get_instance_id()
		var cell := _enemy_separation_cell(enemy.global_position)
		for y in range(-1, 2):
			for x in range(-1, 2):
				var bucket: Array = cells.get(_enemy_separation_key(Vector2i(cell.x + x, cell.y + y)), [])
				for other in bucket:
					var other_id: int = other.get_instance_id()
					if other_id <= enemy_id:
						continue
					var min_distance := (float(enemy.stats["radius"]) + float(other.stats["radius"])) * ENEMY_SEPARATION_RADIUS_SCALE
					var offset: Vector2 = enemy.global_position - other.global_position
					var distance_sq := offset.length_squared()
					if distance_sq >= min_distance * min_distance:
						continue
					var distance := sqrt(distance_sq)
					var direction := Vector2.ZERO
					if distance > 0.01:
						direction = offset / distance
					else:
						direction = Vector2.RIGHT.rotated(float((enemy_id + other_id) % 360) * TAU / 360.0)
					var push := direction * (min_distance - distance) * ENEMY_SEPARATION_PUSH_STRENGTH * 0.5
					pushes[enemy_id] = pushes[enemy_id] + push
					pushes[other_id] = pushes[other_id] - push
	var max_push := ENEMY_SEPARATION_MAX_PUSH_SPEED * delta
	for enemy in active:
		var push: Vector2 = pushes[enemy.get_instance_id()]
		if push.length_squared() <= 0.001:
			continue
		if push.length() > max_push:
			push = push.normalized() * max_push
		enemy.global_position += push
		enemy.global_position.x = clamp(enemy.global_position.x, 40.0, GameConfig.MAP_SIZE.x - 40.0)
		enemy.global_position.y = clamp(enemy.global_position.y, 40.0, GameConfig.MAP_SIZE.y - 40.0)

func _enemy_separation_cell(pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(pos.x / ENEMY_SEPARATION_CELL_SIZE)),
		int(floor(pos.y / ENEMY_SEPARATION_CELL_SIZE))
	)

func _enemy_separation_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]

func _handle_collisions() -> void:
	for enemy in enemies:
		if not enemy.active:
			continue
		if enemy.global_position.distance_to(player.global_position) <= float(enemy.stats["radius"]) + GameConfig.PLAYER["radius"]:
			if player.take_damage(float(enemy.stats["contact_damage"])):
				sfx.play_event("player_hurt")
				_record_event("player_hurt", {
					"source": "enemy_contact",
					"enemy_type": enemy.enemy_type,
					"hp": player.hp
				})
				shake_left = 0.12
	for milk in milk_drops:
		if not milk.active:
			continue
		if milk.global_position.distance_to(player.global_position) <= GameConfig.MILK["radius"] + GameConfig.PLAYER["radius"]:
			if player.take_damage(GameConfig.MILK["damage"]):
				milk.deactivate()
				sfx.play_event("player_hurt")
				_record_event("player_hurt", {"source": "milk", "hp": player.hp})
				shake_left = 0.10
	for cat in cats:
		if not cat.active:
			continue
		if cat.cat_type == "black":
			var should_explode: bool = cat.global_position.distance_to(cat.target_position) < 58.0
			for enemy in enemies:
				if enemy.active and cat.global_position.distance_to(enemy.global_position) <= float(enemy.stats["radius"]) + float(cat.stats["radius"]):
					should_explode = true
					break
			if should_explode:
				_black_cat_explode(cat)
			continue
		for enemy in enemies:
			if not enemy.active:
				continue
			if cat.hit_ids.has(enemy.get_instance_id()):
				continue
			if cat.global_position.distance_to(enemy.global_position) <= float(enemy.stats["radius"]) + float(cat.stats["radius"]):
				_damage_enemy(enemy, cat.damage, cat.cat_type)
				sfx.play_event("hit")
				_spawn_texture_vfx(enemy.global_position, "res://assets/sprites/vfx/runtime/impact_hit_96.png", 0.22, Vector2(0.72, 0.72))
				if cat.cat_type == "orange":
					cat.deactivate()
					break
				if cat.cat_type == "cow":
					cat.hit_ids[enemy.get_instance_id()] = true
					cat.total_hits += 1
					if cat.total_hits >= int(cat.stats["max_hits"]):
						cat.deactivate()
						break

func _black_cat_explode(cat) -> void:
	var radius := float(cat.stats["explosion_radius"])
	for enemy in enemies:
		if enemy.active and enemy.global_position.distance_to(cat.global_position) <= radius:
			_damage_enemy(enemy, float(cat.stats["explosion_damage"]) * _upgrade_multiplier("damage"), "black")
	sfx.play_event("cat_black_explode")
	_record_event("black_cat_exploded", {
		"position": _point(cat.global_position),
		"radius": radius
	})
	_spawn_texture_vfx(cat.global_position, "res://assets/sprites/vfx/runtime/black_cat_explosion_256.png", 0.35, Vector2(1.25, 1.25))
	shake_left = 0.08
	cat.deactivate()

func _damage_enemy(enemy, amount: float, source_cat: String) -> void:
	cat_damage_done[source_cat] = float(cat_damage_done[source_cat]) + amount
	_record_event("enemy_damaged", {
		"enemy_type": enemy.enemy_type,
		"source_cat": source_cat,
		"amount": amount,
		"hp_before": enemy.hp
	})
	if enemy.take_damage(amount):
		_kill_enemy(enemy)

func _kill_enemy(enemy) -> void:
	kills += 1
	_record_event("enemy_killed", {
		"enemy_type": enemy.enemy_type,
		"xp": int(enemy.stats["xp"]),
		"kills": kills
	})
	_spawn_xp(enemy.global_position, int(enemy.stats["xp"]))
	_spawn_texture_vfx(enemy.global_position, "res://assets/sprites/vfx/runtime/death_smoke_128.png", 0.38, Vector2(0.85, 0.85))
	enemy.deactivate()
	sfx.play_event("enemy_die")

func _collect_xp(orb) -> void:
	xp += orb.value
	orb.deactivate()
	sfx.play_event("xp_pickup")
	_record_event("xp_collected", {
		"value": orb.value,
		"xp": xp,
		"xp_needed": GameConfig.xp_needed(level_index)
	})
	while xp >= GameConfig.xp_needed(level_index):
		xp -= GameConfig.xp_needed(level_index)
		level_index += 1
		if _available_upgrades().is_empty():
			continue
		_trigger_upgrade()
		break

func _trigger_upgrade() -> void:
	game_state = "upgrade"
	queued_upgrade = true
	var options := _roll_upgrades()
	ui.show_upgrade(options, upgrade_levels)
	sfx.play_event("level_up")
	_record_event("level_up", {
		"level_index": level_index,
		"options": options.duplicate(),
		"upgrade_count": upgrade_count
	})
	if bool(args.auto_upgrade) and not options.is_empty():
		await get_tree().process_frame
		_on_upgrade_selected(_pick_auto_upgrade(options))

func _roll_upgrades() -> Array:
	var available := _available_upgrades()
	var result := []
	while not available.is_empty() and result.size() < 3:
		var index := rng.randi_range(0, available.size() - 1)
		result.append(available[index])
		available.remove_at(index)
	return result

func _available_upgrades() -> Array:
	var list := []
	for id in GameConfig.UPGRADES.keys():
		if int(upgrade_levels[id]) < int(GameConfig.UPGRADES[id]["max"]):
			list.append(id)
	return list

func _on_start_game_requested() -> void:
	start_new_run()

func _on_scores_requested() -> void:
	ui.show_scores(ScoreStore.load_scores(score_save_path))

func _on_upgrade_selected(upgrade_id: String) -> void:
	if game_state != "upgrade":
		return
	if not GameConfig.UPGRADES.has(upgrade_id):
		return
	upgrade_levels[upgrade_id] = int(upgrade_levels[upgrade_id]) + 1
	upgrade_count += 1
	_apply_upgrade_multipliers()
	ui.clear_popups()
	game_state = "combat"
	queued_upgrade = false
	sfx.play_event("ui_select")
	_record_event("upgrade_selected", {
		"upgrade_id": upgrade_id,
		"new_level": int(upgrade_levels[upgrade_id]),
		"upgrade_count": upgrade_count
	})

func _pick_auto_upgrade(options: Array) -> String:
	var targets := {"U04": 2, "U02": 3, "U01": 1, "U03": 1}
	for id in ["U04", "U02", "U01", "U03"]:
		if options.has(id) and int(upgrade_levels[id]) < int(targets[id]):
			return id
	for id in ["U02", "U01", "U04", "U03"]:
		if options.has(id):
			return id
	return options[0]

func _request_exit() -> void:
	exit_requested = true
	_record_event("exit_requested", {"state": game_state})
	if String(args.debug_mode) == "failure_score_probe":
		quit_intercepted = true
		return
	sfx.shutdown()
	get_tree().quit()

func _apply_upgrade_multipliers() -> void:
	player.speed_multiplier = _upgrade_multiplier("player_speed")

func _cat_stat(kind: String, stat_name: String) -> float:
	var base := float(GameConfig.CAT_STATS[kind][stat_name])
	if stat_name == "cooldown":
		return base * _upgrade_multiplier("cooldown")
	if stat_name == "damage":
		return base * _upgrade_multiplier("damage")
	if stat_name == "speed":
		return base * _upgrade_multiplier("cat_speed")
	return base

func _upgrade_multiplier(stat_name: String) -> float:
	var value := 1.0
	for id in GameConfig.UPGRADES.keys():
		var data: Dictionary = GameConfig.UPGRADES[id]
		if data["stat"] == stat_name:
			value *= pow(float(data["factor"]), int(upgrade_levels[id]))
	return value

func _pick_enemy_type(weights: Dictionary) -> String:
	var roll := rng.randf()
	var cursor := 0.0
	for key in weights.keys():
		cursor += float(weights[key])
		if roll <= cursor:
			return key
	return weights.keys()[-1]

func _spawn_position() -> Vector2:
	var angle := rng.randf_range(0.0, TAU)
	var distance := rng.randf_range(720.0, 980.0)
	var pos: Vector2 = player.global_position + Vector2.RIGHT.rotated(angle) * distance
	pos.x = clamp(pos.x, 90.0, GameConfig.MAP_SIZE.x - 90.0)
	pos.y = clamp(pos.y, 90.0, GameConfig.MAP_SIZE.y - 90.0)
	return pos

func _spawn_enemy(kind: String, pos: Vector2):
	for enemy in enemies:
		if not enemy.active:
			var initial_milk_timer := 0.2
			if GameConfig.ENEMY_STATS[kind].has("shoot_interval"):
				initial_milk_timer = rng.randf_range(0.2, float(GameConfig.ENEMY_STATS[kind]["shoot_interval"]))
			enemy.setup(kind, pos, initial_milk_timer)
			_record_event("enemy_spawned", {
				"enemy_type": kind,
				"position": _point(pos)
			})
			return enemy
	return null

func _spawn_debug_enemies(count: int) -> void:
	var types := ["normal", "calf", "tank", "ranged"]
	for i in count:
		var angle: float = TAU * float(i) / max(1.0, float(count))
		var kind: String = types[i % types.size()]
		_spawn_enemy(kind, player.global_position + Vector2.RIGHT.rotated(angle) * rng.randf_range(260.0, 780.0))

func _move_player_for_capture(pos: Vector2) -> void:
	player.global_position = pos
	player.camera.reset_smoothing()
	player.camera.force_update_scroll()

func _setup_combat_showcase() -> void:
	game_time = 191.0
	current_wave = 5
	previous_wave = 5
	unlocked_weapons = ["orange", "black", "cow"]
	upgrade_levels = {"U01": 1, "U02": 3, "U03": 1, "U04": 2}
	level_index = 6
	upgrade_count = 6
	xp = 0
	_apply_upgrade_multipliers()
	for kind in weapon_cooldowns.keys():
		weapon_cooldowns[kind] = 0.0
	var offsets := [
		["normal", Vector2(240, -30)],
		["normal", Vector2(310, 42)],
		["calf", Vector2(165, 125)],
		["calf", Vector2(-210, 155)],
		["tank", Vector2(390, -110)],
		["tank", Vector2(-340, -80)],
		["ranged", Vector2(500, 40)],
		["ranged", Vector2(-460, -150)],
		["normal", Vector2(115, -185)],
		["calf", Vector2(-135, -220)]
	]
	for item in offsets:
		var kind := String(item[0])
		var offset: Vector2 = item[1]
		var enemy = _spawn_enemy(kind, player.global_position + offset)
		if enemy != null and enemy.enemy_type == "ranged":
			_spawn_milk(enemy, (player.global_position - enemy.global_position).normalized())
	_spawn_xp(player.global_position + Vector2(180, -70), 8)
	_spawn_xp(player.global_position + Vector2(-150, 125), 12)

func _setup_hud_probe() -> void:
	game_time = 75.0
	current_wave = 2
	previous_wave = 2
	spawn_timer = 999.0
	player.hp = 37.0
	xp = 15
	level_index = 0
	kills = 62
	cats_fired = 171
	cat_fire_counts = {"orange": 171, "black": 0, "cow": 0}
	unlocked_weapons = ["orange", "black"]

func _run_menu_probe() -> void:
	probe_mode = "menu_probe"
	var scores_cleanup := ScoreStore.clear_scores(score_save_path)
	validation_probe["menu_probe"] = {
		"current_screen": ui.current_screen,
		"scores_cleanup": scores_cleanup,
		"start": {
			"buttons": GameUIScene.START_BUTTONS.duplicate(),
			"visible": true,
			"enabled": true,
			"unexpected_completion_texts": []
		},
		"developers": {
			"names": GameUIScene.DEVELOPER_NAMES.duplicate(),
			"display_mode": "developer_team_screen",
			"button": "开发团队",
			"names_layout": "one_per_line",
			"visible": false
		}
	}
	if not String(args.capture_dir).is_empty():
		await get_tree().process_frame
		await _capture_named("menu_start_normal.png")
	ui.show_developers()
	validation_probe["menu_probe"]["developers"]["visible"] = true
	if not String(args.capture_dir).is_empty():
		await get_tree().process_frame
		await _capture_named("menu_developers_normal.png")
	ui.show_main_menu()
	ui.show_scores(ScoreStore.load_scores(score_save_path))
	validation_probe["menu_probe"]["scores_screen"] = {
		"visible": true,
		"score_path": score_save_path,
		"uses_isolated_probe_scores": score_save_path != String(GameConfig.SCORE["save_path"]),
		"score_count": ScoreStore.load_scores(score_save_path).size()
	}
	if not String(args.capture_dir).is_empty():
		await get_tree().process_frame
		await _capture_named("menu_scores_empty_normal.png")
	ui.show_main_menu()
	validation_probe["menu_probe"]["before_start_game"] = make_snapshot()
	_on_start_game_requested()
	spawn_timer = 999.0
	probe_mode = "menu_probe"

func _run_scores_probe() -> void:
	var probe_path := score_save_path
	var phase := String(args.score_probe_phase)
	var samples := [100, 900, 300, 700, 1100, 500, 200, 800, 400, 1000, 600, 1200]
	var run_id := "%s-%d" % [phase if not phase.is_empty() else "single", Time.get_ticks_usec()]
	var probe := {
		"persistence_path": probe_path,
		"global_persistence_path": ScoreStore.globalized_path(probe_path),
		"cleanup_method": "ScoreStore.clear_scores",
		"uses_account_or_backend": false,
		"sample_scores": samples,
		"phase": phase,
		"run_id": run_id
	}
	if phase == "read":
		var loaded := ScoreStore.load_scores(probe_path)
		probe["loaded_scores_after_restart"] = ScoreStore.score_values(loaded)
		probe["displayed_scores"] = ScoreStore.score_values(loaded)
		probe["restart_evidence"] = {
			"second_run_id": run_id,
			"phase": "read",
			"loaded_from_disk": true
		}
		ui.show_scores(loaded)
		validation_probe["scores_probe"] = probe
		return
	var cleanup := ScoreStore.clear_scores(probe_path)
	probe["cleanup_result"] = cleanup
	var empty_scores := ScoreStore.load_scores(probe_path)
	probe["empty_state"] = {
		"empty_placeholder": GameUIScene.SCORES_EMPTY_PLACEHOLDER,
		"displayed_scores": ScoreStore.score_values(empty_scores)
	}
	ui.show_scores(empty_scores)
	if not String(args.capture_dir).is_empty():
		await get_tree().process_frame
		await _capture_named("menu_scores_empty_normal.png")
	probe["written_scores"] = ScoreStore.write_score_values(samples, probe_path)
	var loaded_after_write := ScoreStore.load_scores(probe_path)
	probe["displayed_scores"] = ScoreStore.score_values(loaded_after_write)
	probe["loaded_scores_after_restart"] = ScoreStore.score_values(loaded_after_write)
	probe["restart_evidence"] = {
		"first_run_id": run_id,
		"second_run_id": "run --score-probe-phase=read with the same score path",
		"requires_independent_restart": true
	}
	ui.show_scores(loaded_after_write)
	if not String(args.capture_dir).is_empty():
		await get_tree().process_frame
		await _capture_named("menu_scores_top10_normal.png")
	validation_probe["scores_probe"] = probe

func _run_failure_score_probe() -> void:
	probe_mode = "failure_score_probe"
	ScoreStore.clear_scores(score_save_path)
	ScoreStore.add_score({
		"score": 9000,
		"result": "probe_seed",
		"created_at": Time.get_datetime_string_from_system(false, true)
	}, score_save_path)
	game_time = 30.0
	kills = 1
	cats_fired = 3
	upgrade_count = 0
	player.hp = 0.0
	_finish_run("failure")
	var first_failure := last_result_summary.duplicate(true)
	if not String(args.capture_dir).is_empty():
		await get_tree().process_frame
		await _capture_named("result_failure_score_normal.png")
	start_new_run()
	var after_replay := make_snapshot()
	game_time = 180.0
	kills = 1200
	cats_fired = 40
	upgrade_count = 3
	player.hp = 0.0
	_finish_run("failure")
	var record_failure := last_result_summary.duplicate(true)
	_request_exit()
	validation_probe["failure_score_probe"] = {
		"first_failure": first_failure,
		"record_failure": record_failure,
		"buttons": ["退出", "重玩"],
		"after_replay": after_replay,
		"exit_requested": exit_requested,
		"quit_intercepted": quit_intercepted,
		"returned_to_start_menu_after_exit": false
	}

func _run_bgm_probe() -> void:
	start_new_run()
	var status: Dictionary = sfx.bgm_status()
	status["playing_in_combat"] = bool(status.get("playing", false)) and game_state == "combat"
	status["play_requested_in_combat"] = bool(status.get("play_requested", false)) and game_state == "combat"
	status["audio_readme_contains_source_record"] = _file_contains("res://assets/audio/README.md", "39995331_da2-1-16.mp4") and _file_contains("res://assets/audio/README.md", "background_bgm_01.ogg")
	status["audio_licenses_omits_user_bgm_mapping"] = not _file_contains("res://assets/audio/LICENSES.md", "background_bgm_01.ogg")
	validation_probe["bgm_probe"] = status

func _file_contains(path: String, needle: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()
	return text.contains(needle)

func _start_pause_probe(input_label: String) -> void:
	_setup_pause_probe_scene()
	probe_mode = "pause"
	probe_elapsed = 0.0
	probe_sample_elapsed = 0.0
	pause_probe_reported = false
	validation_probe["pause"] = {
		"input": input_label,
		"required_wait_seconds": 3.0,
		"before_pause": _probe_state()
	}
	_record_event("pause_input", {"key": input_label})
	_toggle_pause()
	validation_probe["pause"]["paused_start"] = _probe_state()

func _start_movement_probe() -> void:
	probe_mode = "movement"
	probe_elapsed = 0.0
	movement_probe_reported = false
	validation_probe["movement"] = {
		"before_move": _probe_state(),
		"forced_input": [1.0, 0.0]
	}

func _run_input_probe() -> void:
	var original_pos: Vector2 = player.global_position
	var samples := []
	var sample_defs := [
		{"name": "W", "actions": ["move_up"], "keys": ["W"]},
		{"name": "A", "actions": ["move_left"], "keys": ["A"]},
		{"name": "S", "actions": ["move_down"], "keys": ["S"]},
		{"name": "D", "actions": ["move_right"], "keys": ["D"]},
		{"name": "ArrowUp", "actions": ["move_up"], "keys": ["Up"]},
		{"name": "ArrowLeft", "actions": ["move_left"], "keys": ["Left"]},
		{"name": "ArrowDown", "actions": ["move_down"], "keys": ["Down"]},
		{"name": "ArrowRight", "actions": ["move_right"], "keys": ["Right"]},
		{"name": "W+D", "actions": ["move_up", "move_right"], "keys": ["W", "D"]},
		{"name": "W+A", "actions": ["move_up", "move_left"], "keys": ["W", "A"]},
		{"name": "S+D", "actions": ["move_down", "move_right"], "keys": ["S", "D"]},
		{"name": "S+A", "actions": ["move_down", "move_left"], "keys": ["S", "A"]},
		{"name": "ArrowUp+ArrowRight", "actions": ["move_up", "move_right"], "keys": ["Up", "Right"]},
		{"name": "ArrowDown+ArrowLeft", "actions": ["move_down", "move_left"], "keys": ["Down", "Left"]}
	]
	for def in sample_defs:
		player.reset_player()
		var before: Vector2 = player.global_position
		for action in def["actions"]:
			Input.action_press(String(action))
		player.step_player(1.0, true)
		for action in def["actions"]:
			Input.action_release(String(action))
		var after: Vector2 = player.global_position
		samples.append({
			"name": def["name"],
			"keys": def["keys"],
			"actions": def["actions"],
			"before": _point(before),
			"after": _point(after),
			"distance": snappedf(before.distance_to(after), 0.01),
			"speed_per_second": snappedf(before.distance_to(after), 0.01)
		})
	player.global_position = original_pos
	validation_probe["input"] = {
		"input_map": _input_map_report(),
		"samples": samples,
		"single_axis_expected_speed": GameConfig.PLAYER["speed"],
		"diagonal_uses_normalized_vector": true
	}
	_record_event("input_probe_completed", {"samples": samples.size()})

func _start_xp_probe() -> void:
	probe_mode = "xp"
	probe_elapsed = 0.0
	probe_sample_elapsed = 0.0
	xp_probe_reported = false
	spawn_timer = 999.0
	for enemy in enemies:
		enemy.deactivate()
	for cat in cats:
		cat.deactivate()
	for milk in milk_drops:
		milk.deactivate()
	for orb in xp_orbs:
		orb.deactivate()
	xp = 0
	level_index = 0
	var inside_pos: Vector2 = player.global_position + Vector2(280.0, 0.0)
	var outside_pos: Vector2 = player.global_position + Vector2(330.0, 0.0)
	xp_orbs[0].setup(inside_pos, 8)
	xp_orbs[1].setup(outside_pos, 9)
	validation_probe["xp_absorb"] = {
		"config": {
			"pickup_range": GameConfig.XP["pickup_range"],
			"speed": GameConfig.XP["speed"],
			"player_radius": GameConfig.PLAYER["radius"]
		},
		"samples": []
	}
	_record_xp_probe_sample("initial")

func _setup_pause_probe_scene() -> void:
	spawn_timer = 999.0
	unlocked_weapons = ["orange", "black", "cow"]
	for kind in weapon_cooldowns.keys():
		weapon_cooldowns[kind] = 99.0
	var normal = _spawn_enemy("normal", player.global_position + Vector2(320, 0))
	var ranged = _spawn_enemy("ranged", player.global_position + Vector2(-430, -80))
	if ranged != null:
		_spawn_milk(ranged, (player.global_position - ranged.global_position).normalized())
	var cat = _inactive_cat()
	if cat != null and normal != null:
		cat.setup("orange", player.global_position + Vector2(70, -20), Vector2.RIGHT, _cat_stat("orange", "damage"), _cat_stat("orange", "speed"), normal.global_position)
		cats_fired += 1
		cat_fire_counts["orange"] = int(cat_fire_counts["orange"]) + 1
	xp_orbs[0].setup(player.global_position + Vector2(250, 120), 8)

func _run_restart_probe(result: String) -> void:
	if result == "victory":
		game_time = 240.0
		current_wave = 5
		previous_wave = 5
		kills = 42
		upgrade_count = 5
		unlocked_weapons = ["orange", "black", "cow"]
	else:
		game_time = 96.0
		player.hp = 0.0
	_finish_run(result)
	var key := "restart_%s" % result
	validation_probe[key] = {
		"before_restart": make_snapshot()
	}
	start_new_run()
	validation_probe[key]["after_restart"] = make_snapshot()
	_record_event("restart_probe_completed", {"result": result})

func _step_validation_probe(delta: float) -> void:
	if probe_mode.is_empty():
		return
	probe_elapsed += delta
	probe_sample_elapsed += delta
	if probe_mode == "menu_probe" and game_state == "combat" and game_time >= 5.0:
		validation_probe["menu_probe"]["after_start_game"] = make_snapshot()
		_record_event("menu_probe_completed", {})
		probe_mode = ""
	elif probe_mode == "pause" and not pause_probe_reported and probe_elapsed >= 3.0:
		validation_probe["pause"]["paused_after_wait"] = _probe_state()
		validation_probe["pause"]["paused_elapsed_seconds"] = snappedf(probe_elapsed, 0.01)
		_record_event("resume_input", {"key": validation_probe["pause"]["input"]})
		_resume_from_pause()
		validation_probe["pause"]["after_resume"] = _probe_state()
		_record_event("pause_probe_completed", {})
		pause_probe_reported = true
		probe_mode = ""
	elif probe_mode == "movement" and not movement_probe_reported and probe_elapsed >= 0.85:
		validation_probe["movement"]["after_move"] = _probe_state()
		_record_event("movement_probe_completed", {})
		movement_probe_reported = true
		probe_mode = ""
	elif probe_mode == "xp":
		if probe_sample_elapsed >= 0.05:
			probe_sample_elapsed = 0.0
			_record_xp_probe_sample("sample")
		if not xp_probe_reported and probe_elapsed >= 0.75:
			_record_xp_probe_sample("final")
			_finish_xp_probe_summary()
			_record_event("xp_probe_completed", {})
			xp_probe_reported = true
			probe_mode = ""

func _validation_move_vector() -> Vector2:
	if probe_mode == "movement" and not movement_probe_reported:
		return Vector2.RIGHT
	return Vector2.ZERO

func _probe_state() -> Dictionary:
	return {
		"game_state": game_state,
		"game_time": game_time,
		"player_position": _point(player.global_position),
		"player_hp": player.hp,
		"enemy_count": _active_count(enemies),
		"enemy_positions": _enemy_snapshots(),
		"cat_projectile_count": _active_count(cats),
		"cat_positions": _cat_snapshots(),
		"milk_drop_count": _active_count(milk_drops),
		"milk_positions": _milk_snapshots(),
		"xp_orb_count": _active_count(xp_orbs),
		"xp_positions": _xp_snapshots()
	}

func _enemy_snapshots(limit := 8) -> Array:
	var result := []
	for enemy in enemies:
		if enemy.active:
			result.append({
				"type": enemy.enemy_type,
				"position": _point(enemy.global_position),
				"hp": snappedf(enemy.hp, 0.01)
			})
			if result.size() >= limit:
				break
	return result

func _cat_snapshots(limit := 8) -> Array:
	var result := []
	for cat in cats:
		if cat.active:
			result.append({
				"type": cat.cat_type,
				"position": _point(cat.global_position),
				"velocity": _point(cat.velocity)
			})
			if result.size() >= limit:
				break
	return result

func _milk_snapshots(limit := 8) -> Array:
	var result := []
	for milk in milk_drops:
		if milk.active:
			result.append({
				"position": _point(milk.global_position),
				"velocity": _point(milk.velocity)
			})
			if result.size() >= limit:
				break
	return result

func _xp_snapshots(limit := 8) -> Array:
	var result := []
	for i in xp_orbs.size():
		var orb = xp_orbs[i]
		if orb.active:
			result.append({
				"index": i,
				"position": _point(orb.global_position),
				"distance_to_player": snappedf(orb.global_position.distance_to(player.global_position), 0.01),
				"attracting": orb.attracting,
				"value": orb.value
			})
			if result.size() >= limit:
				break
	return result

func _record_xp_probe_sample(label: String) -> void:
	if not validation_probe.has("xp_absorb"):
		return
	var entries := []
	for i in 2:
		var orb = xp_orbs[i]
		entries.append({
			"index": i,
			"active": orb.active,
			"attracting": orb.attracting,
			"position": _point(orb.global_position),
			"distance_to_player": snappedf(orb.global_position.distance_to(player.global_position), 0.01),
			"value": orb.value
		})
	validation_probe["xp_absorb"]["samples"].append({
		"label": label,
		"time": snappedf(probe_elapsed, 0.001),
		"player_position": _point(player.global_position),
		"orbs": entries,
		"xp": xp
	})

func _finish_xp_probe_summary() -> void:
	var samples: Array = validation_probe["xp_absorb"]["samples"]
	var inside_speeds := []
	var outside_distances := []
	for i in range(1, samples.size()):
		var prev: Dictionary = samples[i - 1]
		var curr: Dictionary = samples[i]
		var dt := float(curr["time"]) - float(prev["time"])
		if dt <= 0.0:
			continue
		var prev_inside: Dictionary = prev["orbs"][0]
		var curr_inside: Dictionary = curr["orbs"][0]
		if bool(prev_inside["active"]) and bool(curr_inside["active"]):
			var moved := Vector2(float(prev_inside["position"][0]), float(prev_inside["position"][1])).distance_to(Vector2(float(curr_inside["position"][0]), float(curr_inside["position"][1])))
			if moved > 0.001:
				inside_speeds.append(snappedf(moved / dt, 0.01))
		var outside: Dictionary = curr["orbs"][1]
		outside_distances.append(float(outside["distance_to_player"]))
	var speed_avg := 0.0
	for value in inside_speeds:
		speed_avg += float(value)
	if not inside_speeds.is_empty():
		speed_avg /= inside_speeds.size()
	validation_probe["xp_absorb"]["summary"] = {
		"inside_orb_start_distance": 280.0,
		"outside_orb_start_distance": 330.0,
		"inside_orb_attracted": _xp_sample_has_attraction(samples, 0),
		"outside_orb_attracted": _xp_sample_has_attraction(samples, 1),
		"inside_observed_speeds": inside_speeds,
		"inside_observed_speed_avg": snappedf(speed_avg, 0.01),
		"outside_distances": outside_distances,
		"xp_after_collection": xp
	}

func _xp_sample_has_attraction(samples: Array, orb_index: int) -> bool:
	for sample in samples:
		var orb: Dictionary = sample["orbs"][orb_index]
		if bool(orb["attracting"]):
			return true
	return false

func _input_map_report() -> Dictionary:
	var action_names := ["move_up", "move_down", "move_left", "move_right", "pause_game"]
	var result := {}
	for action_name in action_names:
		var events := []
		for event in InputMap.action_get_events(action_name):
			events.append(event.as_text())
		result[action_name] = events
	return result

func _auto_play_vector() -> Vector2:
	var candidates := [Vector2.ZERO]
	for i in 24:
		candidates.append(Vector2.RIGHT.rotated(TAU * float(i) / 24.0))
	var best_dir := Vector2.RIGHT.rotated(game_time * 0.42)
	var best_score := -INF
	var survival_focus := current_wave >= 5 or (current_wave >= 4 and upgrade_count >= 5)
	var step_distance: float = float(GameConfig.PLAYER["speed"]) * player.speed_multiplier * (0.52 if survival_focus else 0.58)
	var player_radius: float = float(GameConfig.PLAYER["radius"])
	for dir in candidates:
		var pos: Vector2 = player.global_position + dir * step_distance
		var score := 0.0
		if pos.x < 96.0 or pos.x > GameConfig.MAP_SIZE.x - 96.0 or pos.y < 96.0 or pos.y > GameConfig.MAP_SIZE.y - 96.0:
			score -= 6000.0
		score -= pos.distance_to(GameConfig.PLAYER_START) * (0.00025 if survival_focus else 0.0008)
		score += dir.dot(Vector2.RIGHT.rotated(game_time * 0.42)) * 0.08
		for enemy in enemies:
			if not enemy.active:
				continue
			var distance: float = pos.distance_to(enemy.global_position)
			var weight := 1.0
			if enemy.enemy_type == "calf":
				weight = 1.7
			elif enemy.enemy_type == "tank":
				weight = 1.25
			elif enemy.enemy_type == "ranged":
				weight = 1.35
			if survival_focus:
				weight *= 1.35
			elif current_wave >= 4:
				weight *= 1.08
			var contact_distance: float = float(enemy.stats["radius"]) + player_radius + (145.0 if survival_focus else 80.0)
			if distance < contact_distance:
				score -= (contact_distance - distance) * (125.0 if survival_focus else 95.0) * weight + (6800.0 if survival_focus else 4500.0)
			elif distance < (980.0 if survival_focus else 820.0):
				var danger_range := 980.0 if survival_focus else 820.0
				score -= (danger_range - distance) * (1.18 if survival_focus else 0.9) * weight
			if survival_focus:
				var to_player: Vector2 = (player.global_position - enemy.global_position).normalized()
				var projected_pos: Vector2 = enemy.global_position + to_player * float(enemy.stats["speed"]) * 0.82
				var projected_distance: float = pos.distance_to(projected_pos)
				if projected_distance < contact_distance + 70.0:
					score -= (contact_distance + 70.0 - projected_distance) * 72.0 * weight + 2200.0
		for milk in milk_drops:
			if not milk.active:
				continue
			var milk_distance: float = pos.distance_to(milk.global_position)
			var milk_close := 320.0 if survival_focus else 260.0
			var milk_far := 620.0 if survival_focus else 520.0
			if milk_distance < milk_close:
				score -= (milk_close - milk_distance) * (52.0 if survival_focus else 34.0) + (2400.0 if survival_focus else 1600.0)
			elif milk_distance < milk_far:
				score -= (milk_far - milk_distance) * (1.0 if survival_focus else 0.65)
			if survival_focus:
				var milk_future: Vector2 = milk.global_position + milk.velocity * 0.42
				var milk_future_distance: float = pos.distance_to(milk_future)
				if milk_future_distance < 320.0:
					score -= (320.0 - milk_future_distance) * 46.0 + 1800.0
		for orb in xp_orbs:
			if not orb.active:
				continue
			var xp_distance: float = pos.distance_to(orb.global_position)
			if upgrade_count < 6 and xp_distance < 520.0:
				score += (520.0 - xp_distance) * 0.04
			elif upgrade_count >= 6 and game_time < 235.0 and xp_distance < 900.0:
				score -= (900.0 - xp_distance) * 0.04
		if score > best_score:
			best_score = score
			best_dir = dir
	if best_dir.length_squared() < 0.001:
		return Vector2.RIGHT.rotated(game_time * 0.42)
	return best_dir.normalized()

func _spawn_milk(enemy, direction: Vector2) -> void:
	if _active_count(milk_drops) >= GameConfig.LIMITS["milk"]:
		return
	for milk in milk_drops:
		if not milk.active:
			milk.setup(enemy.global_position + direction * 54.0, direction, enemy)
			sfx.play_event("milk_launch")
			_record_event("milk_fired", {
				"enemy_type": enemy.enemy_type,
				"position": _point(enemy.global_position),
				"direction": _point(direction)
			})
			return

func _spawn_xp(pos: Vector2, amount: int) -> void:
	for orb in xp_orbs:
		if not orb.active:
			var spawn_pos := pos + Vector2(rng.randf_range(-18, 18), rng.randf_range(-18, 18))
			orb.setup(spawn_pos, amount)
			_record_event("xp_spawned", {
				"value": amount,
				"position": _point(spawn_pos)
			})
			return

func _inactive_cat():
	for cat in cats:
		if not cat.active:
			return cat
	return null

func _active_count(list: Array) -> int:
	var count := 0
	for node in list:
		if node.active:
			count += 1
	return count

func _active_cat_count(kind: String) -> int:
	var count := 0
	for cat in cats:
		if cat.active and cat.cat_type == kind:
			count += 1
	return count

func _active_enemies() -> Array:
	var list := []
	for enemy in enemies:
		if enemy.active:
			list.append(enemy)
	return list

func _toggle_pause() -> void:
	if game_state == "combat":
		previous_state = game_state
		game_state = "paused"
		ui.show_pause()
		_record_event("paused", {"time": game_time})
	elif game_state == "paused":
		_resume_from_pause()

func _resume_from_pause() -> void:
	if game_state == "paused":
		game_state = previous_state
		ui.clear_popups()
		_record_event("resumed", {"time": game_time})

func _finish_run(result: String) -> void:
	if game_state == "victory" or game_state == "failure":
		return
	game_state = result
	var score := GameConfig.score_for_stats(game_time, kills, cats_fired, upgrade_count, result)
	var score_entry := {
		"score": score,
		"result": result,
		"game_time": game_time,
		"kills": kills,
		"cats_fired": cats_fired,
		"upgrade_count": upgrade_count,
		"created_at": Time.get_datetime_string_from_system(false, true)
	}
	last_result_summary = ScoreStore.add_score(score_entry, score_save_path)
	sfx.play_event("victory" if result == "victory" else "defeat")
	_record_event("run_finished", {
		"result": result,
		"time": game_time,
		"player_hp": player.hp,
		"upgrade_count": upgrade_count,
		"kills": kills,
		"score": score,
		"is_new_record": bool(last_result_summary.get("is_new_record", false))
	})
	ui.update_hud(make_snapshot())
	ui.show_result(result, make_snapshot())
	if not String(args.capture_dir).is_empty():
		await get_tree().process_frame
		ui.update_hud(make_snapshot())
		await get_tree().process_frame
		_capture_named("result_%s_normal.png" % result)

func _finish_validation_and_quit() -> void:
	if report_written:
		return
	var data := make_snapshot()
	data["validation_args"] = args
	data["sfx_loaded_events"] = sfx.loaded_events()
	data["sfx_missing"] = sfx.missing
	data["sfx_trigger_counts"] = sfx.triggered_events()
	data["bgm_status"] = sfx.bgm_status()
	data["validation_probe"] = validation_probe.duplicate(true)
	ValidationTools.write_json(String(args.validation_report), data)
	report_written = true
	sfx.shutdown()
	await get_tree().process_frame
	get_tree().quit()

func make_snapshot() -> Dictionary:
	return {
		"player_hp": player.hp if player != null else 0.0,
		"player_max_hp": player.max_hp if player != null else GameConfig.PLAYER["max_hp"],
		"player_position": _point(player.global_position) if player != null else [0.0, 0.0],
		"player_bounds": {
			"min": [40.0, 40.0],
			"max": _point(GameConfig.MAP_SIZE - Vector2(40.0, 40.0))
		},
		"current_wave": current_wave,
		"wave_progress": GameConfig.wave_progress(game_time),
		"game_time": game_time,
		"game_state": game_state,
		"enemy_count": _active_count(enemies),
		"cat_projectile_count": _active_count(cats),
		"milk_drop_count": _active_count(milk_drops),
		"xp_orb_count": _active_count(xp_orbs),
		"kills": kills,
			"xp": xp,
			"xp_needed": GameConfig.xp_needed(level_index),
			"upgrade_count": upgrade_count,
			"upgrade_levels": upgrade_levels.duplicate(true),
			"wave_spawn_counts": wave_spawn_counts.duplicate(true),
			"upgrade_multipliers": {
				"cooldown": _upgrade_multiplier("cooldown"),
				"damage": _upgrade_multiplier("damage"),
				"cat_speed": _upgrade_multiplier("cat_speed"),
			"player_speed": _upgrade_multiplier("player_speed")
		},
		"unlocked_weapons": unlocked_weapons.duplicate(),
		"cats_fired": cats_fired,
		"cat_fire_counts": cat_fire_counts.duplicate(true),
		"cat_damage_done": cat_damage_done.duplicate(true),
		"favorite_cat": _favorite_cat_name(),
		"highest_damage_cat": _highest_damage_cat_name(),
		"score": int(last_result_summary.get("entry", {}).get("score", GameConfig.score_for_stats(game_time, kills, cats_fired, upgrade_count, game_state))),
		"is_new_record": bool(last_result_summary.get("is_new_record", false)),
		"score_save_path": score_save_path,
		"score_save_global_path": ScoreStore.globalized_path(score_save_path),
		"top_scores": ScoreStore.load_scores(score_save_path),
		"last_result_summary": last_result_summary.duplicate(true),
		"exit_requested": exit_requested,
		"quit_intercepted": quit_intercepted,
		"ui_screen": ui.current_screen if ui != null else "",
		"bgm_status": sfx.bgm_status() if sfx != null else {},
		"seed": int(args.seed),
		"debug_mode": String(args.debug_mode),
		"debug_overlay_enabled": debug_overlay,
		"event_counts": event_counts.duplicate(true),
		"event_log_sample": event_log.duplicate(true),
		"pool_limits": GameConfig.LIMITS.duplicate(true),
		"node_count": get_tree().get_node_count()
	}

func _record_event(kind: String, data: Dictionary) -> void:
	event_counts[kind] = int(event_counts.get(kind, 0)) + 1
	if event_log.size() >= 240:
		return
	var entry := {
		"time": game_time,
		"kind": kind,
		"data": data.duplicate(true)
	}
	event_log.append(entry)

func _point(value: Vector2) -> Array:
	return [snappedf(value.x, 0.01), snappedf(value.y, 0.01)]

func _favorite_cat_name() -> String:
	var best := "orange"
	var count := -1
	for key in cat_fire_counts.keys():
		if int(cat_fire_counts[key]) > count:
			count = int(cat_fire_counts[key])
			best = key
	return GameConfig.CAT_STATS[best]["name"]

func _highest_damage_cat_name() -> String:
	var best := "orange"
	var amount := -1.0
	for key in cat_damage_done.keys():
		if float(cat_damage_done[key]) > amount:
			amount = float(cat_damage_done[key])
			best = key
	return GameConfig.CAT_STATS[best]["name"]

func _step_vfx(delta: float) -> void:
	if shake_left > 0.0:
		shake_left = max(0.0, shake_left - delta)
		player.camera.offset = Vector2(rng.randf_range(-5.0, 5.0), rng.randf_range(-5.0, 5.0)) * (shake_left / 0.12)
	else:
		player.camera.offset = Vector2.ZERO
	for item in vfx_items.duplicate():
		if not is_instance_valid(item):
			vfx_items.erase(item)
			continue
		item.set_meta("life", float(item.get_meta("life")) - delta)
		var life := float(item.get_meta("life"))
		var start := float(item.get_meta("start_life"))
		item.modulate.a = clamp(life / start, 0.0, 1.0)
		item.scale *= 1.0 + delta * 0.9
		if life <= 0.0:
			vfx_items.erase(item)
			item.queue_free()

func _spawn_texture_vfx(pos: Vector2, texture_path: String, life: float, scale_value: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(texture_path)
	sprite.global_position = pos
	sprite.scale = scale_value
	sprite.set_meta("life", life)
	sprite.set_meta("start_life", life)
	vfx_layer.add_child(sprite)
	vfx_items.append(sprite)

func _spawn_notice_vfx(pos: Vector2, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 30)
	label.global_position = pos
	label.set_meta("life", 1.4)
	label.set_meta("start_life", 1.4)
	vfx_layer.add_child(label)
	vfx_items.append(label)

func _step_capture(delta: float) -> void:
	if String(args.capture_dir).is_empty():
		return
	capture_elapsed += delta
	if capture_elapsed >= 0.25 and capture_count < 12 and game_state == "combat":
		capture_elapsed = 0.0
		_capture_named("frames/combat_frame_%03d_normal.png" % capture_count)
		capture_count += 1
	if game_state == "upgrade" and capture_count < 20:
		_capture_named("upgrade_modal_normal.png")
		capture_count = 20

func _capture_name_for_state() -> String:
	if game_state == "menu":
		if ui.current_screen == "scores":
			return "menu_scores_empty_normal.png"
		if ui.current_screen == "developers":
			return "menu_developers_normal.png"
		return "menu_start_normal.png"
	if game_state == "upgrade":
		return "upgrade_modal_normal.png"
	if game_state == "victory" or game_state == "failure":
		return "result_%s_normal.png" % game_state
	if game_state == "paused":
		return "pause_normal.png"
	return "combat_hud_normal.png"

func _capture_named(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var base := String(args.capture_dir)
	if base.is_empty():
		return
	var full_path := base.path_join(file_name)
	ValidationTools.ensure_dir(full_path.get_base_dir())
	ValidationTools.save_viewport_png(get_viewport(), full_path)

func _draw() -> void:
	if not debug_overlay:
		return
	for enemy in enemies:
		if enemy.active:
			draw_circle(to_local(enemy.global_position), float(enemy.stats["radius"]), Color(1, 0, 0, 0.18))
	draw_circle(to_local(player.global_position), GameConfig.XP["pickup_range"], Color(0, 0.8, 1, 0.12))
