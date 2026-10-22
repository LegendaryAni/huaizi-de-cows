extends Node
## Independent acceptance harness. Fixtures never execute in the growth scenario.
## The frozen policy is docs/20261017_LegendarySurvivor_ScifiTestCases_v0.2.md T16.

const WEAPONS := ["rail", "grenade", "blade", "arc", "thermal", "frost"]
const MODS := ["firecontrol", "blast", "propulsion", "capacitor", "heat", "cooling"]
const SKILLS := ["dash", "pulse", "shield", "repair"]
const META := ["hp", "damage", "weapon_cd", "skill_cd"]
const DIRECTIONS := [Vector2.RIGHT, Vector2(0.70710678,0.70710678), Vector2.DOWN, Vector2(-0.70710678,0.70710678), Vector2.LEFT, Vector2(-0.70710678,-0.70710678), Vector2.UP, Vector2(0.70710678,-0.70710678)]
const BASE_DAMAGE := {"rail":28.0, "grenade":42.0, "blade":22.0, "arc":20.0, "thermal":12.0, "frost":18.0}
const BASE_CD := {"rail":0.55, "grenade":1.65, "blade":1.1, "arc":1.0, "thermal":0.25, "frost":0.7}

var game: Node
var scenario := ""
var assertions: Array[Dictionary] = []
var samples: Array[Dictionary] = []
var notes: Array[String] = []
var started_ticks := 0
var fixture_calls := 0
var output_path := ""
var movement_actions: Array[String] = ["move_right", "move_down", "move_left", "move_up"]
var source_hashes: Dictionary={}
var growth_event_file: FileAccess
var growth_operation_file: FileAccess
var last_event_serial:=0
var growth_snapshot_file: FileAccess
var growth_observing := false
var growth_run := 0
var growth_next_sample := 0
var growth_next_flush := 0
var growth_next_media := 0
var growth_clip_until := 0
var growth_media_seen: Dictionary = {}
var growth_media_pending: Array[String] = []
var growth_frame_index := 0
var growth_media_busy := false
var growth_stream_failed := false
var growth_run_started := 0
var growth_last_clock_time := 0.0
var growth_last_clock_wall := 0
var growth_exit_reason := "not_started"
var growth_boss_death := false
var growth_state_wall: Dictionary = {}
var growth_clock_state := ""
var growth_state_since := 0
var growth_run_ids: Array[String] = []

func run(target: Node, requested: String, report_path: String) -> void:
	game = target
	scenario = requested
	output_path = report_path
	started_ticks = Time.get_ticks_msec()
	for path in ["ScifiMain.gd","ScifiConfig.gd","ScifiCombat.gd","ScifiActor.gd","ScifiProgress.gd","tests/ScifiTests.gd"]:
		source_hashes[path]=FileAccess.get_sha256("res://scripts/scifi/"+path)
	for path in ["res://scripts/scifi/ScifiUI.gd","res://project.godot","res://scenes/Main.tscn","res://tools/run_scifi_tests.ps1","res://docs/20261017_LegendarySurvivor_ScifiTestCases_v0.2.md"]:
		source_hashes[path]=FileAccess.get_sha256(path)
	var isolated := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scifi-save=") and arg.trim_prefix("--scifi-save=").length() > 0:
			isolated = true
	check(isolated, "harness.isolated_save", "All test invocations require explicit --scifi-save; never use player saves.")
	if not isolated:
		finish()
		return
	for method in ["snapshot", "start_run", "choose_card", "use_skill", "purchase_upgrade", "retry_save", "finish_run", "test_fixture"]:
		check(game.has_method(method), "api." + method, "Required real entrypoint exists")
	if not all_passed():
		finish()
		return
	await get_tree().process_frame
	match scenario:
		"smoke": await test_smoke()
		"loadout": await test_loadout()
		"movement": await test_movement()
		"weapons": await test_weapons()
		"evolutions": await test_evolutions()
		"cards": await test_cards()
		"skills": await test_skills()
		"stages-boss": await test_stages()
		"economy": await test_economy()
		"save-faults": await test_save_faults()
		"pool-stress": await test_pool_stress()
		"growth": await test_growth()
		"visual-capture", "flow-compat": await test_ui_flow()
		"menu-preview": await test_main_menu_only()
		"menu-v3": await test_cinematic_menu_v3()
		"menu-v3-motion": await test_menu_v3_motion()
		"menu-v3-perf": await test_menu_v3_performance()
		"ui-bounds": await test_ui_bounds()
		"feedback-audio": await test_audio()
		"assets-directions": await test_directions()
		"replay": await test_replay()
		"collisions": await test_collisions()
		"all":
			await test_smoke()
			await test_loadout()
			await test_movement()
			await test_weapons()
			await test_evolutions()
			await test_cards()
			await test_skills()
			await test_stages()
			await test_economy()
			await test_save_faults()
		_:
			check(false, "harness.known_scenario", requested)
	finish()

func check(condition: bool, id: String, detail: Variant = null) -> void:
	assertions.append({"id":id, "passed":condition, "detail":detail, "wall_ms":Time.get_ticks_msec() - started_ticks})
	if not condition:
		push_error("SCIFI_TEST_FAIL " + id + " " + str(detail))

func all_passed() -> bool:
	for item in assertions:
		if not item.passed:
			return false
	return true

func snap() -> Dictionary:
	return game.call("snapshot",false) if scenario == "growth" else game.call("snapshot")

func fixture(op: String, data: Dictionary = {}) -> Variant:
	if scenario == "growth":
		check(false, "growth.no_fixture", op)
		return null
	fixture_calls += 1
	return game.call("test_fixture", op, data)

func sample(label: String) -> Dictionary:
	var value := snap().duplicate(true)
	if scenario=="growth":
		flush_growth_events()
		write_growth_snapshot(label,value)
		return value
	samples.append({"label":label, "wall_ms":Time.get_ticks_msec()-started_ticks, "snapshot":value})
	return value

