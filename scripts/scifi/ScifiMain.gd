extends Node2D

# Emitted after a completed physics update to support exact-tick replay observation.
signal physics_advanced(tick_id: int)

const C = preload("res://scripts/scifi/ScifiConfig.gd")
const Actor = preload("res://scripts/scifi/ScifiActor.gd")
const Terrain = preload("res://scripts/scifi/ScifiWorldCollision.gd")
const Combat = preload("res://scripts/scifi/ScifiCombat.gd")
const Progress = preload("res://scripts/scifi/ScifiProgress.gd")
const Sound = preload("res://scripts/SfxBus.gd")
const Scores = preload("res://scripts/ScoreStore.gd")
var ui:CanvasLayer
var sound:Node
var player:Node2D
var camera:Camera2D
var world:Node2D
var world_collision: Node2D
var progress:RefCounted
var combat:RefCounted
var state = "menu"
var time = 0.0
var tick = 0
var stage = 0
var seed_value = 17
var rng = RandomNumberGenerator.new()
var run_id = ""
var hp = 120.0
var max_hp = 120.0
var velocity = Vector2.ZERO
var facing = Vector2.DOWN
var invulnerable = 0.0
var shield = 0.0
var dash_direction = Vector2.DOWN
var dash_remaining = 0.0
var weapons:Dictionary = {}
var passives:Dictionary = {}
var skills:Array = []
var cards:Array = []
var pending_upgrades = 0
var level = 1
var xp = 0
var kills = 0
var credits = 0
var milestones = 0
var boss_count = 0
var spawn_timer = 0.0
var spawning = true
var pools:Dictionary = {"enemies":[],"projectiles":[],"enemy_projectiles":[],"xp":[],"vfx":[]}
var pool_stats:Dictionary = {}
var events:Array = []
var event_serial = 0
var entity_serial = 0
var loaded_resources:Array = []
var texture_cache:Dictionary = {}
var test_scenario = ""
var test_report = ""
var test_save = ""
var won_result = false
var result_summary:Dictionary = {}
var ui_timer = 0.0
var confirmation_previous = ""
# View-only impact response. No time_scale, simulation RNG or physics changes.
var shake_remaining := 0.0
var shake_duration := 0.15
var shake_strength := 0.0
var shake_phase := 0.0
var shake_next_time := -1.0

func _process(delta: float) -> void:
	if camera == null: return
	if state != "playing" or shake_remaining <= 0.0:
		camera.offset = Vector2.ZERO
		return
	shake_remaining = maxf(0.0, shake_remaining - delta)
	shake_phase += delta * 95.0
	var fade := shake_remaining / shake_duration
	camera.offset = Vector2(sin(shake_phase * 1.13), cos(shake_phase * 1.71)) * shake_strength * fade * (sound.shake_level if sound != null else 1.0)
	if shake_remaining <= 0.0:
		camera.offset = Vector2.ZERO
		shake_strength = 0.0

func camera_impact(power: float, force: bool = false) -> void:
	if not force and time < shake_next_time: return
	shake_next_time = time + 0.11
	shake_duration = 0.18 if force else 0.12
	shake_remaining = shake_duration
	shake_strength = minf(14.0, maxf(power, shake_strength * 0.55))


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="): seed_value = int(arg.get_slice("=",1))
		if arg.begins_with("--scifi-test="): test_scenario = arg.get_slice("=",1)
		if arg.begins_with("--scifi-report="): test_report = arg.trim_prefix("--scifi-report=")
		if arg.begins_with("--scifi-save="): test_save = arg.trim_prefix("--scifi-save=")
	get_tree().auto_accept_quit = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rng.seed = seed_value
	progress = Progress.new(test_save)
	combat = Combat.new(self)
	_setup_inputs()
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	var map = Sprite2D.new()
	map.texture = texture("res://assets/sprites/scifi/map_detail.png")
	map.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR # High-resolution map only; character pixels remain sharp.
	map.centered = false
	map.z_index = -100
	add_child(map)
	world_collision = Terrain.new()
	world_collision.name = "WorldObstacles"
	add_child(world_collision)
	player = Actor.new()
	player.configure("1103",3)
	player.position = C.MAP_SIZE/2
	world.add_child(player)
	camera = Camera2D.new()
	camera.position = player.position
	camera.zoom = Vector2.ONE
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(C.MAP_SIZE.x)
	camera.limit_bottom = int(C.MAP_SIZE.y)
	add_child(camera)
	sound = Sound.new()
	add_child(sound)
	var ui_script = load("res://scripts/scifi/ScifiUI.gd")
	if ui_script != null and ui_script.can_instantiate():
		ui = ui_script.new()
		add_child(ui)
		ui.deploy_requested.connect(start_run)
		ui.upgrade_selected.connect(choose_card)
		ui.skill_requested.connect(use_skill)
		ui.purchase_requested.connect(purchase_upgrade)
		ui.retry_save_requested.connect(retry_save)
		ui.menu_requested.connect(_request_menu)
		ui.quit_requested.connect(_request_quit)
		ui.pause_requested.connect(toggle_pause)
		ui.settings_changed.connect(func(value: Dictionary) -> void: sound.set_preferences(value))
		ui.tutorial_finished.connect(_mark_tutorial_seen)
		ui.set_preferences(sound.preferences())
	for key in pools:
		pool_stats[key] = {"allocated":0,"reuses":0,"peak":0}
	show_menu()
	if not progress.error.is_empty() and ui != null:
		ui.show_notice(progress.error)
	if test_scenario.is_empty() and ui != null:
		var tutorial_config := ConfigFile.new()
		if tutorial_config.load("user://scifi_tutorial_v1.cfg") != OK or not bool(tutorial_config.get_value("tutorial","completed",false)):
			ui.show_tutorial(0)
	if not test_scenario.is_empty():
		var script = load("res://scripts/scifi/tests/ScifiTests.gd")
		if script != null:
			var test = script.new()
			add_child(test)
			test.call_deferred("run",self,test_scenario,test_report)

