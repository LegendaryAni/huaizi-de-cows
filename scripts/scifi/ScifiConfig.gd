extends RefCounted

const VERSION = "0.2.1"
const MAP_SIZE = Vector2(4096, 2305)
const BOUNDS = Rect2(80, 80, 3936, 2145)
const PLAYER = {"hp":120.0,"speed":340.0,"radius":30.0,"iframe":0.65}
const CAPS = {"enemies":180,"projectiles":160,"enemy_projectiles":100,"xp":400,"vfx":80}
const WEAPONS = {
	"rail":{"name":"磁軌步槍","evolution":"穿甲磁軌","damage":28.0,"cooldown":0.55,"mod":"firecontrol","speed":900.0,"life":1.3,"hits":1,"evolved_hits":4},
	"grenade":{"name":"智慧榴彈","evolution":"集束榴彈","damage":42.0,"cooldown":1.65,"mod":"blast","speed":450.0,"life":1.5,"radius":140.0,"children":6,"child_damage":0.35,"child_offset":48.0,"child_speed":650.0,"child_life":0.6},
	"blade":{"name":"迴旋刃","evolution":"雙重迴旋刃","damage":22.0,"cooldown":1.1,"mod":"propulsion","speed":520.0,"life":1.5,"range":330.0,"curve_samples":64,"curve_width":0.08,"repeat_cd":0.35,"hits":6},
	"arc":{"name":"電弧放射器","evolution":"連鎖電網","damage":20.0,"cooldown":1.0,"mod":"capacitor","range":620.0,"jump":220.0,"chains":3,"evolved_chains":3},
	"thermal":{"name":"熱能噴射器","evolution":"熔穿噴流","damage":12.0,"cooldown":0.25,"mod":"heat","range":320.0,"evolved_range":500.0,"angle":55.0,"duration":0.35,"targets":3},
	"frost":{"name":"寒霜射線","evolution":"極寒光束","damage":18.0,"cooldown":0.7,"mod":"cooling","range":760.0,"width":26.0,"evolved_width":54.0,"slow":0.25,"evolved_slow":0.55,"duration":1.6}}
const MODS = {"firecontrol":"火控","blast":"爆破","propulsion":"推進","capacitor":"電容","heat":"散熱","cooling":"冷卻"}
const SKILLS = {"dash":{"name":"衝刺","cooldown":4.0,"duration":0.18,"distance":240.0},"pulse":{"name":"電磁脈衝","cooldown":12.0,"duration":1.5,"range":360.0,"boss_slow":0.3},"shield":{"name":"護盾","cooldown":16.0,"duration":4.0,"ratio":0.35},"repair":{"name":"維修","cooldown":20.0,"duration":0.0,"ratio":0.25}}
const ENEMIES = {"crawler":{"asset":"2101","radius":22.0,"hp":32.0,"speed":105.0,"damage":10.0,"xp":5,"scale":3},"spider":{"asset":"2106","radius":20.0,"hp":22.0,"speed":230.0,"damage":8.0,"xp":5,"scale":3},"heavy":{"asset":"2103","radius":35.0,"hp":110.0,"speed":65.0,"damage":17.0,"xp":14,"scale":4},"turret":{"asset":"2105","radius":28.0,"hp":55.0,"speed":80.0,"damage":9.0,"xp":9,"scale":3},"boss":{"asset":"3101","radius":50.0,"hp":9000.0,"speed":75.0,"damage":25.0,"xp":0,"scale":5}}
const SPAWN_INTERVALS = [1.0,0.65,0.45,0.35,0.55]
const RANGED = {"range":400.0,"cooldown":2.2,"damage":10.0,"speed":425.0,"life":3.0}
const BOSS = {"time":480.0,"charge_windup":0.9,"charge_speed":660.0,"charge_duration":0.65,"charge_cd":6.0,"shot_windup":0.65,"shot_cd":3.0,"shot_count":5,"shot_damage":19.0,"shot_speed":480.0,"shot_life":3.0}
const XP = {"base":25,"per_level":12,"range":260.0,"speed":650.0}
const ECONOMY = {"kill":1,"milestone_seconds":60.0,"milestone":15,"win":200,"prices":[60,100,160,240,340],"hp":0.12,"damage":0.1,"weapon_cd":0.05,"skill_cd":0.05}
const LEVEL_DAMAGE = 1.35
const LEVEL_CD = 0.90
const EVOLUTION_DAMAGE = 1.4
const SFX = {"attack":"rail_fire","hit":"hit","death":"enemy_die","boss_death":"boss_die","hurt":"player_hurt","xp":"xp_pickup","upgrade":"level_up","choose":"ui_select","stage":"wave_start","win":"victory","lose":"defeat","skill":"pulse","evolve":"evolve","explosion":"explosion","fire_rail":"rail_fire","fire_grenade":"grenade_fire","fire_blade":"blade_fire","fire_arc":"arc_fire","fire_thermal":"thermal_fire","fire_frost":"frost_fire","hit_rail":"rail_hit","hit_grenade":"grenade_hit","hit_blade":"blade_hit","hit_arc":"arc_hit","hit_thermal":"thermal_hit","hit_frost":"frost_hit","hit_heavy":"hit_heavy","skill_dash":"dash","skill_pulse":"pulse","skill_shield":"shield","skill_repair":"repair"}

static func valid_loadout(value:Variant) -> bool:
	if not value is Dictionary or not value.get("weapon") is String:
		return false
	var selected = value.get("skills")
	if not selected is Array or selected.size() != 2:
		return false
	if not selected[0] is String or not selected[1] is String:
		return false
	return WEAPONS.has(value.weapon) and selected[0] != selected[1] and SKILLS.has(selected[0]) and SKILLS.has(selected[1])