func seconds(duration: float) -> void:
	var deadline := Time.get_ticks_msec() + int(duration * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await get_tree().physics_frame

func start(weapon := "rail", skills: Array = ["dash", "repair"]) -> bool:
	var current:=str(snap().get("state",""))
	if scenario!="growth" and current in ["playing","upgrade","paused"]:
		game.call("finish_run",false)
	if str(snap().get("state",""))=="result":
		game.call("return_to_loadout")
	var result: Variant = game.call("start_run", {"weapon":weapon, "skills":skills})
	await get_tree().physics_frame
	return bool(result)

func clean(weapon := "rail", skills: Array = ["dash", "repair"]) -> void:
	await start(weapon, skills)
	fixture("reset_arena", {"spawning":false})
	fixture("set_player", {"position":[2048, 1152], "hp":120, "max_hp":120, "invulnerable":0.0, "shield":0.0})
	await get_tree().physics_frame

func vector(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	if value is Dictionary:
		return Vector2(float(value.get("x", 0)), float(value.get("y", 0)))
	return Vector2.ZERO

func player(data: Dictionary) -> Dictionary:
	return data.get("player", {})

func near(a: float, b: float, tolerance := 0.05) -> bool:
	return absf(a-b) <= tolerance

func entity(data: Dictionary, id: Variant) -> Dictionary:
	for item in data.get("enemies", []):
		if str(item.get("id")) == str(id):
			return item
	return {}

func event_list(data: Dictionary, event: String, weapon := "") -> Array:
	var result: Array = []
	for item in data.get("events", []):
		if str(item.get("event", "")) == event:
			if weapon.is_empty() or str(item.get("data", {}).get("weapon", "")) == weapon:
				result.append(item)
	return result

func test_smoke() -> void:
	var initial := sample("formal-entry")
	for key in ["version", "seed", "run_id", "state", "time", "stage", "player", "weapons", "mods", "cards", "queued_upgrades", "skills", "enemies", "enemy_projectiles", "movement_bounds", "boss", "counts", "pool_allocated", "kills", "xp", "run_credits", "progress", "pending_settlement", "save_status", "save_error", "events", "loaded_resources"]:
		check(initial.has(key), "snapshot." + key)
	check(await start(), "smoke.start_valid_loadout")
	var before := snap()
	await seconds(1.0)
	var after := sample("smoke-battle")
	check(float(after.get("time", 0)) > float(before.get("time", 0)) + 0.8, "smoke.real_clock_advances")
	check(after.get("weapons", {}).has("rail"), "smoke.start_weapon_present")
	check(after.get("skills", []).size() == 2, "smoke.two_skills")
	check(float(player(after).get("hp", 0)) > 0, "smoke.player_alive")
	growth_skill_input(KEY_E,1,after)
	await get_tree().physics_frame
	check(float(snap().get("skills",[])[1].get("remaining",0))>0,"smoke.growth_e_key_reaches_production_skill_handler")
	growth_skill_input(KEY_SPACE,0,snap())
	await get_tree().physics_frame
	check(float(snap().get("skills",[])[0].get("remaining",0))>0,"smoke.growth_space_key_reaches_production_skill_handler")
	await capture("smoke-battle")

func test_loadout() -> void:
	for weapon in WEAPONS:
		for i in range(SKILLS.size()):
			for j in range(i+1, SKILLS.size()):
				check(await start(weapon, [SKILLS[i], SKILLS[j]]), "loadout.valid.%s.%s.%s" % [weapon, SKILLS[i], SKILLS[j]])
				var state := snap()
				check(state.get("weapons", {}).has(weapon), "loadout.weapon." + weapon)
				var equipped: Array = state.get("skills", [])
				check(equipped.size() == 2 and equipped[0].get("key") == SKILLS[i] and equipped[1].get("key") == SKILLS[j], "loadout.skill_slots")
	for loadout in [{"weapon":"unknown", "skills":["dash","repair"]}, {"weapon":"rail", "skills":["dash","dash"]}, {"weapon":"rail", "skills":["dash"]}, {"weapon":"rail", "skills":["dash","repair","pulse"]}, {"weapon":"rail", "skills":["unknown","repair"]}, {}]:
		var before: Dictionary = snap().get("progress", {}).duplicate(true)
		check(not bool(game.call("start_run", loadout)), "loadout.reject." + str(loadout))
		check(snap().get("progress", {}) == before, "loadout.invalid_preserves_progress")
	sample("loadout-matrix-finished")

func set_movement(direction: Vector2) -> void:
	for i in range(movement_actions.size()):
		var action := movement_actions[i]
		if InputMap.has_action(action):
			Input.action_release(action)
	var axes := [direction.x, direction.y, -direction.x, -direction.y]
	for i in range(axes.size()):
		if axes[i] > 0.01 and InputMap.has_action(movement_actions[i]):
			Input.action_press(movement_actions[i], float(axes[i]))

func test_movement() -> void:
	await clean()
	var distances: Array[float] = []
	var speeds: Array[float] = []
	for direction in [Vector2.RIGHT, Vector2(1,1).normalized()]:
		fixture("set_player", {"position":[2048,1152]})
		var begin := vector(player(snap()).get("position"))
		var simulation_start:=float(snap().get("time",0))
		set_movement(direction)
		await seconds(0.5)
		set_movement(Vector2.ZERO)
		distances.append(begin.distance_to(vector(player(snap()).get("position"))))
		var simulation_delta:=float(snap().get("time",0))-simulation_start
		speeds.append(distances[-1]/maxf(0.001,simulation_delta))
	check(distances[0] > 120, "movement.normal_input_moves", distances)
	check(absf(speeds[0]-speeds[1]) < 2 and near(speeds[0],340,2), "movement.diagonal_normalized", {"distances":distances,"simulation_speeds":speeds})
	for position in [[31,31],[4065,31],[31,2274],[4065,2274]]:
		fixture("set_player", {"position":position})
		set_movement((vector(position)-Vector2(2048,1152)).normalized())
		game.call("use_skill", 0)
		await seconds(0.35)
		set_movement(Vector2.ZERO)
		var at := vector(player(snap()).get("position"))
		check(at.x >= 0 and at.x <= 4096 and at.y >= 0 and at.y <= 2305, "movement.dash_boundary", [at.x,at.y])
	await test_dash_immediate_input_direction()

func test_dash_immediate_input_direction() -> void:
	# T16 presses Space in the same decision as a newly selected legal direction.
	# Do not yield a physics frame between changing Input and pressing Space.
	var cases := [
		{"id":"southeast_to_northwest","old":Vector2(1,1).normalized(),"next":Vector2(-1,-1).normalized()},
		{"id":"east_to_south","old":Vector2.RIGHT,"next":Vector2.DOWN}
	]
	for case in cases:
		await clean()
		set_movement(case.old)
		await seconds(0.06)
		var before := snap()
		var origin := vector(player(before).get("position"))
		var desired: Vector2=case.next
		var old_facing: Vector2=game.get("facing")
		check(old_facing.dot(case.old)>0.999,"movement.dash_old_facing_established."+case.id,{"facing":str(old_facing),"velocity":player(before).get("velocity")})
		set_movement(desired)
		growth_skill_input(KEY_SPACE,0,before)
		var launched: Vector2=game.get("dash_direction")
		check(launched.dot(desired)>0.999,"movement.dash_uses_immediate_input."+case.id,{"desired":[desired.x,desired.y],"previous_facing":before.get("facing"),"launched":[launched.x,launched.y],"input":str(Input.get_vector("move_left","move_right","move_up","move_down"))})
		await seconds(0.24)
		var after := snap()
		var displacement := vector(player(after).get("position"))-origin
		check(displacement.dot(desired)>=239.99 and absf(displacement.cross(desired))<=0.01,"movement.dash_real_displacement_matches_immediate_input."+case.id,{"desired":[desired.x,desired.y],"displacement":[displacement.x,displacement.y],"distance":displacement.length(),"before":before,"after":after})
		set_movement(Vector2.ZERO)
		sample("dash-immediate-input-"+case.id)

func test_weapons() -> void:
	for key in WEAPONS:
		for level in range(1,6):
			for meta_level in [0,5]:
				await clean(key)
				fixture("seed_build", {"weapons":{key:{"level":level,"evolved":false}},"passives":{},"meta":{"hp":0,"damage":meta_level,"weapon_cd":meta_level,"skill_cd":0}})
				var target: Variant = fixture("add_enemy", {"kind":"heavy", "position":[2210,1152], "hp":100000, "speed":0, "contact_damage":0})
				var before := snap()
				var damage: float = float(BASE_DAMAGE[key]) * pow(1.35,level-1) * (1.0+0.1*meta_level)
				var cooldown: float = float(BASE_CD[key]) * pow(0.9,level-1) * (1.0-0.05*meta_level)
				await seconds(maxf(0.9,cooldown*2.5+0.5))
				var after := snap()
				var observed: Dictionary = after.get("weapons", {}).get(key,{})
				var tag := "%s.L%d.meta%d" % [key,level,meta_level]
				check(near(float(observed.get("damage",-1)),damage),"weapons.damage."+tag,{"expected":damage,"actual":observed})
				check(near(float(observed.get("cooldown",-1)),cooldown),"weapons.cd_config."+tag)
				check(float(entity(after,target).get("hp",100000)) < float(entity(before,target).get("hp",100000)),"weapons.real_hit."+tag)
				var attacks := event_list(after,"attack",key)
				check(attacks.size() >= 2,"weapons.real_emission."+tag,attacks.size())
				if attacks.size() >= 2:
					var gap := float(attacks[-1].get("time",0))-float(attacks[-2].get("time",0))
					check(absf(gap-cooldown)<0.05,"weapons.real_interval."+tag,{"expected":cooldown,"actual":gap})
				var hits := event_list(after,"hit",key)
				check(not hits.is_empty(),"weapons.hit_attribution."+tag)
				if not hits.is_empty():
					check(near(float(hits[-1].get("data",{}).get("amount",-1)),damage),"weapons.real_hit_amount."+tag)
	await clean("arc")
	var victim: Variant = fixture("add_enemy", {"kind":"crawler","position":[2160,1152],"hp":1,"speed":0,"contact_damage":0})
	var before_kills := int(snap().get("kills",0))
	fixture("force_damage", {"target":victim,"damage":100,"source_id":"test:first"})
	fixture("force_damage", {"target":victim,"damage":100,"source_id":"test:second"})
	check(int(snap().get("kills",0)) == before_kills+1,"weapons.death_single_credit")
	sample("weapon-matrix-finished")

func test_evolutions() -> void:
	for i in range(WEAPONS.size()):
		var key: String = WEAPONS[i]
		var mod_key: String = MODS[i]
		for pair in [[4,3],[5,2],[5,3]]:
			await clean(key)
			fixture("seed_build", {"weapons":{key:{"level":pair[0],"evolved":false}},"passives":{mod_key:pair[1]}})
			fixture("open_upgrade")
			var data := snap()
			var candidate := find_card(data.get("legal_cards",[]),"evolve",key)
			if pair == [5,3]:
				check(not candidate.is_empty(),"evolution.eligible."+key)
				check(not bool(data.get("weapons",{}).get(key,{}).get("evolved",true)),"evolution.not_early."+key)
				if not candidate.is_empty():
					fixture("open_upgrade",{"cards":[candidate.id]})
					game.call("choose_card",candidate.id)
					var evolved := snap()
					check(bool(evolved.get("weapons",{}).get(key,{}).get("evolved",false)),"evolution.selected."+key)
					check(evolved.get("weapons",{}).size() == 1,"evolution.same_slot."+key)
					fixture("open_upgrade")
					check(find_card(snap().get("cards",[]),"evolve",key).is_empty(),"evolution.once."+key)
			else:
				check(candidate.is_empty(),"evolution.ineligible.%s.%s" % [key,str(pair)])
	await test_evolution_behaviors()
	await test_grenade_outer_children()
	notes.append("Mechanical evolution differentials have real HP assertions; matching rendered effects still require independent visual review.")

func test_grenade_outer_children() -> void:
	# Each target is beyond the main blast and lies on one of six child rays.
	# Dense-target ties select the center, which is inserted first. No direct damage fixture.
	for evolved in [false,true]:
		await clean("grenade")
		fixture("seed_build",{"weapons":{"grenade":{"level":5,"evolved":evolved}},"passives":{"blast":0}})
		var center := Vector2(2280,1152)
		var central = fixture("add_enemy",{"kind":"crawler","position":[center.x,center.y],"hp":100000,"speed":0,"contact_damage":0})
		var outer: Array = []
		for index in range(6):
			var at := center+Vector2.from_angle(TAU*index/6.0)*240.0
			outer.append(fixture("add_enemy",{"kind":"crawler","position":[at.x,at.y],"hp":100000,"speed":0,"contact_damage":0}))
		var first_serial := int(game.get("event_serial"))
		await seconds(0.95)
		var data := snap()
		var blasts: Array = []
		for event in event_list(data,"explosion"):
			if int(event.get("serial",0))>first_serial: blasts.append(event)
		check(blasts.size()==1,"evolution.grenade.single_main_blast."+str(evolved),blasts.size())
		check(float(entity(data,central).get("hp",100000))<100000,"evolution.grenade.main_real_hit."+str(evolved))
		var child_sources: Array = []
		for index in range(outer.size()):
			var id = outer[index]
			var hits: Array = []
			for event in event_list(data,"hit","grenade"):
				if int(event.get("serial",0))>first_serial and str(event.get("entity_id"))==str(id): hits.append(event)
			var damage := 100000.0-float(entity(data,id).get("hp",100000))
			if evolved:
				var expected := 42.0*pow(1.35,4)*1.4*0.35
				check(hits.size()==1 and near(damage,expected,0.01),"evolution.grenade.outer_child_real_damage.%d"%index,{"damage":damage,"expected":expected,"hits":hits})
				if hits.size()==1:
					var source := str(hits[0].get("source_id",""))
					check(not child_sources.has(source) and (blasts.is_empty() or source!=str(blasts[0].get("entity_id"))),"evolution.grenade.distinct_child_source.%d"%index,source)
					child_sources.append(source)
			else:
				check(hits.is_empty() and damage==0,"evolution.grenade.normal_outer_unhit.%d"%index,damage)
		check(not evolved or child_sources.size()==6,"evolution.grenade.all_six_children_real_hits",child_sources)
		sample("grenade-outer-six-children-"+str(evolved))

func test_evolution_behaviors() -> void:
	for key in ["rail","grenade","arc","thermal","frost"]:
		var outcomes: Array = []
		for evolved in [false,true]:
			await clean(key)
			fixture("seed_build",{"weapons":{key:{"level":5,"evolved":evolved}},"passives":{}})
			var targets: Array = []
			var positions: Array = []
			match key:
				"rail": positions=[[2180,1152],[2300,1152],[2420,1152],[2540,1152]]
				"grenade": positions=[[2280,1152],[2480,1152]]
				"arc": positions=[[2180,1152],[2330,1152],[2480,1152],[2630,1152],[2780,1152],[2930,1152],[3080,1152]]
				"thermal": positions=[[2180,1152],[2230,1152],[2280,1152],[2310,1152],[2460,1152]]
				"frost": positions=[[2200,1152],[2260,1190]]
			for position in positions:
				targets.append(fixture("add_enemy",{"kind":"crawler","position":position,"hp":100000,"speed":0,"contact_damage":0}))
			await seconds(0.9 if key!="grenade" else 1.4)
			var data:=snap()
			var hit_count:=0
			for id in targets:
				if float(entity(data,id).get("hp",100000))<100000:
					hit_count+=1
			outcomes.append({"hit_count":hit_count,"targets":targets,"snapshot":data})
			if key=="frost":
				check(near(float(entity(data,targets[0]).get("slow",-1)),0.55 if evolved else 0.25),"evolution.frost_real_slow."+str(evolved))
		check(int(outcomes[1].hit_count)>int(outcomes[0].hit_count),"evolution.real_target_difference."+key,{"normal":outcomes[0].hit_count,"evolved":outcomes[1].hit_count})
	await clean("blade")
	fixture("seed_build",{"weapons":{"blade":{"level":5,"evolved":true}},"passives":{}})
	fixture("add_enemy",{"kind":"heavy","position":[2300,1152],"hp":100000,"speed":0})
	await seconds(0.1)
	var signs: Array=[]
	for projectile in snap().get("projectiles",[]):
		if projectile.get("weapon")=="blade":
			signs.append(projectile.get("sign",0))
	check(signs.has(1) and signs.has(-1),"evolution.blade_opposite_arcs",signs)

func card_kind(card: Dictionary) -> String:
	var kind := str(card.get("kind",""))
	if kind.is_empty():
		kind = str(card.get("id","")).get_slice(":",0)
	return kind

func card_key(card: Dictionary) -> String:
	var key := str(card.get("key",""))
	if key.is_empty():
		key = str(card.get("id","")).get_slice(":",1)
	return key

func find_card(cards: Array, kind: String, key: String) -> Dictionary:
	for value in cards:
		if card_kind(value) == kind and card_key(value) == key:
			return value
	return {}

func test_cards() -> void:
	await clean()
	fixture("seed_build",{"weapons":{"rail":{"level":1,"evolved":false},"arc":{"level":1,"evolved":false},"grenade":{"level":1,"evolved":false}},"passives":{}})
	for card in snap().get("legal_cards",[]):
		check(card_kind(card)!="weapon","cards.full_slots_exclude_new",card)
	game.call("use_skill",0)
	game.call("use_skill",1)
	var build := {"rail":{"level":5,"evolved":true},"arc":{"level":5,"evolved":true},"grenade":{"level":5,"evolved":true}}
	var passives := {}
	for key in MODS:
		passives[key] = 3
	fixture("seed_build", {"weapons":build,"passives":passives})
	fixture("open_upgrade")
	var data := snap()
	var cards: Array = data.get("cards",[])
	check(not cards.is_empty(),"cards.maxed_has_supply")
	for card in cards:
		check(card_kind(card) == "supply", "cards.maxed_only_supply",card)
	var before := data.duplicate(true)
	await seconds(0.5)
	data = snap()
	check(near(float(data.get("time",-1)),float(before.get("time",-2)),0.001),"cards.time_frozen")
	check(player(data).get("position") == player(before).get("position"),"cards.position_frozen")
	check(data.get("skills",[]) == before.get("skills",[]),"cards.skills_frozen")
	check(not bool(game.call("choose_card","no-such-card")),"cards.reject_unknown")
	if not cards.is_empty():
		check(bool(game.call("choose_card",cards[0].id)),"cards.choose_visible")
		check(not bool(game.call("choose_card",cards[0].id)),"cards.reject_stale")
	fixture("open_upgrade", {"cards":["supply:repair"]})
	check(snap().get("cards",[]).size() == 1,"cards.one_candidate")
	sample("cards-finished")

func test_skills() -> void:
	for i in range(SKILLS.size()):
		for j in range(i+1,SKILLS.size()):
			for order in [[SKILLS[i],SKILLS[j]],[SKILLS[j],SKILLS[i]]]:
				await clean("rail",order)
				fixture("set_player", {"hp":50})
				check(bool(game.call("use_skill",0)),"skills.slot0."+str(order))
				var after_first := snap()
				check(float(after_first.get("skills",[])[1].get("remaining",-1)) == 0,"skills.independent_cd."+str(order))
				check(not bool(game.call("use_skill",0)),"skills.cooldown_reject."+str(order))
				check(bool(game.call("use_skill",1)),"skills.slot1."+str(order))
				check(float(player(snap()).get("hp",0)) <= float(player(snap()).get("max_hp",0)),"skills.no_overheal")
	await clean("rail",["pulse","shield"])
	var turret: Variant = fixture("add_enemy", {"kind":"turret","position":[2300,1152],"hp":100000,"speed":80,"shoot_timer":0.05,"contact_damage":0})
	var boss: Variant = fixture("add_enemy", {"kind":"boss","position":[2320,1200],"hp":100000,"speed":75,"contact_damage":0})
	game.call("use_skill",0)
	var before := snap()
	var turret_at := vector(entity(before,turret).get("position"))
	var boss_at := vector(entity(before,boss).get("position"))
	check(float(entity(before,turret).get("stun_remaining",0)) > 1.4,"skills.pulse_turret_stun")
	check(float(entity(before,boss).get("stun_remaining",0)) == 0,"skills.boss_not_stunned")
	await seconds(0.7)
	var after := snap()
	check(vector(entity(after,turret).get("position")).distance_to(turret_at)<0.1,"skills.turret_stops")
	check(after.get("enemy_projectiles",[]).is_empty(),"skills.turret_no_shoot_while_stunned")
	check(vector(entity(after,boss).get("position")).distance_to(boss_at)>1,"skills.boss_moves_during_pulse")
	game.call("use_skill",1)
	var shield := float(player(snap()).get("shield",0))
	check(near(shield,42),"skills.shield_35percent",shield)
	fixture("force_damage",{"target":"player","damage":10,"bypass_invulnerability":true})
	check(near(float(player(snap()).get("hp",0)),120),"skills.shield_absorbs")
	check(near(float(player(snap()).get("shield",0)),32),"skills.shield_depletes")
	for pause_key in [KEY_P,KEY_ESCAPE]:
		await press_key(pause_key)
		var paused:=snap()
		check(str(paused.get("state",""))=="paused","skills.keyboard_pause."+str(pause_key))
		await seconds(0.5)
		var frozen:=snap()
		check(near(float(paused.get("time",-1)),float(frozen.get("time",-2)),0.001),"skills.pause_time_frozen")
		check(paused.get("skills",[])==frozen.get("skills",[]),"skills.pause_cd_frozen")
		check(near(float(player(paused).get("shield_remaining",-1)),float(player(frozen).get("shield_remaining",-2)),0.001),"skills.pause_shield_duration_frozen")
		check(not bool(game.call("use_skill",0)),"skills.no_cast_paused")
		await press_key(pause_key)
		check(str(snap().get("state",""))=="playing","skills.keyboard_resume."+str(pause_key))
	await clean("rail",["repair","dash"])
	fixture("set_player",{"hp":110})
	game.call("use_skill",0)
	check(near(float(player(snap()).get("hp",0)),120),"skills.repair_clamped")
	sample("skills-finished")

func press_key(key: int) -> void:
	var down:=InputEventKey.new()
	down.keycode=key
	down.physical_keycode=key
	down.pressed=true
	Input.parse_input_event(down)
	await seconds(0.05)
	var up:=InputEventKey.new()
	up.keycode=key
	up.physical_keycode=key
	up.pressed=false
	Input.parse_input_event(up)
	await get_tree().process_frame

func test_stages() -> void:
	await clean()
	for boundary in [120,240,360,480]:
		fixture("set_time",{"time":float(boundary)-0.05})
		await seconds(0.12)
		check(int(snap().get("stage",-1)) == boundary/120,"stages.boundary."+str(boundary))
	check(int(snap().get("boss",{}).get("spawn_count",0)) == 1,"stages.boss_once_at480")
	fixture("set_time",{"time":601.0})
	await seconds(0.1)
	check(str(snap().get("state","")) == "playing","stages.no_600s_auto_win")
	check(int(snap().get("boss",{}).get("spawn_count",0)) == 1,"stages.no_duplicate_boss")
	fixture("force_damage",{"target":"player","damage":100000,"bypass_invulnerability":true})
	await get_tree().physics_frame
	check(str(snap().get("state","")) == "result","stages.hp0_result")
	check(not bool(snap().get("result",{}).get("won",true)),"stages.hp0_loss")
	for player_first in [true,false]:
		await clean()
		fixture("set_time",{"time":480.0})
		await get_tree().physics_frame
		await get_tree().physics_frame
		var boss_id: Variant=snap().get("boss",{}).get("id","")
		var prior_settlements:=event_list(snap(),"settlement").size()
		for target in (["player",boss_id] if player_first else [boss_id,"player"]):
			fixture("force_damage",{"target":target,"damage":100000,"bypass_invulnerability":true})
		await get_tree().physics_frame
		await get_tree().physics_frame
		var data:=snap()
		check(not bool(data.get("result",{}).get("won",true)),"stages.same_tick_loss_priority."+str(player_first))
		check(event_list(data,"settlement").size()==prior_settlements+1,"stages.same_tick_single_settlement."+str(player_first))
		check(int(data.get("run_credits",-1))==121,"stages.same_tick_no_win_bonus."+str(player_first),data.get("run_credits"))

func test_economy() -> void:
	await clean()
	game.call("finish_run",false)
	game.call("return_to_loadout")
	fixture("seed_build",{"weapons":{"rail":{"level":1,"evolved":false}},"passives":{},"meta":{"hp":0,"damage":0,"weapon_cd":0,"skill_cd":0},"credits":0})
	var before: Dictionary = snap().get("progress",{}).duplicate(true)
	check(not bool(game.call("purchase_upgrade","hp")),"economy.insufficient_rejected")
	check(snap().get("progress",{}) == before,"economy.insufficient_unchanged")
	var prices := [60,100,160,240,340]
	for key in META:
		for level in range(5):
			fixture("seed_build",{"credits":2000})
			var prior := int(snap().get("progress",{}).get("credits",0))
			check(bool(game.call("purchase_upgrade",key)),"economy.buy.%s.%d" % [key,level+1])
			var progress: Dictionary = snap().get("progress",{})
			check(int(progress.get("upgrades",{}).get(key,-1)) == level+1,"economy.level.%s.%d" % [key,level+1])
			check(prior-int(progress.get("credits",0)) == prices[level],"economy.price.%s.%d" % [key,level+1])
		var full: Dictionary = snap().get("progress",{}).duplicate(true)
		check(not bool(game.call("purchase_upgrade",key)),"economy.cap_rejected."+key)
		check(snap().get("progress",{}) == full,"economy.cap_unchanged."+key)
	await clean()
	fixture("set_time",{"time":120.1})
	await get_tree().physics_frame
	await get_tree().physics_frame
	for index in range(3):
		var id: Variant = fixture("add_enemy",{"kind":"crawler","position":[2600+index*50,1152],"hp":1,"speed":0})
		fixture("force_damage",{"target":id,"damage":100})
	var credits_before := int(snap().get("progress",{}).get("credits",0))
	game.call("finish_run",false)
	var final := snap()
	check(int(final.get("run_credits",-1)) == 33,"economy.kill_and_milestone_formula",final.get("run_credits"))
	check(int(final.get("progress",{}).get("credits",0)) == credits_before+33,"economy.loss_full_credit")
	game.call("finish_run",false)
	check(int(snap().get("progress",{}).get("credits",0)) == credits_before+33,"economy.settlement_once")

func test_save_faults() -> void:
	for point in ["journal_write","temp_write","before_replace","replace","after_commit"]:
		await clean()
		fixture("set_time",{"time":60.1})
		fixture("save_fault",{"point":point})
		var prior := int(snap().get("progress",{}).get("credits",0))
		game.call("finish_run",false)
		var failed := snap()
		check(not str(failed.get("save_error","")).is_empty(),"save.visible_error."+point)
		check(not failed.get("pending_settlement",{}).is_empty(),"save.pending_preserved."+point)
		fixture("save_fault",{"point":""})
		check(bool(game.call("retry_save")),"save.retry."+point)
		var after := snap()
		check(int(after.get("progress",{}).get("credits",0)) == prior+15,"save.credit_once."+point)
		game.call("retry_save")
		check(int(snap().get("progress",{}).get("credits",0)) == prior+15,"save.repeated_retry_idempotent."+point)
	await test_progress_disk()
	notes.append("On-disk recovery is tested using fresh Progress instances; actual OS process interruption and physical disk failure are not simulated by object reconstruction.")

func isolated_root() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scifi-save="):
			return arg.trim_prefix("--scifi-save=")
	return ""

func write_text(path: String, contents: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file:=FileAccess.open(path,FileAccess.WRITE)
	check(file!=null,"disk.fixture_write",path)
	if file:
		file.store_string(contents)
		file.close()

func read_text(path: String) -> String:
	var file:=FileAccess.open(path,FileAccess.READ)
	return file.get_as_text() if file else ""

func test_progress_disk() -> void:
	var progress_script: Script=load("res://scripts/scifi/ScifiProgress.gd")
	check(progress_script!=null,"disk.progress_module_available")
	if progress_script==null:
		return
	var folder:=isolated_root().path_join("disk-component-cases")
	var backup_folder:=folder.path_join("backup")
	var progress: RefCounted=progress_script.new(backup_folder)
	var first: Dictionary=progress.call("defaults")
	first.credits=60
	check(bool(progress.call("commit",first)),"disk.first_commit")
	var original:=read_text(backup_folder.path_join("scifi_progress.json"))
	var second:=first.duplicate(true)
	second.credits=160
	check(bool(progress.call("commit",second)),"disk.second_commit")
	check(read_text(backup_folder.path_join("scifi_progress.json.bak"))==original,"disk.backup_is_previous_exact")
	var reloaded: RefCounted=progress_script.new(backup_folder)
	check(int(reloaded.get("data").get("credits",-1))==160,"disk.restart_reads_committed")
	for point in ["temp_write","before_replace","replace","after_commit"]:
		var case_folder:=folder.path_join("recover-"+point)
		var writer: RefCounted=progress_script.new(case_folder)
		check(bool(writer.call("commit",writer.call("defaults"))),"disk.prepare."+point)
		writer.set("fault",point)
		check(not bool(writer.call("settle","unique-"+point,{"credits":37,"won":false})),"disk.injected_failure."+point)
		check(not read_text(case_folder.path_join("scifi_pending.json")).is_empty(),"disk.journal_written."+point)
		var recovered: RefCounted=progress_script.new(case_folder)
		check(not recovered.get("pending").is_empty(),"disk.restart_pending."+point)
		check(bool(recovered.call("retry")),"disk.restart_retry."+point)
		check(int(recovered.get("data").get("credits",-1))==37,"disk.restart_reward_once."+point)
		var next_reload: RefCounted=progress_script.new(case_folder)
		next_reload.call("settle","unique-"+point,{"credits":37,"won":false})
		check(int(next_reload.get("data").get("credits",-1))==37,"disk.replayed_id_no_duplicate."+point)
	for kind in ["corrupt","future","wrong_type"]:
		var case_folder:=folder.path_join(kind)
		var value: String="{broken-json"
		if kind=="future":
			var future: Dictionary=progress.call("defaults")
			future.version=999
			value=JSON.stringify(future)
		elif kind=="wrong_type":
			value=JSON.stringify({"version":1,"credits":"not-number","upgrades":[]})
		var path:=case_folder.path_join("scifi_progress.json")
		write_text(path,value)
		var invalid: RefCounted=progress_script.new(case_folder)
		check(bool(invalid.get("protected")),"disk.protect_invalid."+kind)
		check(not str(invalid.get("error")).is_empty(),"disk.invalid_visible."+kind)
		invalid.call("commit",invalid.call("defaults"))
		check(read_text(path)==value,"disk.no_overwrite_invalid."+kind)
	var protected_folder:=folder.path_join("valid-backup")
	write_text(protected_folder.path_join("scifi_progress.json"),"{broken")
	write_text(protected_folder.path_join("scifi_progress.json.bak"),original)
	var restored: RefCounted=progress_script.new(protected_folder)
	check(int(restored.get("data").get("credits",-1))==60,"disk.valid_backup_loaded")
	check(read_text(protected_folder.path_join("scifi_progress.json"))=="{broken","disk.backup_does_not_overwrite_corrupt")
	for invalid_case in ["loadout_array","loadout_null","negative_credits","fractional_credits","future_journal","wrong_reward"]:
		var case_folder:=folder.path_join(invalid_case)
		var valid_data: Dictionary=progress.call("defaults")
		var test_path:=case_folder.path_join("scifi_progress.json")
		if invalid_case=="loadout_array": valid_data.loadout=[]
		elif invalid_case=="loadout_null": valid_data.loadout=null
		elif invalid_case=="negative_credits": valid_data.credits=-1
		elif invalid_case=="fractional_credits": valid_data.credits=0.5
		var contents:=JSON.stringify(valid_data)
		write_text(test_path,contents)
		if invalid_case in ["future_journal","wrong_reward"]:
			test_path=case_folder.path_join("scifi_pending.json")
			contents=JSON.stringify({"version":999 if invalid_case=="future_journal" else 1,"run_id":"pending-test","reward":{"credits":12} if invalid_case=="future_journal" else []})
			write_text(test_path,contents)
		var rejected: RefCounted=progress_script.new(case_folder)
		check(bool(rejected.get("protected")),"disk.protect_shape."+invalid_case)
		rejected.call("commit",rejected.call("defaults"))
		check(read_text(test_path)==contents,"disk.preserve_invalid_shape."+invalid_case)

func test_pool_stress() -> void:
	await clean("arc")
	for index in range(220):
		fixture("add_enemy",{"kind":"heavy","position":[2500+(index%10)*10,1100+(index/10)*10],"hp":100000,"speed":0})
	for index in range(130):
		fixture("add_enemy_projectile",{"position":[3500,2000],"velocity":[0,0],"damage":1,"life":0.1})
	var first := sample("stress-saturated")
	check(int(first.get("counts",{}).get("enemies",100000)) <= 180,"pools.enemy_cap")
	check(int(first.get("counts",{}).get("enemy_projectiles",100000)) <= 100,"pools.enemy_projectile_cap")
	for index in range(180):
		await seconds(1)
		var data := sample("stress-second-"+str(index+1))
		for pair in [["enemies",180],["projectiles",160],["enemy_projectiles",100],["xp",400],["vfx",80]]:
			check(int(data.get("counts",{}).get(pair[0],100000)) <= pair[1],"pools.cap.%s.%d" % [pair[0],index])
	notes.append("Node identities/allocation trend, memory and rendered mixed-Boss stress must accompany this cap run; cap assertions alone do not establish reuse or stability.")

func rank_card(card: Dictionary) -> int:
	var kind := card_kind(card)
	var key := card_key(card)
	var order := ["evolve:rail","upgrade:rail","mod:firecontrol","weapon:arc","evolve:arc","upgrade:arc","mod:capacitor","weapon:grenade","evolve:grenade","upgrade:grenade","mod:blast","mod:heat","mod:cooling","mod:propulsion","weapon:thermal","weapon:frost","weapon:blade"]
	var rank := order.find(kind+":"+key)
	if rank >= 0:
		return rank
	if kind == "upgrade" or kind == "evolve":
		return 20
	if kind == "supply" and key == "repair":
		return 30
	return 31

func growth_direction(data: Dictionary) -> Vector2:
	var position := vector(player(data).get("position"))
	var speed := float(player(data).get("speed",340))
	var bounds: Array = data.get("movement_bounds",[])
	if bounds.size() != 4:
		check(false,"growth.movement_bounds_contract",bounds)
		return Vector2.ZERO
	var center := Vector2((float(bounds[0])+float(bounds[2]))*0.5,(float(bounds[1])+float(bounds[3]))*0.5)
	var obstacles: Array = data.get("enemies",[]).duplicate()
	obstacles.append_array(data.get("enemy_projectiles",[]))
	if obstacles.is_empty():
		return (center-position).normalized()
	var best := Vector2.ZERO
	var best_safety := -INF
	var best_center := INF
	for direction in DIRECTIONS:
		var predicted: Vector2 = position+direction*speed*0.5
		if predicted.x<float(bounds[0]) or predicted.y<float(bounds[1]) or predicted.x>float(bounds[2]) or predicted.y>float(bounds[3]):
			continue
		var safety := INF
		for obstacle in obstacles:
			safety = minf(safety,predicted.distance_to(vector(obstacle.get("position"))))
		var centering := predicted.distance_squared_to(center)
		if safety>best_safety+0.0001 or (near(safety,best_safety,0.0001) and centering<best_center-0.0001):
			best=direction
			best_safety=safety
			best_center=centering
	return best

func test_growth() -> void:
	growth_event_file=FileAccess.open(output_path+".events.jsonl",FileAccess.WRITE)
	growth_operation_file=FileAccess.open(output_path+".inputs.jsonl",FileAccess.WRITE)
	growth_snapshot_file=FileAccess.open(output_path+".snapshots.jsonl",FileAccess.WRITE)
	check(growth_event_file!=null and growth_operation_file!=null and growth_snapshot_file!=null,"growth.durable_streams_available")
	check(near(Engine.time_scale,1.0,0.001),"growth.time_scale_one")
	check(Engine.physics_ticks_per_second==60,"growth.standard_physics_tick",Engine.physics_ticks_per_second)
	var initial := snap()
	check(int(initial.get("progress",{}).get("credits",-1)) == 0,"growth.fresh_credits")
	for key in META:
		check(int(initial.get("progress",{}).get("upgrades",{}).get(key,-1)) == 0,"growth.fresh_meta."+key)
	if not all_passed():
		growth_exit_reason="preflight_failed"
		return
	growth_observing=true
	growth_exit_reason="running"
	growth_operation("preflight",{"source_hashes":source_hashes,"engine":Engine.get_version_info(),"time_scale":Engine.time_scale,"physics_ticks_per_second":Engine.physics_ticks_per_second,"display":DisplayServer.get_name(),"policy":"T16 frozen 20261017; full-information automatic operator; no fixtures"})
	archive_growth_save("initial",initial)
	ui_node().call("show_loadout",{"weapon":"rail","skills":["dash","repair"]})
	mark_growth_media("loadout")
	await seconds(0.25)
	var pointer := 0
	var won_at := 0
	for run_index in range(1,6):
		growth_run=run_index
		growth_boss_death=false
		archive_growth_save("run-%d-before"%run_index,snap())
		growth_run_started=Time.get_ticks_msec()
		growth_state_wall.clear()
		growth_clock_state=str(game.get("state"))
		growth_state_since=growth_run_started
		growth_last_clock_wall=growth_run_started
		growth_last_clock_time=0.0
		var started := await start("rail",["dash","repair"])
		growth_operation("start",{"ok":started,"loadout":{"weapon":"rail","skills":["dash","repair"]}})
		check(started,"growth.legal_start."+str(run_index))
		if not started:
			growth_exit_reason="start_rejected"
			return
		var started_id := str(game.get("run_id"))
		check(not started_id.is_empty() and not growth_run_ids.has(started_id),"growth.unique_run_id",started_id)
		growth_run_ids.append(started_id)
		sample("growth-run-%d-start" % run_index)
		var ticks := 0
		while true:
			var data := snap()
			var state := str(data.get("state",""))
			if growth_stream_failed:
				growth_exit_reason="evidence_stream_failed"
				set_movement(Vector2.ZERO)
				return
			if state == "result":
				break
			if state == "upgrade":
				set_movement(Vector2.ZERO)
				growth_operation("movement",{"tick":ticks,"direction":[0,0],"reason":"upgrade"})
				var cards: Array = data.get("cards",[]).duplicate(true)
				cards.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
					var rank_a := rank_card(a)
					var rank_b := rank_card(b)
					if rank_a==20 and rank_b==20 and card_key(a)!=card_key(b): return card_key(a)<card_key(b)
					return rank_a<rank_b or (rank_a==rank_b and str(a.get("id",""))<str(b.get("id",""))))
				mark_growth_media("upgrade")
				sample("growth-run-%d-card-before"%run_index)
				await seconds(0.5)
				if cards.is_empty():
					check(false,"growth.visible_card_required")
					growth_exit_reason="missing_visible_cards"
					return
				var accepted := bool(game.call("choose_card",cards[0].id))
				growth_operation("card",{"tick":ticks,"visible_candidates":data.get("cards",[]),"sorted_candidates":cards,"selected":cards[0],"accepted":accepted,"delay_seconds":0.5})
				check(accepted,"growth.legal_card",cards[0])
				sample("growth-run-%d-card-after"%run_index)
				if card_kind(cards[0])=="evolve": mark_growth_media("evolution")
			elif state == "playing":
				var direction := growth_direction(data)
				set_movement(direction)
				growth_operation("movement",{"tick":ticks,"game_time":data.get("time"),"direction":[direction.x,direction.y],"player":player(data),"skills":data.get("skills",[])})
				var hp := float(player(data).get("hp",0))
				var maximum := float(player(data).get("max_hp",0))
				var skills: Array = data.get("skills",[])
				if skills.size()!=2:
					check(false,"growth.skill_snapshot_contract")
					growth_exit_reason="invalid_skill_snapshot"
					return
				if hp<=maximum*0.75 and float(skills[1].get("remaining",-1))==0:
					growth_skill_input(KEY_E,1,data)
				var nearest := INF
				var obstacles: Array = data.get("enemies",[]).duplicate()
				obstacles.append_array(data.get("enemy_projectiles",[]))
				for obstacle in obstacles:
					nearest=minf(nearest,vector(player(data).get("position")).distance_to(vector(obstacle.get("position"))))
				if nearest<=100 and float(skills[0].get("remaining",-1))==0:
					growth_skill_input(KEY_SPACE,0,data)
			else:
				check(false,"growth.unexpected_state",state)
				growth_exit_reason="unexpected_state:"+state
				return
			if ticks%100==0: write_live(data,run_index)
			ticks+=1
			if float(data.get("time",0))>1800:
				check(false,"growth.watchdog_no_synthetic_finish",data.get("time"))
				set_movement(Vector2.ZERO)
				growth_exit_reason="watchdog"
				return
			await seconds(0.1)
		set_movement(Vector2.ZERO)
		growth_operation("movement",{"direction":[0,0],"reason":"result"})
		var result := sample("growth-run-%d-result" % run_index)
		account_growth_state()
		growth_operation("settlement",{"result":result.get("result",{}),"save_status":result.get("save_status"),"pending":result.get("pending_settlement",{}),"run_credits":result.get("run_credits"),"progress":result.get("progress",{}),"wall_run_ms":Time.get_ticks_msec()-growth_run_started,"battle_seconds":result.get("time"),"nonbattle_seconds":(Time.get_ticks_msec()-growth_run_started)/1000.0-float(result.get("time",0)),"upgrade_ui_ms":growth_state_wall.get("upgrade",0),"state_wall_ms":growth_state_wall.duplicate(),"transaction_ui_ms":0})
		check(str(result.get("save_status","")) == "saved" and result.get("pending_settlement",{}).is_empty(),"growth.settlement_saved")
		check(growth_boss_death if bool(result.get("result",{}).get("won",false)) else float(player(result).get("hp",1))<=0,"growth.natural_settlement_cause",{"won":result.get("won"),"boss_death_observed":growth_boss_death,"hp":player(result).get("hp")})
		archive_growth_save("run-%d-result"%run_index,result)
		mark_growth_media("result")
		await seconds(0.25)
		if bool(result.get("result",{}).get("won",false)):
			won_at=run_index
			ui_node().call("show_meta",snap().get("progress",{}))
			mark_growth_media("meta")
			await seconds(0.25)
			break
		var purchases:=0
		var transaction_started := Time.get_ticks_msec()
		while purchases<20:
			var progress: Dictionary=snap().get("progress",{})
			var key: String=META[pointer%4]
			var level:=int(progress.get("upgrades",{}).get(key,0))
			if level>=5:
				pointer+=1
				purchases+=1
				continue
			var price: int=[60,100,160,240,340][level]
			if int(progress.get("credits",0))<price:
				growth_operation("purchase_stop",{"key":key,"price":price,"wallet":progress.get("credits"),"pointer":pointer})
				break
			var accepted := bool(game.call("purchase_upgrade",key))
			growth_operation("purchase",{"key":key,"price":price,"before":progress,"after":snap().get("progress",{}),"accepted":accepted,"pointer":pointer})
			check(accepted,"growth.legal_purchase",{"key":key,"level":level+1,"price":price})
			archive_growth_save("run-%d-purchase-%d"%[run_index,purchases],snap())
			pointer+=1
			purchases+=1
		sample("growth-run-%d-post-purchases" % run_index)
		growth_operation("run_timing",{"battle_seconds":result.get("time"),"upgrade_ui_ms":growth_state_wall.get("upgrade",0),"transaction_ui_ms":Time.get_ticks_msec()-transaction_started,"transaction_includes":"purchase policy loop, official transactions and save readback/archive"})
		archive_growth_save("run-%d-after"%run_index,snap())
		# Show the real permanent-upgrade screen between runs, without changing purchases.
		ui_node().call("show_meta",snap().get("progress",{}))
		mark_growth_media("meta")
		await seconds(0.25)
	check(fixture_calls==0,"growth.no_fixture_calls",fixture_calls)
	check(won_at>=1 and won_at<=5,"growth.win_within_five",won_at)
	for path in source_hashes:
		var resource: String=path if str(path).begins_with("res://") else "res://scripts/scifi/"+str(path)
		check(FileAccess.get_sha256(resource)==source_hashes[path],"growth.source_unchanged."+path)
	growth_exit_reason="first_win" if won_at>0 else "five_runs_without_win"
	growth_operation("exit",{"reason":growth_exit_reason,"first_win_run":won_at,"fixture_calls":fixture_calls})
	archive_growth_save("final",snap())
	notes.append("first_win_run="+str(won_at))
	notes.append("Global acceptance additionally requires all seeds 17/41/73 and first-win median 3..5; a single seed result is insufficient. Internal enemy positions were read by this automated policy; human difficulty/fun remains unverified.")
	# Finish any already-triggered natural result/meta frame capture before shutdown.
	await get_tree().process_frame

func growth_skill_input(key: int, slot: int, before: Dictionary) -> void:
	# Same-frame key down/up uses the production input handler; never calls use_skill.
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode=key
		event.physical_keycode=key
		event.pressed=pressed
		get_viewport().push_input(event,true)
		growth_operation("skill_input",{"keycode":key,"slot":slot,"pressed":pressed,"before":before.get("skills",[]),"hp":player(before).get("hp")})

func growth_operation(kind: String, detail: Dictionary) -> void:
	if not growth_operation_file: return
	growth_operation_file.store_line(JSON.stringify({"operation":kind,"run":growth_run,"run_id":game.get("run_id"),"wall_ms":Time.get_ticks_msec()-started_ticks,"utc":Time.get_datetime_string_from_system(true),"detail":detail}))

func flush_growth_events() -> void:
	if not growth_event_file: return
	var serial := int(game.get("event_serial"))
	if serial==last_event_serial: return
	var entries: Array = game.get("events")
	var first := maxi(0,entries.size()-(serial-last_event_serial))
	for index in range(first,entries.size()):
		var event: Dictionary=entries[index]
		var current := int(event.get("serial",0))
		if current<=last_event_serial: continue
		if current!=last_event_serial+1:
			check(false,"growth.event_serial_gap",{"expected":last_event_serial+1,"actual":current})
			growth_stream_failed=true
		growth_event_file.store_line(JSON.stringify({"run":growth_run,"run_id":game.get("run_id"),"wall_ms":Time.get_ticks_msec()-started_ticks,"event":event}))
		last_event_serial=current
		if event.get("event")=="fixture":
			check(false,"growth.no_fixture_event",event)
			growth_stream_failed=true
		if event.get("event")=="skill": mark_growth_media("skill")
		if event.get("event")=="spawn" and event.get("kind")=="boss": mark_growth_media("boss")
		if event.get("event")=="death" and event.get("kind")=="boss": growth_boss_death=true

func write_growth_snapshot(label: String, data: Dictionary) -> void:
	if not growth_snapshot_file: return
	growth_snapshot_file.store_line(JSON.stringify({"label":label,"run":growth_run,"wall_ms":Time.get_ticks_msec()-started_ticks,"utc":Time.get_datetime_string_from_system(true),"last_event_serial":last_event_serial,"time_scale":Engine.time_scale,"physics_ticks_per_second":Engine.physics_ticks_per_second,"source_hashes":source_hashes,"snapshot":data}))

func archive_growth_save(label: String, data: Dictionary) -> void:
	var directory := output_path.get_basename()+"-saves/"+label
	check(DirAccess.make_dir_recursive_absolute(directory)==OK,"growth.save_archive_directory."+label)
	var root := str(data.get("progress",{}).get("path","")).get_base_dir()
	var requires_committed := label.contains("-result") or label.contains("-purchase-") or label.ends_with("-after") or label=="final"
	var main_path := root.path_join("scifi_progress.json")
	if requires_committed:
		check(FileAccess.file_exists(main_path),"growth.committed_save_exists."+label,main_path)
		var disk: Variant=JSON.parse_string(read_text(main_path)) if FileAccess.file_exists(main_path) else null
		check(disk is Dictionary,"growth.committed_save_parse."+label)
		if disk is Dictionary:
			for key in ["credits","upgrades","settled_ids"]:
				check(disk.get(key)==data.get("progress",{}).get(key),"growth.committed_save_readback."+label+"."+key,{"disk":disk.get(key),"snapshot":data.get("progress",{}).get(key)})
	var files: Array=[]
	for name in ["scifi_progress.json","scifi_progress.json.bak","scifi_pending.json","huazi_scores.json"]:
		var source := root.path_join(name)
		var exists := FileAccess.file_exists(source)
		var info := {"source":source,"exists":exists}
		if exists:
			var target := directory.path_join(name)
			var copied := DirAccess.copy_absolute(source,target)==OK
			check(copied,"growth.save_archive_copy."+label+"."+name)
			info.merge({"copy":target,"sha256":FileAccess.get_sha256(source),"copy_sha256":FileAccess.get_sha256(target)},true)
			check(info.sha256==info.copy_sha256,"growth.save_archive_hash."+label+"."+name)
		files.append(info)
	growth_operation("save_archive",{"label":label,"files":files,"progress":data.get("progress",{})})

func mark_growth_media(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	var identity := "run-%d-%s"%[growth_run,label]
	if growth_media_seen.has(identity): return
	growth_media_seen[identity]=true
	growth_media_pending.append(identity)
	growth_clip_until=maxi(growth_clip_until,Time.get_ticks_msec()+3000)

func _process(_delta: float) -> void:
	if not growth_observing: return
	account_growth_state()
	flush_growth_events()
	var now := Time.get_ticks_msec()
	if now>=growth_next_sample:
		growth_next_sample=now+1000
		var data := snap()
		write_growth_snapshot("periodic",data)
		if data.get("state")=="playing": mark_growth_media("battle")
		var time_value := float(data.get("time",0))
		var clock := {"run":growth_run,"wall_ms":now,"game_time":time_value,"time_scale":Engine.time_scale,"physics_ticks_per_second":Engine.physics_ticks_per_second}
		if growth_last_clock_wall>0 and time_value>=growth_last_clock_time:
			var advance := time_value-growth_last_clock_time
			var real_elapsed := (now-growth_last_clock_wall)/1000.0
			if not near(Engine.time_scale,1.0,0.001) or Engine.physics_ticks_per_second!=60 or advance>real_elapsed+0.15:
				check(false,"growth.normal_clock_audit",clock.merged({"simulation_advance":advance,"real_elapsed":real_elapsed}))
				growth_stream_failed=true
		if data.get("state")=="playing":
			var expected_max := 120.0*(1.0+0.12*int(data.get("progress",{}).get("upgrades",{}).get("hp",0)))
			if not bool(game.get("spawning")) or not near(float(player(data).get("max_hp",0)),expected_max) or not str(game.get("progress").get("fault")).is_empty():
				check(false,"growth.no_cheat_state_audit",{"spawning":game.get("spawning"),"expected_max_hp":expected_max,"player":player(data),"save_fault":game.get("progress").get("fault")})
				growth_stream_failed=true
		growth_last_clock_wall=now
		growth_last_clock_time=time_value
		growth_operation("clock_audit",clock)
	if now>=growth_next_flush:
		growth_next_flush=now+1000
		for stream in [growth_event_file,growth_operation_file,growth_snapshot_file]:
			if stream:
				stream.flush()
				if stream.get_error()!=OK and not growth_stream_failed:
					check(false,"growth.evidence_write_failed",stream.get_error())
					growth_stream_failed=true
	if not growth_media_busy and (not growth_media_pending.is_empty() or (now<growth_clip_until and now>=growth_next_media)):
		capture_growth_frame()

func account_growth_state() -> void:
	var now := Time.get_ticks_msec()
	if growth_state_since>0:
		growth_state_wall[growth_clock_state]=int(growth_state_wall.get(growth_clock_state,0))+now-growth_state_since
	growth_clock_state=str(game.get("state"))
	growth_state_since=now

func capture_growth_frame() -> void:
	growth_media_busy=true
	growth_next_media=Time.get_ticks_msec()+200
	await RenderingServer.frame_post_draw
	var frame := get_viewport().get_texture().get_image()
	var directory := output_path.get_basename()+"-natural-frames"
	DirAccess.make_dir_recursive_absolute(directory)
	var labels := growth_media_pending.duplicate()
	growth_media_pending.clear()
	var path := directory.path_join("frame-%06d.png"%growth_frame_index)
	var saved := frame.save_png(path)==OK
	if not saved: check(false,"growth.natural_frame_write",path)
	growth_operation("natural_frame",{"index":growth_frame_index,"path":path,"labels":labels,"state":game.get("state"),"game_time":game.get("time"),"fixture":false,"fps_target":5})
	growth_frame_index+=1
	growth_media_busy=false

func write_live(data: Dictionary,run_index: int) -> void:
	var live:={"run":run_index,"seed":data.get("seed"),"time":data.get("time"),"hp":player(data).get("hp"),"level":data.get("level"),"kills":data.get("kills"),"boss_hp":data.get("boss",{}).get("hp",0),"wallet":data.get("progress",{}).get("credits"),"meta":data.get("progress",{}).get("upgrades"),"source_hashes":source_hashes,"wall_ms":Time.get_ticks_msec()-started_ticks,"state":data.get("state"),"last_event_serial":last_event_serial,"snapshots_file":output_path+".snapshots.jsonl","events_file":output_path+".events.jsonl","operations_file":output_path+".inputs.jsonl"}
	var file:=FileAccess.open(output_path+".live.json",FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(live,"\t"))
		file.close()

func ui_node() -> Node:
	return game.get("ui")

func click(action: String, value: Variant = null) -> bool:
	await get_tree().process_frame
	var button: Button=null
	for candidate in get_tree().get_nodes_in_group("scifi_buttons"):
		if candidate is Button and candidate.is_visible_in_tree() and not candidate.disabled and candidate.get_meta("scifi_action","")==action:
			if value==null or candidate.get_meta("scifi_value",null)==value:
				button=candidate
				break
	check(button!=null,"ui.enabled_button."+action,value)
	if button==null:
		return false
	var at:=button.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new()
	motion.position=at
	get_viewport().push_input(motion,true)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new()
		event.position=at
		event.global_position=at
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=pressed
		get_viewport().push_input(event,true)
		await get_tree().process_frame
	await seconds(0.1)
	return true

func _inspect_ui_bounds(label: String) -> void:
	await get_tree().process_frame
	var active: Node = ui_node()
	if active == null:
		check(false,"ui_bound."+label+".ui_missing")
		return
	var viewport_box := Rect2(Vector2.ZERO,Vector2(1920,1080))
	var frames: Array[Node] = [active.get("root")]
	var visited := 0
	var outside: Array[String] = []
	while not frames.is_empty():
		var n: Node = frames.pop_back()
		for child in n.get_children(): frames.append(child)
		if not n is Control or not n.is_visible_in_tree(): continue
		var ctrl: Control = n
		if ctrl is Label or ctrl is Button or ctrl is TextureRect or ctrl is NinePatchRect or ctrl is ColorRect:
			var bounds := ctrl.get_global_rect()
			if bounds.size.x > 0 and bounds.size.y > 0:
				visited += 1
				if bounds.position.x < -1 or bounds.position.y < -1 or bounds.end.x > 1921 or bounds.end.y > 1081:
					outside.append("%s at %s"%[str(n.name),str(bounds)])
	check(outside.is_empty(),"ui_bound."+label+".all_visible_controls_inside_viewport",{"inspected":visited,"escaped":outside.slice(0,12)})
	check(visited >= 6,"ui_bound."+label+".actual_controls_present",visited)

func test_ui_bounds() -> void:
	check(DisplayServer.get_name() != "headless","ui_bounds.gpu_required")
	if DisplayServer.get_name() == "headless": return
	var layer: Node = ui_node()
	check(layer != null,"ui_bounds.ui_loaded")
	if layer == null: return
	var store: Dictionary = layer.get("cached_progress")
	if store.is_empty():
		store = {"credits":0,"loadout":{"weapon":"rail","skills":["dash","repair"]},"upgrades":{}}
	layer.call("show_menu",store,[])
	await _inspect_ui_bounds("main_menu")
	await capture("bounds-menu")
	layer.call("show_loadout",{"weapon":"rail","skills":["dash","repair"]})
	await _inspect_ui_bounds("loadout")
	await capture("bounds-loadout")
	layer.call("show_meta",store)
	await _inspect_ui_bounds("meta")
	await capture("bounds-meta")
	layer.call("show_scores")
	await _inspect_ui_bounds("scores")
	layer.call("show_credits")
	await _inspect_ui_bounds("credits")
	layer.call("show_settings","menu")
	await _inspect_ui_bounds("settings")
	await capture("bounds-settings")
	for idx in range(3):
		layer.call("show_tutorial",idx)
		await _inspect_ui_bounds("tutorial_%d"%idx)
	layer.call("show_pause")
	await _inspect_ui_bounds("pause")
	layer.call("show_upgrade",[{"id":"weapon:rail","type":"weapon","key":"rail","title":"磁軌步槍","level":1,"description":"選擇新的起始武器"},{"id":"mod:blast","type":"mod","key":"blast","title":"爆破強化","level":1,"description":"強化爆炸效果"},{"id":"supply:repair","type":"supply","key":"repair","title":"維修補給","level":0,"description":"回復耐久"}])
	await _inspect_ui_bounds("upgrade")
	await capture("bounds-upgrade")
	layer.call("show_result",{"won":true,"saved":true,"time":620,"kills":134,"level":21,"credits":350})
	await _inspect_ui_bounds("victory")
	await capture("bounds-result")
	layer.call("show_result",{"won":false,"saved":false,"save_error":"無法寫入存檔","time":52,"kills":12,"level":4,"credits":15})
	await _inspect_ui_bounds("defeat")
	layer.call("show_confirm","本次出擊將失去尚未結算的進度。",func() -> void: pass)
	await _inspect_ui_bounds("confirm")
	layer.call("clear_popups")
	var in_battle: Dictionary = snap()
	in_battle["state"] = "playing"
	layer.call("update_hud",in_battle)
	await _inspect_ui_bounds("hud")
	await capture("bounds-hud")

func test_menu_v3_motion() -> void:
	check(DisplayServer.get_name() != "headless","v3motion.gpu_required")
	if DisplayServer.get_name() == "headless": return
	var layer: Node = ui_node()
	layer.call("set_preferences",{"music":0.65,"effects":0.8,"shake":0.8,"reduce_motion":false})
	game.call("show_menu")
	await seconds(0.8)
	var scene: Control = layer.get("popup").get_node_or_null("MainMenuView")
	check(scene != null,"v3motion.scene_loaded")
	if scene == null:return
	var rig: Node2D = scene.get_node_or_null("HeroDisplay/HeroRig") as Node2D
	check(rig != null and rig.has_method("motion_snapshot"),"v3motion.articulated_rig")
	if rig == null: return
	var start_state: Dictionary = rig.call("motion_snapshot")
	await capture("v3rig-start")
	await seconds(0.92)
	var later: Dictionary = rig.call("motion_snapshot")
	check(absf(float(later["head_deg"])-float(start_state["head_deg"])) > 0.07,"v3motion.head_independent_motion",later)
	check(absf(float(later["left_arm_deg"])-float(start_state["left_arm_deg"])) > 0.07,"v3motion.left_arm_motion",later)
	check(absf(float(later["right_arm_deg"])-float(start_state["right_arm_deg"])) > 0.07,"v3motion.right_arm_motion",later)
	check(absf(float(later["torso_y"])-float(start_state["torso_y"])) > 0.2,"v3motion.torso_motion",later)
	await capture("v3rig-articulated")
	await click("open_settings")
	await seconds(0.38)
	check(str(layer.get("current_screen")) == "settings","v3motion.settings_open")
	await click("toggle_reduce_motion")
	check(bool(layer.get("audio_options").get("reduce_motion",false)),"v3motion.option_enabled")
	await click("close_settings")
	await seconds(0.20)
	scene = layer.get("popup").get_node_or_null("MainMenuView")
	check(scene != null and bool(scene.get("reduced_motion")),"v3motion.reduced_motion_propagated")
	if scene == null: return
	rig = scene.get_node_or_null("HeroDisplay/HeroRig")
	var initial: Dictionary = rig.call("motion_snapshot")
	await seconds(0.45)
	var frozen: Dictionary = rig.call("motion_snapshot")
	check(not bool(frozen.get("motion_enabled",true)),"v3motion.joints_frozen")
	check(absf(float(initial["head_deg"])-float(frozen["head_deg"])) < 0.001,"v3motion.head_static")
	var particles: GPUParticles2D = scene.get_node_or_null("Environment/HangarDust")
	check(particles != null and not particles.emitting,"v3motion.particles_off")
	check(not scene.get_node("Animations").is_playing(),"v3motion.light_loop_off")
	await capture("v3rig-reduce-motion")
	await click("open_settings")
	await click("toggle_reduce_motion")
	check(not bool(layer.get("audio_options").get("reduce_motion",true)),"v3motion.option_disabled")
	await click("close_settings")
	await seconds(0.3)
	scene = layer.get("popup").get_node_or_null("MainMenuView")
	check(scene != null and not bool(scene.get("reduced_motion")),"v3motion.normal_animations_restored")
	check(scene.get_node("Animations").is_playing(),"v3motion.light_loop_restored")
	# The persisted user preference is never written in isolated automated runs.

func test_menu_v3_performance() -> void:
	check(DisplayServer.get_name() != "headless","v3perf.gpu_required")
	if DisplayServer.get_name() == "headless": return
	game.call("show_menu")
	await seconds(1.1)
	var scene: Control = ui_node().get("popup").get_node_or_null("MainMenuView")
	check(scene != null,"v3perf.scene_available")
	if scene == null:return
	var timings: Array[float] = []
	var last: int = Time.get_ticks_usec()
	for frame in range(360):
		await get_tree().process_frame
		var now: int = Time.get_ticks_usec()
		if frame > 20: timings.append(float(now-last)/1000.0)
		last = now
	timings.sort()
	var total: float = 0.0
	for dt in timings: total += dt
	var mean: float = total / maxf(1.0,float(timings.size()))
	var p95: float = timings[int(float(timings.size()-1)*0.95)]
	var mean_fps: float = 1000.0/maxf(0.001,mean)
	var measures: Dictionary = {"mean_fps":mean_fps,"mean_ms":mean,"p95_ms":p95,"samples":timings.size(),"renderer_fps":Engine.get_frames_per_second(),"viewport":str(get_viewport().get_visible_rect().size)}
	notes.append("v3 performance: " + JSON.stringify(measures))
	check(timings.size()>=300,"v3perf.samples_collected",measures)
	check(mean_fps>=58.0,"v3perf.60fps_approx_target",measures)
	check(p95<22.0,"v3perf.frame_p95_under22ms",measures)

func test_cinematic_menu_v3() -> void:
	check(DisplayServer.get_name() != "headless","v3.rendered_gpu_required")
	if DisplayServer.get_name() == "headless": return
	game.call("show_menu")
	var ui_ref: Node = ui_node()
	var pop: Control = ui_ref.get("popup")
	await get_tree().process_frame
	var scene: Control = pop.get_node_or_null("MainMenuView")
	check(scene != null,"v3.separate_scene_loaded")
	if scene == null: return
	check(scene.get_script().resource_path.ends_with("ScifiMainMenuV3.gd"),"v3.preview_selected")
	for path in ["Environment/HangarFar","Environment/HangarMid","Environment/LightRays","Environment/HangarDust","HeroDisplay/HeroRig/Head","HeroDisplay/HeroRig/LeftArm","HeroDisplay/HeroRig/RightArm","HeroDisplay/HeroRig/Torso","HeroDisplay/HeroRig/Legs","HeroDisplay/ForegroundRails","MainUI/Navigation","MainUI/MissionBanner","MainUI/VersionFrame","Animations"]:
		check(scene.get_node_or_null(path) != null,"v3.visual_layer."+path.replace("/","_"))
	var top_button: Button = scene.find_child("Command_open_loadout",true,false) as Button
	check(top_button != null and top_button.size.y >= 88,"v3.primary_navigation")
	await capture("v3-entry")
	await seconds(0.85)
	await capture("v3-settled")
	var buttons: Array[Button] = []
	for action in ["open_loadout","open_meta","open_scores","open_settings","tutorial","open_credits","quit"]:
		var button: Button = scene.find_child("Command_"+action,true,false) as Button
		check(button != null,"v3.action."+action)
		if button != null:
			var english: Label = button.find_child("EnglishLabel",true,false) as Label
			check(english != null and not english.text.is_empty(),"v3.bilingual_navigation."+action)
			var rect: Rect2 = button.get_global_rect()
			check(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= 1920 and rect.end.y <= 1080,"v3.action_bounds."+action,rect)
			for old_button in buttons:
				check(not rect.intersects(old_button.get_global_rect()),"v3.nonoverlap."+action)
			buttons.append(button)
	var credit_label: Label = scene.get_node_or_null("MainUI/CreditCount")
	var history_label: Label = scene.get_node_or_null("MainUI/HistoryCount")
	check(credit_label != null and credit_label.text.contains("信用點"),"v3.real_credits_visible")
	check(history_label != null and history_label.text.contains("作戰紀錄"),"v3.local_scores_visible")
	check(scene.get_node("Animations").is_playing(),"v3.ambient_animation_active")
	if top_button: top_button.grab_focus()
	await capture("v3-focused")
	await click("open_settings")
	await seconds(0.34)
	check(str(ui_ref.get("current_screen")) == "settings","v3.settings_navigates")
	await click("close_settings")
	await seconds(0.35)
	check(str(ui_ref.get("current_screen")) == "menu","v3.settings_returns")
	await click("tutorial")
	await seconds(0.34)
	check(str(ui_ref.get("current_screen")) == "tutorial","v3.tutorial_navigates")
	await click("skip_tutorial")
	await seconds(0.34)
	await click("open_scores")
	await seconds(0.34)
	check(str(ui_ref.get("current_screen")) == "scores","v3.scores_navigates")
	await click("menu")
	await seconds(0.34)
	await click("open_meta")
	await seconds(0.34)
	check(str(ui_ref.get("current_screen")) == "meta","v3.meta_navigates")
	await click("menu")
	await seconds(0.34)
	await click("open_credits")
	await seconds(0.34)
	check(str(ui_ref.get("current_screen")) == "credits","v3.credits_navigates")
	await click("menu")
	await seconds(0.34)
	await click("open_loadout")
	await seconds(0.34)
	check(str(ui_ref.get("current_screen")) == "loadout","v3.loadout_navigates")
	await capture("v3-loadout")

func test_main_menu_only() -> void:
	check(DisplayServer.get_name() != "headless","menu.requires_gpu")
	if DisplayServer.get_name() == "headless": return
	game.call("show_menu")
	await seconds(0.85)
	var ui_node_ref: Node = ui_node()
	var layer: Control = ui_node_ref.get("popup")
	check(layer.get_node_or_null("MainMenuView") != null,"menu.scene_loaded")
	var menu_v2 := layer.get_node_or_null("MainMenuView")
	if menu_v2 != null:
		check(menu_v2.get_node_or_null("MaintenanceBay") != null,"menu.authored_bay_visible")
		check(menu_v2.get_node_or_null("MainUnit1103") != null,"menu.crisp_mech_separate_layer")
		var primary: Button = menu_v2.get_node_or_null("Command_open_loadout") as Button
		check(primary != null and primary.size.y >= 95,"menu.primary_action_hierarchy")
	var checks: Array[String] = ["open_loadout","open_meta","open_scores","open_settings","tutorial","open_credits","quit"]
	var located: Array[Rect2] = []
	for key in checks:
		var found: Button = null
		for candidate in get_tree().get_nodes_in_group("scifi_buttons"):
			if candidate is Button and candidate.is_visible_in_tree() and candidate.get_meta("scifi_action","") == key:
				found = candidate
				break
		check(found != null,"menu.action_"+key)
		if found != null:
			var box: Rect2 = found.get_global_rect()
			check(box.position.x >= 0 and box.position.y >= 0 and box.end.x <= 1920 and box.end.y <= 1080,"menu.action_in_viewport_"+key)
			if found.position.x < 710: located.append(box)
	for i in range(located.size()):
		for j in range(i+1,located.size()):
			check(not located[i].intersects(located[j]),"menu.navigation_nonoverlap_%d_%d"%[i,j])
	await capture("menu-settled")
	await click("open_settings")
	check(str(ui_node_ref.get("current_screen")) == "settings","menu.settings_functional")
	await click("close_settings")
	await click("tutorial")
	check(str(ui_node_ref.get("current_screen")) == "tutorial","menu.tutorial_functional")
	await click("skip_tutorial")
	await click("open_scores")
	check(str(ui_node_ref.get("current_screen")) == "scores","menu.scores_functional")
	await click("menu")
	await click("open_meta")
	check(str(ui_node_ref.get("current_screen")) == "meta","menu.meta_functional")
	await click("menu")
	await click("open_credits")
	check(str(ui_node_ref.get("current_screen")) == "credits","menu.credits_functional")
	await click("menu")
	await click("open_loadout")
	check(str(ui_node_ref.get("current_screen")) == "loadout","menu.loadout_functional")
	await capture("menu-to-loadout")

func test_ui_flow() -> void:
	check(DisplayServer.get_name()!="headless","ui.requires_rendered_viewport")
	if DisplayServer.get_name()=="headless":
		return
	check(ui_node()!=null,"ui.exists")
	if ui_node()==null:
		return
	var score_path:=isolated_root().path_join("huazi_scores.json")
	var legacy:=JSON.stringify({"scores":[{"score":12345,"kills":7,"game_time":88.0,"result":"victory","created_at":"2026-10-13T12:00:00"}]})
	write_text(score_path,legacy)
	game.call("show_menu")
	await seconds(1.1) # Capture settled main-menu animations rather than mid-fade frames.
	var menu_view: Control = ui_node().get("popup").get_node_or_null("MainMenuView")
	check(menu_view != null,"ui.main_menu_separate_scene")
	var menu_actions: Array[String] = ["open_loadout","open_meta","open_scores","open_settings","tutorial","open_credits","quit"]
	var menu_rectangles: Array[Rect2] = []
	for action_key in menu_actions:
		var found_button: Button = null
		for candidate in get_tree().get_nodes_in_group("scifi_buttons"):
			if candidate is Button and candidate.is_visible_in_tree() and candidate.get_meta("scifi_action","")==action_key:
				found_button = candidate
				break
		check(found_button != null,"ui.main_menu_nav_"+action_key)
		if found_button != null:
			var bounds: Rect2 = found_button.get_global_rect()
			check(bounds.position.x >= 0 and bounds.position.y >= 0 and bounds.end.x <= 1920 and bounds.end.y <= 1080,"ui.main_menu_nav_visible_"+action_key)
			if found_button.position.x < 710: menu_rectangles.append(bounds)
	for first in range(menu_rectangles.size()):
		for second in range(first+1,menu_rectangles.size()):
			check(not menu_rectangles[first].intersects(menu_rectangles[second]),"ui.main_menu_nav_no_overlap_%d_%d"%[first,second])
	await capture("menu")
	await click("open_settings")
	check(str(ui_node().get("current_screen"))=="settings","ui.audio_settings_open")
	await capture("settings")
	var prior_sfx := float(game.get("sound").preferences().get("effects",0.8))
	await click("adjust_effects_down")
	check(float(game.get("sound").preferences().get("effects",0.0)) < prior_sfx,"ui.audio_settings_actual_change")
	await click("close_settings")
	await click("tutorial")
	check(str(ui_node().get("current_screen"))=="tutorial","ui.tutorial_open")
	await capture("tutorial-01")
	await click("next_tutorial")
	check(int(ui_node().get("tutorial_page"))==1,"ui.tutorial_step_two")
	await capture("tutorial-02")
	await click("skip_tutorial")
	check(str(ui_node().get("current_screen"))=="menu","ui.tutorial_skip_returns_menu")
	await click("open_scores")
	check(str(ui_node().get("current_screen"))=="scores","ui.scores_open")
	var loaded: Array=ui_node().get("cached_scores")
	check(not loaded.is_empty() and int(loaded[0].get("score",0))==12345,"ui.old_score_real_caller")
	await capture("legacy-scores")
	await click("menu")
	await click("open_meta")
	check(str(ui_node().get("current_screen"))=="meta","ui.meta_open")
	await capture("meta-empty")
	await click("menu")
	if str(ui_node().get("current_screen"))=="menu":
		await click("open_loadout")
	check(str(ui_node().get("current_screen"))=="loadout","ui.loadout_open")
	await click("select_weapon","grenade")
	check(str(ui_node().get("selected_weapon"))=="grenade","ui.weapon_selection_click")
	await click("select_weapon","rail")
	await capture("loadout")
	await click("deploy")
	check(str(snap().get("state",""))=="playing","ui.deploy_real_click")
	set_movement(Vector2.RIGHT)
	for frame in range(60):
		if str(snap().get("state",""))=="upgrade":
			var visible: Array=snap().get("cards",[])
			if not visible.is_empty(): await click("choose_card",visible[0].id)
		await capture("normal-motion-%03d"%frame)
		await seconds(0.1)
	set_movement(Vector2.ZERO)
	await capture("normal-battle")
	await click("skill",0)
	check(float(snap().get("skills",[])[0].get("remaining",0))>0,"ui.skill_click_casts")
	await capture("skill-cooldown")
	await press_key(KEY_ESCAPE)
	check(str(snap().get("state",""))=="paused","ui.pause_keyboard")
	await capture("pause")
	await click("menu")
	check(str(ui_node().get("current_screen"))=="confirm","ui.leave_confirmation")
	await capture("leave-confirmation")
	await click("cancel_leave")
	check(str(snap().get("state",""))=="paused","ui.leave_cancel_preserves_run")
	await click("resume")
	check(str(snap().get("state",""))=="playing","ui.resume_after_leave_cancel")
	fixture("open_upgrade")
	await capture("fixture-upgrade-three")
	var cards: Array=snap().get("cards",[])
	if not cards.is_empty(): await click("choose_card",cards[0].id)
	check(str(snap().get("state",""))=="playing","ui.upgrade_real_click")
	fixture("seed_build",{"weapons":{"rail":{"level":5,"evolved":false}},"passives":{"firecontrol":3}})
	fixture("open_upgrade",{"cards":["evolve:rail"]})
	await capture("fixture-evolution-choice")
	await click("choose_card","evolve:rail")
	check(bool(snap().get("weapons",{}).get("rail",{}).get("evolved",false)),"ui.evolution_click")
	await capture("fixture-evolved-battle")
	fixture("set_time",{"time":480})
	await seconds(0.5)
	check(int(snap().get("boss",{}).get("spawn_count",0))==1,"ui.boss_visible_state")
	var boss_panel: Control=ui_node().get("boss_panel")
	var hud: Control=ui_node().get("hud")
	var left_panel: Control=hud.get_child(0)
	check(boss_panel.visible and not boss_panel.get_global_rect().intersects(left_panel.get_global_rect()),"ui.boss_panel_no_left_hud_overlap",{"boss":str(boss_panel.get_global_rect()),"left_hud":str(left_panel.get_global_rect())})
	await capture("fixture-boss")
	fixture("save_fault",{"point":"temp_write"})
	game.call("finish_run",false)
	await capture("fixture-save-failure")
	await click("menu")
	check(str(snap().get("state",""))=="result","ui.pending_blocks_leave")
	fixture("save_fault",{"point":""})
	await click("retry_save")
	check(snap().get("pending_settlement",{}).is_empty(),"ui.retry_real_click")
	var notice: Label=ui_node().get("notice")
	check(not notice.visible and notice.text.is_empty(),"ui.saved_result_clears_stale_notice",{"visible":notice.visible,"text":notice.text})
	await capture("defeat-saved")
	await click("menu")
	check(str(snap().get("state",""))=="loadout","ui.restart_returns_loadout")
	await click("deploy")
	fixture("reset_arena",{"spawning":false})
	fixture("set_time",{"time":480})
	await seconds(0.1)
	var boss: Dictionary=snap().get("boss",{})
	fixture("force_damage",{"target":boss.get("id",""),"damage":100000})
	await seconds(0.1)
	check(bool(snap().get("result",{}).get("won",false)),"ui.boss_death_victory")
	await capture("fixture-victory")
	game.call("return_to_loadout")
	ui_node().call("show_meta",snap().get("progress",{}))
	var before:=int(snap().get("progress",{}).get("upgrades",{}).get("hp",0))
	await click("purchase","hp")
	check(int(snap().get("progress",{}).get("upgrades",{}).get("hp",0))==before+1,"ui.purchase_real_click")
	await capture("meta-purchased")
	check(read_text(score_path)==legacy,"ui.legacy_score_unchanged")
	sample("rendered-ui-flow-finished")
	notes.append("normal-motion sequence is unmodified ordinary-clock battle; screenshots named fixture use explicit state setup without debug overlays. Independent visual comparison is still required.")

func test_audio() -> void:
	check(DisplayServer.get_name()!="headless","audio.requires_runtime_audio")
	if DisplayServer.get_name()=="headless": return
	await clean("grenade",["pulse","shield"])
	var sound: Node=game.get("sound")
	var bgm: Dictionary=sound.call("bgm_status")
	check(bool(bgm.get("playing",false)) and bool(bgm.get("loop_enabled",false)),"audio.bgm_plays_and_loops")
	check(float(bgm.get("stream_length_seconds",0))>1,"audio.bgm_nonempty")
	sound.call("stop_bgm")
	var effect:=AudioEffectCapture.new()
	effect.buffer_length=2
	var bus:=AudioServer.get_bus_index("Master")
	var effect_index:=AudioServer.get_bus_effect_count(bus)
	AudioServer.add_bus_effect(bus,effect)
	fixture("add_enemy",{"kind":"crawler","position":[2200,1152],"hp":20,"speed":0,"contact_damage":0})
	await seconds(1.1)
	var buffer:=effect.get_buffer(effect.get_frames_available())
	var energy:=0.0
	for frame in buffer:
		energy+=frame.length_squared()
	check(buffer.size()>0 and energy>0.000001,"audio.real_attack_hit_explosion_samples",{"frames":buffer.size(),"energy":energy})
	var data:=snap()
	for event in ["attack","hit","death","explosion"]:
		check(not event_list(data,event).is_empty(),"audio.real_source_event."+event)
	var players: Dictionary=sound.get("players")
	for key in players:
		var audio_player: AudioStreamPlayer=players[key]
		check(audio_player.stream!=null and audio_player.stream.get_length()>0,"audio.stream_nonempty."+str(key))
		check(audio_player.volume_db>-60 and audio_player.bus=="Master","audio.player_audible_config."+str(key))
	AudioServer.remove_bus_effect(bus,effect_index)
	sample("audio-actual-bus-samples")
	notes.append("AudioEffectCapture measured real Master-bus samples, not the listener's speaker hardware. Remaining event coverage is correlated through source events and actual SfxBus counters; human listening remains a distinct check.")

func test_directions() -> void:
	await clean()
	var actor: Node=game.get("player")
	for index in range(DIRECTIONS.size()):
		set_movement(DIRECTIONS[index])
		await seconds(0.25)
		var data:=sample("player-direction-%d"%index)
		check(vector(player(data).get("velocity")).dot(DIRECTIONS[index])>300,"directions.real_input."+str(index))
		await capture("direction-player-%d"%index)
	set_movement(Vector2.ZERO)
	for kind in ["crawler","spider","heavy","turret"]:
		for index in range(DIRECTIONS.size()):
			fixture("reset_arena",{"spawning":false})
			var at: Vector2=vector(player(snap()).get("position"))-DIRECTIONS[index]*600
			var id: Variant=fixture("add_enemy",{"kind":kind,"position":[at.x,at.y],"hp":100000})
			await seconds(0.25)
			check(not entity(snap(),id).is_empty(),"directions.enemy_active.%s.%d"%[kind,index])
			await capture("fixture-direction-%s-%d"%[kind,index])
	check(actor!=null,"directions.real_actor")
	notes.append("Rendered direction images must be compared with source poses and source frame durations; animation names alone are insufficient.")

func test_collisions() -> void:
	await clean()
	var terrain: Node = game.get("world_collision")
	check(terrain != null,"collision.terrain_node")
	if terrain == null: return
	check(int(terrain.get("obstacle_count"))>=40,"collision.generated_prop_footprints")
	var character: CharacterBody2D = game.get("player")
	check(character != null and character.get_child_count() > 0, "collision.character_body")
	check(character.collision_layer==2 and character.collision_mask==5,"collision.player_collision_layers")
	var test_rect := Rect2()
	var found := false
	for rect in terrain.get("footprints"):
		var approach: Vector2 = Vector2(rect.position.x - 39.0,rect.get_center().y)
		if terrain.clear_at(approach,30):
			test_rect = rect
			found = true
			break
	check(found,"collision.available_obstacle_approach")
	if not found: return
	var approach := Vector2(test_rect.position.x-39.0,test_rect.get_center().y)
	fixture("set_player",{"position":[approach.x,approach.y]})
	set_movement(Vector2.RIGHT)
	for step in range(35): await get_tree().physics_frame
	var at := vector(player(snap()).position)
	check(at.x <= test_rect.position.x - 27.0,"collision.player_blocked_by_prop",{"position":at,"box":test_rect})
	await capture("collision-normal-blocked")
	set_movement(Vector2.ZERO)
	fixture("set_player",{"position":[approach.x,approach.y]})
	set_movement(Vector2.RIGHT)
	check(bool(game.call("use_skill",0)),"collision.dash_started")
	for step in range(22): await get_tree().physics_frame
	at = vector(player(snap()).position)
	check(at.x <= test_rect.position.x - 27.0,"collision.dash_does_not_cross_prop",{"position":at,"box":test_rect})
	await capture("collision-dash-blocked")
	set_movement(Vector2.ZERO)
	fixture("reset_arena",{"spawning":false})
	fixture("set_player",{"position":[test_rect.end.x + 160.0,test_rect.get_center().y]})
	var enemy_id: Variant = fixture("add_enemy",{"kind":"crawler","position":[approach.x,approach.y],"speed":135,"contact_damage":0})
	for step in range(32): await get_tree().physics_frame
	var foe := entity(snap(),enemy_id)
	check(not foe.is_empty(),"collision.enemy_active")
	if not foe.is_empty():
		check(vector(foe.position).x <= test_rect.end.x + 22.0,"collision.enemy_obstacle_response",foe.position)
	var wall: Dictionary = game.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(test_rect.position.x-120.0,test_rect.get_center().y),Vector2(test_rect.end.x+120.0,test_rect.get_center().y),1))
	check(not wall.is_empty(),"collision.physics_ray_hits_prop")
	fixture("reset_arena",{"spawning":false})
	fixture("set_player",{"position":[test_rect.end.x+145.0,test_rect.get_center().y],"hp":120,"invulnerable":0.0})
	fixture("add_enemy_projectile",{"position":[test_rect.position.x-110.0,test_rect.get_center().y],"velocity":[500,0],"damage":16,"life":1.5})
	for frame in range(35): await get_tree().physics_frame
	check(int(snap().counts.enemy_projectiles)==0,"collision.wall_absorbs_enemy_projectile")
	check(near(float(snap().hp),120.0,0.01),"collision.no_projectile_damage_through_prop")
	# An enemy CharacterBody2D is stopped by the player collider before shapes overlap.
	# Validate physical body contact, not only center-distance overlap.
	fixture("reset_arena",{"spawning":false})
	fixture("set_player",{"position":[2048,1152],"hp":120.0,"invulnerable":0.0,"shield":0.0})
	set_movement(Vector2.ZERO)
	var contact_id: Variant = fixture("add_enemy",{"kind":"crawler","position":[2180,1152],"hp":100000.0,"speed":180.0,"contact_damage":10.0})
	for frame in range(110): await get_tree().physics_frame
	var contact_snapshot := snap()
	check(float(contact_snapshot.hp) < 120.0,"collision.enemy_physics_contact_damages_player",{"hp":contact_snapshot.hp,"player_pos":contact_snapshot.position,"state":contact_snapshot.state,"invulnerable":game.get("invulnerable"),"dash_remaining":game.get("dash_remaining"),"shield":game.get("shield"),"enemy":entity(contact_snapshot,contact_id)})
	notes.append("Godot StaticBody2D collision, CharacterBody2D normal movement, dash, enemy/player physical contact and map geometry tested. No debug outlines in normal mode.")

func test_replay() -> void:
	var traces: Array=[]
	for repetition in range(2):
		await clean()
		fixture("reset_arena",{"spawning":true})
		var trace: Array=[]
		for step in range(12):
			set_movement(DIRECTIONS[step%8])
			# Wait for completion, not physics_frame (emitted BEFORE _physics_process).
			# This preserves the required exact 30 real physics updates per input.
			for tick_index in range(30): await game.physics_advanced
			var data:=snap()
			trace.append({"time":data.time,"position":player(data).position,"hp":player(data).hp,"kills":data.kills,"counts":data.counts})
		set_movement(Vector2.ZERO)
		traces.append(trace)
	for index in range(12):
		var first: Dictionary=traces[0][index]
		var second: Dictionary=traces[1][index]
		check(near(float(first.time),float(second.time),0.02),"replay.time."+str(index))
		check(vector(first.position).distance_to(vector(second.position))<6,"replay.position."+str(index))
		check(first.hp==second.hp and first.kills==second.kills and first.counts==second.counts,"replay.state."+str(index))
	samples.append({"label":"replay-traces","traces":traces})

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless" or output_path.is_empty():
		return
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := output_path.get_basename()+"-"+label+".png"
	check(image.save_png(path)==OK,"capture."+label,path)

func finish() -> void:
	set_movement(Vector2.ZERO)
	if scenario=="growth":
		flush_growth_events()
		write_growth_snapshot("final",snap())
		growth_operation("harness_finish",{"reason":growth_exit_reason,"last_event_serial":last_event_serial,"fixture_calls":fixture_calls,"natural_frame_count":growth_frame_index})
	if growth_event_file: growth_event_file.close()
	if growth_operation_file: growth_operation_file.close()
	if growth_snapshot_file: growth_snapshot_file.close()
	growth_observing=false
	var failed:=0
	for item in assertions:
		if not item.passed:
			failed+=1
	var result := {"scenario":scenario,"status":"logic_passed" if failed==0 else "failed","acceptance_status":"partially_verified" if failed==0 else "not_verified","assertions":assertions,"failed":failed,"samples":samples,"notes":notes,"fixture_calls":fixture_calls,"growth_exit_reason":growth_exit_reason,"event_serial_last":last_event_serial,"natural_frame_count":growth_frame_index,"engine":Engine.get_version_info(),"source_hashes":source_hashes,"wall_ms":Time.get_ticks_msec()-started_ticks}
	if not output_path.is_empty():
		DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
		var file:=FileAccess.open(output_path,FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(result,"\t"))
			file.close()
		else:
			push_error("SCIFI_TEST_REPORT_WRITE_FAILED "+output_path)
			failed+=1
	print("SCIFI_TEST_DONE scenario=%s failed=%d report=%s" % [scenario,failed,output_path])
	get_tree().quit(0 if failed==0 else 1)