func _exit_tree() -> void:
	if sound != null:
		sound.shutdown()
	combat.thermal_field.clear()
	texture_cache.clear()

func _setup_inputs() -> void:
	for spec in [["skill_0",KEY_SPACE],["skill_1",KEY_E]]:
		if not InputMap.has_action(spec[0]):
			InputMap.add_action(spec[0])
			var input = InputEventKey.new()
			input.physical_keycode = spec[1]
			InputMap.action_add_event(spec[0],input)

func texture(path:String) -> Texture2D:
	if not texture_cache.has(path):
		texture_cache[path] = load(path) if ResourceLoader.exists(path) else null
		if texture_cache[path] != null:
			loaded_resources.append(path)
	return texture_cache[path]

func _unhandled_input(event:InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		toggle_pause()
	if event.is_action_pressed("skill_0"): use_skill(0)
	if event.is_action_pressed("skill_1"): use_skill(1)

func _notification(what:int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_request_quit()

func meta(key:String) -> int:
	return int(progress.data.upgrades.get(key,0))

func _mark_tutorial_seen() -> void:
	if not test_scenario.is_empty(): return
	var config := ConfigFile.new()
	config.set_value("tutorial","completed",true)
	if config.save("user://scifi_tutorial_v1.cfg") != OK:
		push_warning("Unable to save tutorial completion")

func show_menu() -> void:
	state = "menu"
	if ui != null:
		var score_path = test_save.path_join("huazi_scores.json") if not test_save.is_empty() else ""
		ui.show_menu(progress.snapshot(),Scores.load_scores(score_path))

func start_run(loadout:Dictionary) -> bool:
	if not C.valid_loadout(loadout) or not progress.pending.is_empty() or state == "playing" or state == "upgrade" or state == "paused":
		return false
	if not progress.save_loadout(loadout):
		record("save",{"ok":false,"error":progress.error})
		if ui != null: ui.show_notice(progress.error)
		return false
	clear_arena()
	rng.seed = seed_value
	time = 0.0
	tick = 0
	stage = 0
	level = 1
	xp = 0
	kills = 0
	credits = 0
	milestones = 0
	boss_count = 0
	spawn_timer = 0.0
	spawning = true
	max_hp = C.PLAYER.hp*(1+C.ECONOMY.hp*meta("hp"))
	hp = max_hp
	invulnerable = 0.0
	shield = 0.0
	dash_remaining = 0.0
	velocity = Vector2.ZERO
	shake_remaining = 0.0
	shake_strength = 0.0
	shake_next_time = -1.0
	camera.offset = Vector2.ZERO
	facing = Vector2.DOWN
	player.position = C.MAP_SIZE/2
	weapons = {loadout.weapon:{"level":1,"evolved":false,"remaining":0.0}}
	passives.clear()
	for key in C.MODS: passives[key] = 0
	skills.clear()
	for key in loadout.skills: skills.append({"key":key,"remaining":0.0,"duration":0.0,"cooldown":C.SKILLS[key].cooldown*(1-C.ECONOMY.skill_cd*meta("skill_cd"))})
	cards.clear()
	pending_upgrades = 0
	won_result = false
	result_summary.clear()
	run_id = "%d-%d-%d" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),seed_value]
	state = "playing"
	if ui != null: ui.clear_popups()
	sound.start_bgm()
	record("run_start",{"loadout":loadout,"run_id":run_id,"seed":seed_value})
	return true

func _physics_process(delta:float) -> void:
	if state != "playing":
		freeze_actors(true)
		return
	freeze_actors(false)
	tick += 1
	time += delta
	var previous_stage = stage
	stage = mini(4,int(time/120.0))
	if previous_stage != stage:
		record("stage",{"stage":stage})
		audio("stage")
	_accrue_milestones()
	invulnerable = maxf(0,invulnerable-delta)
	for skill in skills:
		skill.remaining = maxf(0,skill.remaining-delta)
		skill.duration = maxf(0,skill.duration-delta)
		if skill.key == "shield" and skill.duration <= 0: shield = 0
	velocity = Input.get_vector("move_left","move_right","move_up","move_down")*C.PLAYER.speed
	if velocity.length_squared() > 0.01: facing = velocity.normalized()
	if dash_remaining > 0:
		player.velocity = dash_direction*C.SKILLS.dash.distance/C.SKILLS.dash.duration
		dash_remaining = maxf(0,dash_remaining-delta)
	else:
		player.velocity = velocity
	player.move_and_slide()
	player.position = player.position.clamp(C.BOUNDS.position,C.BOUNDS.end)
	player.animate(velocity)
	player.modulate = Color(1,0.55,0.45) if invulnerable > 0 and fmod(time,0.16)<0.08 else Color.WHITE
	camera.position = player.position
	if spawning:
		spawn_timer -= delta
		if spawn_timer <= 0:
			spawn_timer += C.SPAWN_INTERVALS[stage]
			_spawn_wave()
	if time >= C.BOSS.time and boss_count == 0:
		var boss = spawn_enemy("boss",(player.position+Vector2(750,0)).clamp(C.BOUNDS.position,C.BOUNDS.end))
		if not boss.is_empty(): boss_count += 1
	_update_enemies(delta)
	_update_enemy_projectiles(delta)
	combat.update(delta)
	_update_xp(delta)
	_update_effects(delta)
	if hp <= 0:
		_finish(false)
	elif boss_count > 0:
		var alive = false
		for e in pools.enemies:
			if e.active and e.kind == "boss" and e.hp > 0: alive = true
		if not alive: _finish(true)
	if state == "playing" and pending_upgrades > 0:
		_open_upgrade()
	ui_timer -= delta
	if ui_timer <= 0 and ui != null:
		ui_timer = 0.08
		ui.update_hud(snapshot(false))
	if test_scenario == "replay": physics_advanced.emit(tick)

func freeze_actors(frozen:bool) -> void:
	if player != null: player.freeze(frozen)
	for e in pools.enemies:
		if e.active: e.node.freeze(frozen)

func _spawn_wave() -> void:
	# Reserve one normal-spawn slot so the timed boss cannot be delayed by saturation.
	if boss_count == 0 and active_count("enemies") >= C.CAPS.enemies-1: return
	var types = ["crawler","spider","heavy","turret"]
	var kind = types[rng.randi_range(0,mini(stage,3))]
	var position = player.position+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(680,1000)
	spawn_enemy(kind,position.clamp(C.BOUNDS.position,C.BOUNDS.end))

func spawn_enemy(kind:String,position:Vector2,extra:Dictionary = {}) -> Dictionary:
	if not C.ENEMIES.has(kind): return {}
	var cfg = C.ENEMIES[kind]
	position = world_collision.safe_spawn(position,float(cfg.radius)) if world_collision != null else position
	var e = acquire("enemies",{"kind":kind,"position":position,"hp":cfg.hp,"max_hp":cfg.hp,"speed":cfg.speed,"contact_damage":cfg.damage,"radius":cfg.radius,"slow":0.0,"slow_time":0.0,"stun":0.0,"shoot_timer":C.RANGED.cooldown,"charge_timer":C.BOSS.charge_cd,"shot_timer":C.BOSS.shot_cd,"windup":0.0,"attack_state":"idle","attack_direction":Vector2.ZERO,"charge_duration":0.0}.merged(extra,true))
	if not e.is_empty():
		e.node.configure(cfg.asset,cfg.scale)
		e.node.position = position
		record("spawn",{"entity_id":e.id,"kind":kind,"position":[position.x,position.y]})
	return e

func _update_enemies(delta:float) -> void:
	for e in pools.enemies:
		if not e.active or e.hp <= 0: continue
		e.stun = maxf(0,e.stun-delta)
		e.slow_time = maxf(0,e.slow_time-delta)
		if e.slow_time <= 0: e.slow = 0.0
		var direction:Vector2 = e.position.direction_to(player.position)
		var move = direction*e.speed*(1-e.slow)
		if e.stun > 0:
			move = Vector2.ZERO
		elif e.kind == "turret":
			var distance = e.position.distance_to(player.position)
			move *= 1 if distance > C.RANGED.range+25 else (-1 if distance < C.RANGED.range-25 else 0)
			e.shoot_timer -= delta
			if e.shoot_timer <= 0:
				e.shoot_timer += C.RANGED.cooldown
				enemy_shot(e.position,direction*C.RANGED.speed,C.RANGED.damage,C.RANGED.life,e.id)
		elif e.kind == "boss":
			move = _boss_movement(e,move,direction,delta)
		e.node.velocity = _steer_around_obstacles(e.position,move)
		e.node.move_and_slide()
		e.node.position = e.node.position.clamp(C.BOUNDS.position,C.BOUNDS.end)
		e.position = e.node.position
		e.node.animate(move,"charge" if e.attack_state != "idle" else "")
		if e.position.distance_to(player.position) <= e.radius+C.PLAYER.radius:
			damage_player(e.contact_damage,e.id)

func _steer_around_obstacles(origin: Vector2, wanted: Vector2) -> Vector2:
	if wanted.length_squared() <= 0.001: return wanted
	var ray := PhysicsRayQueryParameters2D.create(origin,origin + wanted.normalized()*90.0,1)
	var obstruction := get_world_2d().direct_space_state.intersect_ray(ray)
	if obstruction.is_empty(): return wanted
	var along: Vector2 = obstruction.normal.orthogonal()
	var to_target: Vector2 = player.position - origin
	if along.dot(to_target) < 0.0 or (absf(along.dot(to_target)) < 0.001 and along.y < 0): along = -along
	return (wanted.normalized()*0.12 + along*0.88).normalized()*wanted.length()

func _boss_movement(e:Dictionary,move:Vector2,direction:Vector2,delta:float) -> Vector2:
	e.charge_timer -= delta
	e.shot_timer -= delta
	if e.attack_state == "charge":
		e.charge_duration -= delta
		if e.charge_duration <= 0: e.attack_state = "idle"
		return e.attack_direction*C.BOSS.charge_speed*(1-e.slow)
	if e.windup > 0:
		e.windup -= delta
		if e.windup <= 0:
			if e.attack_state == "charge_windup":
				e.attack_state = "charge"
				e.charge_duration = C.BOSS.charge_duration
				record("boss_charge",{"entity_id":e.id})
			else:
				for i in range(C.BOSS.shot_count):
					enemy_shot(e.position,e.attack_direction.rotated((i-2)*0.22)*C.BOSS.shot_speed,C.BOSS.shot_damage,C.BOSS.shot_life,e.id)
				e.attack_state = "idle"
		return Vector2.ZERO
	if e.charge_timer <= 0:
		e.charge_timer += C.BOSS.charge_cd
		e.windup = C.BOSS.charge_windup
		e.attack_state = "charge_windup"
		e.attack_direction = direction
		effect("smoke",e.position,e.windup)
		record("boss_windup",{"entity_id":e.id,"kind":"charge","duration":e.windup})
	elif e.shot_timer <= 0:
		e.shot_timer += C.BOSS.shot_cd
		e.windup = C.BOSS.shot_windup
		e.attack_state = "shot_windup"
		e.attack_direction = direction
		effect("pulse",e.position,e.windup)
		record("boss_windup",{"entity_id":e.id,"kind":"shot","duration":e.windup})
	return move

func enemy_shot(position:Vector2,motion:Vector2,damage:float,life:float,source_id:String) -> Dictionary:
	var p = acquire("enemy_projectiles",{"position":position,"velocity":motion,"damage":damage,"life":life,"source_id":source_id})
	if not p.is_empty():
		visual(p,"enemy")
		record("enemy_attack",{"entity_id":p.id,"source_id":source_id,"damage":damage,"velocity":[motion.x,motion.y]})
		audio("enemy_shot")
	return p

func _update_enemy_projectiles(delta:float) -> void:
	for p in pools.enemy_projectiles:
		if not p.active: continue
		var previous:Vector2 = p.position
		p.position += p.velocity*delta
		p.node.position = p.position
		p.life -= delta
		var wall := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(previous,p.position,1))
		if not wall.is_empty():
			effect("impact",wall.position,0.12)
			release("enemy_projectiles",p)
			continue
		if Geometry2D.get_closest_point_to_segment(player.position,previous,p.position).distance_to(player.position) <= C.PLAYER.radius+8:
			damage_player(p.damage,p.source_id)
			release("enemy_projectiles",p)
		elif p.life <= 0: release("enemy_projectiles",p)

func damage_player(amount:float,source_id:String,bypass:bool = false) -> void:
	if state != "playing" or (not bypass and (invulnerable > 0 or dash_remaining > 0)): return
	var absorbed = minf(shield,amount)
	shield -= absorbed
	hp = maxf(0,hp-(amount-absorbed))
	invulnerable = C.PLAYER.iframe
	record("hit",{"entity_id":"player","source_id":source_id,"amount":amount,"absorbed":absorbed,"hp":hp})
	player.impact_feedback(-facing, true, "hurt")
	camera_impact(13.0, true)
	effect("impact",player.position,0.25)
	audio("hurt")

func hit_enemy(enemy:Dictionary,amount:float,source_id:String,weapon:String = "") -> void:
	if not enemy.active or enemy.hp <= 0: return
	enemy.hp -= amount
	record("hit",{"entity_id":enemy.id,"source_id":source_id,"weapon":weapon,"amount":amount,"hp":maxf(0,enemy.hp)})
	enemy.node.impact_feedback(enemy.position - player.position, enemy.kind in ["heavy", "boss"],weapon)
	camera_impact(5.0 if enemy.kind == "boss" else (3.5 if weapon in ["grenade", "blade"] else 2.2))
	effect("impact_" + weapon if weapon in ["rail","grenade","blade","arc","thermal","frost"] else "impact",enemy.position,0.18 if weapon == "grenade" else 0.13)
	if enemy.kind in ["heavy","boss"] or weapon == "grenade": effect("impact_ring",enemy.position,0.20)
	audio("hit_" + weapon if weapon in ["rail","grenade","blade","arc","thermal","frost"] else ("hit_heavy" if enemy.kind in ["heavy","boss"] else "hit"))
	if enemy.hp <= 0:
		kills += 1
		add_credit(C.ECONOMY.kill,"kill",enemy.id)
		record("death",{"entity_id":enemy.id,"source_id":source_id,"weapon":weapon,"kind":enemy.kind})
		var value = C.ENEMIES[enemy.kind].xp
		if value > 0:
			var orb = acquire("xp",{"position":enemy.position,"value":value})
			if not orb.is_empty(): visual(orb,"xp")
		effect("death_boss" if enemy.kind == "boss" else "death",enemy.position,0.46 if enemy.kind == "boss" else 0.26)
		if enemy.kind in ["heavy","boss"]: effect("impact_ring",enemy.position,0.28)
		effect("explosion",enemy.position,0.35)
		if enemy.kind in ["heavy", "boss"]:
			camera_impact(10.0 if enemy.kind == "boss" else 6.0, true)
		release("enemies",enemy)
		audio("boss_death" if enemy.kind == "boss" else "death")

func _update_xp(delta:float) -> void:
	for orb in pools.xp:
		if not orb.active: continue
		if orb.position.distance_to(player.position) <= C.XP.range:
			orb.position = orb.position.move_toward(player.position,C.XP.speed*delta)
			orb.node.position = orb.position
			if orb.position.distance_to(player.position) < 25:
				xp += int(orb.value)
				record("xp",{"entity_id":orb.id,"amount":orb.value})
				release("xp",orb)
				audio("xp")
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		pending_upgrades += 1

func xp_needed() -> int:
	return C.XP.base+level*C.XP.per_level

func legal_cards() -> Array:
	var result:Array = []
	for key in C.WEAPONS:
		if not weapons.has(key):
			if weapons.size() < 3: result.append(card("weapon",key,1))
		elif weapons[key].level < 5:
			result.append(card("upgrade",key,weapons[key].level+1))
		elif not weapons[key].evolved and passives[C.WEAPONS[key].mod] >= 3:
			result.append(card("evolve",key,5))
	for key in C.MODS:
		if passives.get(key,0) < 3: result.append(card("mod",key,passives.get(key,0)+1))
	if result.is_empty():
		result = [card("supply","repair",0),card("supply","credits",0)]
	return result

func card(type:String,key:String,rank:int) -> Dictionary:
	var title:String = C.MODS.get(key,key)
	var description = "改裝強化至 %d 級" % rank
	if C.WEAPONS.has(key):
		title = C.WEAPONS[key].evolution if type == "evolve" else C.WEAPONS[key].name
		description = "取得自動武器" if type == "weapon" else ("啟動專屬進化" if type == "evolve" else "傷害與射速強化 · 等級 %d"%rank)
	elif type == "supply":
		title = "維修補給" if key == "repair" else "信用點補給"
		description = "恢復 25% 耐久" if key == "repair" else "本局信用點 +20"
	return {"id":type+":"+key,"type":type,"key":key,"title":title,"description":description,"level":rank}

func _open_upgrade() -> void:
	var available = legal_cards()
	for i in range(available.size()-1,0,-1):
		var j = rng.randi_range(0,i)
		var temporary = available[i]
		available[i] = available[j]
		available[j] = temporary
	cards = available.slice(0,mini(3,available.size()))
	state = "upgrade"
	audio("upgrade")
	record("upgrade_open",{"cards":cards.duplicate(true)})
	if ui != null: ui.show_upgrade(cards)

func choose_card(id:String) -> bool:
	if state != "upgrade": return false
	var selected:Dictionary = {}
	for candidate in cards:
		if candidate.id == id: selected = candidate
	if selected.is_empty(): return false
	var key:String = selected.key
	match selected.type:
		"weapon":
			if weapons.size() >= 3 or weapons.has(key): return false
			weapons[key] = {"level":1,"evolved":false,"remaining":0.0}
		"upgrade": weapons[key].level = mini(5,weapons[key].level+1)
		"mod": passives[key] = mini(3,passives[key]+1)
		"evolve":
			weapons[key].evolved = true
			effect("pulse",player.position,0.65,player.position,true)
			audio("evolve")
		"supply":
			if key == "repair": hp = minf(max_hp,hp+max_hp*0.25)
			else: add_credit(20,"supply")
	pending_upgrades = maxi(0,pending_upgrades-1)
	cards.clear()
	state = "playing"
	if ui != null: ui.clear_popups()
	audio("choose")
	record("card_chosen",{"id":id,"key":key})
	return true

func use_skill(slot:int) -> bool:
	if state != "playing" or slot < 0 or slot >= skills.size(): return false
	var skill:Dictionary = skills[slot]
	if skill.remaining > 0: return false
	var cfg = C.SKILLS[skill.key]
	skill.remaining = skill.cooldown
	skill.duration = cfg.duration
	match skill.key:
		"dash":
			dash_remaining = cfg.duration
			# A turn and Space can arrive before the next physics tick updates facing.
			var input_direction = Input.get_vector("move_left","move_right","move_up","move_down")
			dash_direction = input_direction.normalized() if input_direction.length_squared() > 0.001 else facing
		"pulse":
			for e in pools.enemies:
				if e.active and e.position.distance_to(player.position) <= cfg.range:
					if e.kind == "boss":
						e.slow = maxf(e.slow,cfg.boss_slow)
						e.slow_time = cfg.duration
					else: e.stun = cfg.duration
		"shield": shield = max_hp*cfg.ratio
		"repair": hp = minf(max_hp,hp+max_hp*cfg.ratio)
	effect(skill.key,player.position,maxf(0.35,cfg.duration))
	audio("skill_" + String(skill.key))
	record("skill",{"entity_id":"player","source_id":skill.key,"key":skill.key,"slot":slot,"direction":[dash_direction.x,dash_direction.y] if skill.key == "dash" else [],"position":[player.position.x,player.position.y]})
	return true

func toggle_pause() -> void:
	if not confirmation_previous.is_empty():
		state = confirmation_previous
		confirmation_previous = ""
		if ui != null:
			if state == "upgrade": ui.show_upgrade(cards)
			elif state == "paused": ui.show_pause()
			else: ui.clear_popups()
		return
	if state == "playing":
		state = "paused"
		if ui != null: ui.show_pause()
	elif state == "paused":
		state = "playing"
		if ui != null: ui.clear_popups()

func _accrue_milestones() -> void:
	while milestones < int(time/C.ECONOMY.milestone_seconds):
		milestones += 1
		add_credit(C.ECONOMY.milestone,"milestone")

func add_credit(amount:int,source:String,entity_id:String = "player") -> void:
	credits += amount
	record("credit",{"amount":amount,"source_id":source,"entity_id":entity_id,"credits":credits})

func finish_run(won:bool) -> void:
	if not test_scenario.is_empty() and test_scenario != "growth": _finish(won)

func _finish(won:bool) -> void:
	if state not in ["playing","upgrade","paused"]: return
	_accrue_milestones()
	state = "result"
	won_result = won and hp > 0
	if won_result: add_credit(C.ECONOMY.win,"win")
	result_summary = {"run_id":run_id,"won":won_result,"victory":won_result,"kills":kills,"time":time,"credits":credits,"level":level}
	var saved = progress.settle(run_id,result_summary)
	result_summary.merge({"saved":saved,"pending":not progress.pending.is_empty(),"save_error":progress.error,"wallet":progress.data.credits},true)
	record("settlement",result_summary)
	record("save",{"ok":saved,"error":progress.error})
	audio("win" if won_result else "lose")
	sound.stop_bgm()
	if ui != null: ui.show_result(result_summary)

func purchase_upgrade(key:String) -> bool:
	if state in ["playing","upgrade","paused"]: return false
	var ok = progress.purchase(key)
	record("purchase",{"key":key,"ok":ok,"wallet":progress.data.credits})
	if ui != null:
		if not progress.error.is_empty(): ui.show_notice(progress.error)
		else: ui.show_meta(progress.snapshot())
	return ok

func retry_save() -> bool:
	var ok = progress.retry()
	record("save",{"ok":ok,"error":progress.error,"retry":true})
	if ui != null:
		if state == "result":
			result_summary.merge({"saved":ok,"pending":not progress.pending.is_empty(),"save_error":progress.error,"wallet":progress.data.credits},true)
			ui.show_result(result_summary)
		elif not ok: ui.show_notice(progress.error)
	return ok

func return_to_loadout() -> bool:
	if not progress.pending.is_empty():
		if ui != null: ui.show_notice("本局收益尚未儲存，請先重試儲存。" + progress.error)
		return false
	if state in ["playing","upgrade","paused"]: return false
	clear_arena()
	state = "loadout"
	if ui != null: ui.show_loadout(progress.data.loadout)
	return true

func _request_menu() -> void:
	if not progress.pending.is_empty():
		if ui != null: ui.show_notice("收益待儲存，請先重試，避免遺失。" + progress.error)
		return
	if state in ["playing","upgrade","paused"]:
		var old = state
		confirmation_previous = state
		state = "paused"
		if ui != null:
			ui.show_confirm("離開將放棄本局尚未結算收益。確定返回配裝？",func():
				confirmation_previous = ""
				state = "menu"
				return_to_loadout())
			# UI cancellation uses pause_requested to restore active combat.
		else: state = old
	elif state == "result": return_to_loadout()
	else: show_menu()

func _request_quit() -> void:
	if not progress.pending.is_empty():
		if ui != null: ui.show_notice("收益儲存失敗，請保留視窗並重試。"+progress.error)
		return
	if state in ["playing","upgrade","paused"] and ui != null:
		confirmation_previous = state
		state = "paused"
		ui.show_confirm("關閉將放棄本局尚未結算收益。確定離開？",func(): get_tree().quit())
	else: get_tree().quit()

func acquire(pool:String,values:Dictionary) -> Dictionary:
	var entity:Dictionary = {}
	for candidate in pools[pool]:
		if not candidate.active:
			entity = candidate
			pool_stats[pool].reuses += 1
			break
	if entity.is_empty():
		if pools[pool].size() >= C.CAPS[pool]: return {}
		var node = Actor.new() if pool == "enemies" else Sprite2D.new()
		world.add_child(node)
		entity = {"node":node,"active":false}
		pools[pool].append(entity)
		pool_stats[pool].allocated += 1
	var node = entity.node
	entity.clear()
	entity.merge(values,true)
	entity_serial += 1
	entity.merge({"node":node,"id":"%s-%d"%[pool,entity_serial],"active":true},true)
	node.visible = true
	node.modulate = Color.WHITE
	node.position = values.get("position",Vector2.ZERO)
	pool_stats[pool].peak = maxi(pool_stats[pool].peak,active_count(pool))
	record("pool",{"entity_id":entity.id,"pool":pool,"action":"acquire","node_id":node.get_instance_id()})
	return entity

func release(pool:String,entity:Dictionary) -> void:
	if not entity.active: return
	entity.active = false
	entity.node.visible = false
	if pool == "enemies": entity.node.disable_collision()
	record("pool",{"entity_id":entity.id,"pool":pool,"action":"release","node_id":entity.node.get_instance_id()})

func clear_arena() -> void:
	combat.thermal_field.clear()
	for key in pools:
		for entity in pools[key]:
			if entity.active: release(key,entity)

func active_count(pool:String) -> int:
	var count = 0
	for e in pools[pool]:
		if e.active: count += 1
	return count

func allocated_counts() -> Dictionary:
	var result:Dictionary = {}
	for key in pool_stats: result[key] = pool_stats[key].allocated
	return result

func shield_duration() -> float:
	for skill in skills:
		if skill.key == "shield": return skill.duration
	return 0.0

func visual(entity:Dictionary,key:String) -> void:
	var node:Sprite2D = entity.node
	node.texture = texture("res://assets/sprites/vfx/runtime/scifi/%s.png"%key)
	node.rotation = 0
	node.scale = Vector2.ONE*2
	node.z_index = 0
	if node.texture != null and maxf(node.texture.get_width(),node.texture.get_height()) > 100:
		node.scale = Vector2.ONE*0.6
	if key == "xp": node.scale = Vector2.ONE*1.5
	if entity.get("evolved",false): node.modulate = Color(1.0,0.77,0.30)

func effect(key:String,position:Vector2,duration:float,end:Vector2 = Vector2.INF,evolved:bool = false) -> void:
	var e = acquire("vfx",{"key":key,"position":position,"life":duration,"duration":duration,"evolved":evolved,"follow":key in ["shield","dash","repair"]})
	if e.is_empty(): return
	visual(e,key)
	if end != Vector2.INF and position.distance_to(end)>1:
		e.node.position = (position+end)/2
		e.node.rotation = position.angle_to_point(end)
		if e.node.texture != null:
			e.node.scale = Vector2(position.distance_to(end)/e.node.texture.get_width(),3 if evolved else 2)
	elif key == "pulse": e.node.scale = Vector2.ONE*4
	if key == "impact" or key.begins_with("impact_") or key in ["explosion","death","death_boss"]:
		e["base_scale"] = e.node.scale
		e.node.z_index = 5

func _update_effects(delta:float) -> void:
	for e in pools.vfx:
		if not e.active: continue
		e.life -= delta
		e.node.modulate.a = clampf(e.life/e.duration,0,1)
		if e.key == "impact" or e.key.begins_with("impact_") or e.key in ["explosion","death","death_boss"]:
			var progress_ratio := 1.0 - clampf(e.life / maxf(0.001, e.duration), 0.0, 1.0)
			e.node.scale = e.base_scale * (0.48 + (1.18 if e.key == "impact_ring" else 0.85) * progress_ratio)
		if e.follow: e.node.position = player.position
		if e.life <= 0: release("vfx",e)

func audio(key:String) -> void:
	var mapped = C.SFX.get(key,"hit")
	sound.play_event(mapped)
	record("audio",{"key":key,"source_id":mapped,"entity_id":"audio","loaded":sound.loaded_events().has(mapped)})

func record(event:String,data:Dictionary = {}) -> void:
	event_serial += 1
	var entry = {"serial":event_serial,"event":event,"time":time,"tick":tick,"entity_id":data.get("entity_id","system"),"source_id":data.get("source_id","system"),"data":data.duplicate(true)}
	entry.merge(data,true)
	events.append(entry)
	if events.size()>10000: events.pop_front()

func snapshot(include_events:bool = true) -> Dictionary:
	var weapon_data = weapons.duplicate(true)
	for key in weapon_data: weapon_data[key].merge(combat.stats(key),true)
	var enemy_data:Array = []
	var boss:Dictionary = {}
	for e in pools.enemies:
		if not e.active: continue
		var value = {"id":e.id,"entity_id":e.id,"kind":e.kind,"position":[e.position.x,e.position.y],"hp":e.hp,"max_hp":e.max_hp,"speed":e.speed*(1-e.slow),"base_speed":e.speed,"stun":e.stun,"stun_remaining":e.stun,"slow":e.slow,"slow_factor":e.slow,"slow_time":e.slow_time,"shoot_timer":e.shoot_timer,"state":e.attack_state,"windup":e.windup,"animation":str(e.node.sprite.animation),"facing":e.node.facing}
		enemy_data.append(value)
		if e.kind == "boss": boss = value
	var enemy_bullets:Array = []
	for p in pools.enemy_projectiles:
		if p.active: enemy_bullets.append({"id":p.id,"position":[p.position.x,p.position.y],"velocity":[p.velocity.x,p.velocity.y],"damage":p.damage,"life":p.life,"age":p.get("age",0),"remaining_hits":p.get("remaining_hits",0),"sign":p.get("sign",0)})
	var projectile_data:Array = []
	for p in pools.projectiles:
		if p.active: projectile_data.append({"id":p.id,"kind":p.kind,"weapon":p.weapon,"position":[p.position.x,p.position.y],"damage":p.damage,"life":p.life,"age":p.get("age",0),"remaining_hits":p.get("remaining_hits",0),"sign":p.get("sign",0)})
	var counts:Dictionary = {}
	for key in pools: counts[key] = active_count(key)
	return {"version":C.VERSION,"config_version":C.VERSION,"seed":seed_value,"run_id":run_id,"state":state,"time":time,"stage":stage,"hp":hp,"max_hp":max_hp,"position":[player.position.x,player.position.y],"velocity":[velocity.x,velocity.y],"speed":C.PLAYER.speed,"facing":player.facing,"animation":str(player.sprite.animation),"movement_bounds":[C.BOUNDS.position.x,C.BOUNDS.position.y,C.BOUNDS.end.x,C.BOUNDS.end.y],"weapons":weapon_data,"passives":passives.duplicate(true),"mods":passives.duplicate(true),"cards":cards.duplicate(true),"legal_cards":legal_cards() if not weapons.is_empty() else [],"pending_upgrades":pending_upgrades,"queued_upgrades":pending_upgrades,"skills":skills.duplicate(true),"shield":shield,"invulnerable":invulnerable,"dash_remaining":dash_remaining,"enemies":enemy_data,"enemy_projectiles":enemy_bullets,"projectiles":projectile_data,"boss":boss.merged({"spawn_count":boss_count}),"boss_count":boss_count,"pool_counts":counts,"counts":counts,"pool_stats":pool_stats.duplicate(true),"pool_allocated":allocated_counts(),"caps":C.CAPS,"kills":kills,"xp":xp,"xp_needed":xp_needed(),"xp_required":xp_needed(),"level":level,"credits":credits,"run_credits":credits,"milestones":milestones,"wallet":progress.data.credits,"meta":progress.data.upgrades.duplicate(true),"progress":progress.snapshot(),"pending":progress.pending.duplicate(true),"pending_settlement":progress.pending.duplicate(true),"save_status":("saved" if progress.error.is_empty() and progress.pending.is_empty() else ("pending" if not progress.pending.is_empty() else "error")),"settled_ids":progress.data.settled_ids.duplicate(),"save_error":progress.error,"events":events.duplicate(true) if include_events else [],"loaded_resources":loaded_resources.duplicate(),"bgm":sound.bgm_status(),"audio":sound.triggered_events(),"node_count":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"won":won_result,"result":result_summary.duplicate(true),"player":{"hp":hp,"max_hp":max_hp,"position":[player.position.x,player.position.y],"speed":C.PLAYER.speed,"shield":shield,"shield_remaining":shield_duration(),"invulnerable_remaining":maxf(invulnerable,dash_remaining),"velocity":[velocity.x,velocity.y],"facing":player.facing}}

func test_fixture(op:String,data:Dictionary = {}) -> Variant:
	if test_scenario.is_empty() or test_scenario == "growth": return false
	record("fixture",{"op":op,"arguments":data})
	match op:
		"reset_arena":
			clear_arena()
			spawning = data.get("spawning",false)
			if test_scenario == "replay" and spawning:
				# Replay starts from one canonical frame, RNG, wave and weapon timer baseline.
				rng.seed = seed_value
				tick = 0
				time = 0.0
				spawn_timer = 0.0
				for key in weapons: weapons[key].remaining = 0.0
		"set_player":
			if data.has("position"): player.position = _vector(data.position)
			if data.has("hp"): hp = data.hp
			if data.has("max_hp"): max_hp = data.max_hp
			if data.has("invulnerable"): invulnerable = data.invulnerable
			if data.has("shield"): shield = data.shield
		"add_enemy":
			var extra = data.duplicate(true)
			extra.erase("position")
			extra.erase("kind")
			var e = spawn_enemy(data.get("kind","crawler"),_vector(data.get("position",[2048,1000])),extra)
			return e.get("id","")
		"add_enemy_projectile":
			var p = enemy_shot(_vector(data.get("position",[2048,1000])),_vector(data.get("velocity",[0,0])),data.get("damage",8),data.get("life",3),"fixture")
			return p.get("id","")
		"seed_build":
			if data.has("weapons"):
				weapons.clear()
				for key in data.weapons:
					weapons[key] = {"level":1,"evolved":false,"remaining":0.0}.merged(data.weapons[key],true)
			if data.has("passives"):
				for key in data.passives: passives[key] = data.passives[key]
			if data.has("meta"):
				progress.data.upgrades.merge(data.meta,true)
			if data.has("credits"): progress.data.credits = data.credits
		"open_upgrade":
			pending_upgrades = data.get("pending",1)
			_open_upgrade()
			if data.has("cards"):
				cards = legal_cards().filter(func(c): return data.cards.has(c.id))
				if ui != null: ui.show_upgrade(cards)
		"set_time": time = data.get("time",0.0)
		"force_damage":
			if data.get("target","player") == "player": damage_player(data.get("damage",0),data.get("source_id","fixture"),data.get("bypass_invulnerability",true))
			else:
				for e in pools.enemies:
					if e.active and e.id == data.target: hit_enemy(e,data.get("damage",0),data.get("source_id","fixture"))
		"save_fault": progress.fault = data.get("point","")
		_: return false
	return true

func _vector(value:Variant) -> Vector2:
	return value if value is Vector2 else Vector2(value[0],value[1])
