extends RefCounted

const C = preload("res://scripts/scifi/ScifiConfig.gd")
var main:Node
var thermal_field:Dictionary = {}

func _init(owner_node:Node) -> void:
	main = owner_node

func stats(key:String) -> Dictionary:
	var build = main.weapons[key]
	var config = C.WEAPONS[key]
	var damage = config.damage * pow(C.LEVEL_DAMAGE,int(build.level)-1) * (1.0 + C.ECONOMY.damage * main.meta("damage"))
	if key == "rail":
		damage *= 1.0 + 0.12 * main.passives.firecontrol
	if build.evolved:
		damage *= C.EVOLUTION_DAMAGE
	return {"damage":damage,"cooldown":config.cooldown * pow(C.LEVEL_CD,int(build.level)-1) * (1.0-C.ECONOMY.weapon_cd*main.meta("weapon_cd"))}

func update(delta:float) -> void:
	for key in main.weapons:
		main.weapons[key].remaining = maxf(0,main.weapons[key].remaining-delta)
		if main.weapons[key].remaining <= 0 and fire(key):
			main.weapons[key].remaining = stats(key).cooldown
	_update_thermal(delta)
	for p in main.pools.projectiles:
		if not p.active:
			continue
		p.age += delta
		p.life -= delta
		var previous:Vector2 = p.position
		if p.kind == "blade":
			_advance_blade(p,delta)
		else:
			p.position += p.velocity*delta
		p.node.position = p.position
		p.node.rotation = (p.position-previous).angle()
		var wall: Dictionary = main.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(previous,p.position,1))
		if not wall.is_empty():
			p.position = wall.position
			p.node.position = p.position
			if p.kind == "grenade":
				explode(p)
			else:
				main.effect("impact",p.position,0.12)
			main.release("projectiles",p)
			continue
		if p.kind == "grenade":
			if p.life <= 0 or p.position.distance_to(p.target) <= p.speed*delta:
				explode(p)
				main.release("projectiles",p)
			continue
		for enemy in main.pools.enemies:
			if not enemy.active or enemy.hp <= 0:
				continue
			var distance = Geometry2D.get_closest_point_to_segment(enemy.position,previous,p.position).distance_to(enemy.position)
			if distance > enemy.radius + 10:
				continue
			if p.hits.has(enemy.id) and (p.kind != "blade" or main.time-float(p.hits[enemy.id]) < C.WEAPONS.blade.repeat_cd):
				continue
			p.hits[enemy.id] = main.time
			main.hit_enemy(enemy,p.damage,p.id,p.weapon)
			p.remaining_hits -= 1
			if p.remaining_hits <= 0:
				break
		if p.life <= 0 or p.remaining_hits <= 0:
			main.release("projectiles",p)

func _blade_curve(origin:Vector2,direction:Vector2,sign_value:int) -> Array:
	var points:Array = []
	var config = C.WEAPONS.blade
	for i in range(config.curve_samples+1):
		var phase = float(i)/config.curve_samples
		points.append(origin+direction*sin(phase*PI)*config.range+direction.orthogonal()*sin(phase*TAU)*config.range*config.curve_width*sign_value)
	return points

func _advance_blade(projectile:Dictionary,delta:float) -> void:
	var travel:float = projectile.speed*delta
	while travel > 0 and projectile.curve_index < projectile.curve_points.size():
		var next_point:Vector2 = projectile.curve_points[projectile.curve_index]
		var distance:float = projectile.position.distance_to(next_point)
		if distance <= travel:
			projectile.position = next_point
			travel -= distance
			projectile.curve_index += 1
		else:
			projectile.position = projectile.position.move_toward(next_point,travel)
			travel = 0

func _update_thermal(delta:float) -> void:
	if thermal_field.is_empty(): return
	var zone = thermal_field
	zone.life -= delta
	zone.hit_timer -= delta
	if zone.hit_timer <= 0:
		zone.hit_timer += C.WEAPONS.thermal.cooldown
		var count = 0
		var candidates = main.pools.enemies.filter(func(e): return e.active and e.hp > 0)
		candidates.sort_custom(func(a,b): return zone.origin.distance_squared_to(a.position) < zone.origin.distance_squared_to(b.position))
		for enemy in candidates:
			if zone.origin.distance_to(enemy.position) <= zone.range and absf(zone.direction.angle_to(zone.origin.direction_to(enemy.position))) <= deg_to_rad(C.WEAPONS.thermal.angle/2):
				main.hit_enemy(enemy,zone.damage,zone.source_id,"thermal")
				count += 1
				if not zone.evolved and count >= C.WEAPONS.thermal.targets: break
	if zone.life <= 0: thermal_field.clear()

func nearest(position:Vector2, distance:float = INF, excluded:Array = []) -> Dictionary:
	var result:Dictionary = {}
	for e in main.pools.enemies:
		if not e.active or e.hp <= 0 or excluded.has(e.id):
			continue
		var d = position.distance_to(e.position)
		if d < distance:
			result = e
			distance = d
	return result

func fire(key:String) -> bool:
	var cfg = C.WEAPONS[key]
	var origin:Vector2 = main.player.position
	var target = nearest(origin)
	if target.is_empty():
		return false
	var first_target_id:String = target.id
	var direction:Vector2 = origin.direction_to(target.position)
	var amount = stats(key).damage
	var evolved:bool = main.weapons[key].evolved
	if key == "arc":
		target = nearest(origin,cfg.range)
		if target.is_empty():
			return false
		var visited:Array = []
		var start = origin
		for i in range(int(cfg.chains)+int(main.passives.capacitor)+(int(cfg.evolved_chains) if evolved else 0)):
			if target.is_empty():
				break
			visited.append(target.id)
			main.effect("arc",start,0.18,target.position,evolved)
			main.hit_enemy(target,amount,"arc-%d"%main.tick,"arc")
			start = target.position
			target = nearest(start,cfg.jump,visited)
	elif key == "thermal":
		if origin.distance_to(target.position) > (cfg.evolved_range if evolved else cfg.range):
			return false
		var reach:float = cfg.evolved_range if evolved else cfg.range
		var duration = cfg.duration*(1+main.passives.heat*0.15)
		var hit_timer = thermal_field.get("hit_timer",0.0)
		thermal_field = {"origin":origin,"direction":direction,"range":reach,"damage":amount,"life":duration,"hit_timer":hit_timer,"evolved":evolved,"source_id":"thermal-%d"%main.tick}
		main.effect(key,origin,duration,origin+direction*reach,evolved)
	elif key == "frost":
		if origin.distance_to(target.position) > cfg.range:
			return false
		var end = origin+direction*cfg.range
		for e in main.pools.enemies:
			if e.active and e.hp > 0 and Geometry2D.get_closest_point_to_segment(e.position,origin,end).distance_to(e.position) <= (cfg.evolved_width if evolved else cfg.width)/2.0 + e.radius:
				main.hit_enemy(e,amount,"frost-%d"%main.tick,key)
				e.slow = minf(0.65,(cfg.evolved_slow if evolved else cfg.slow)+main.passives.cooling*0.1)
				e.slow_time = cfg.duration
		main.effect(key,origin,0.24,end,evolved)
	elif key == "grenade":
		var best = -1
		for e in main.pools.enemies:
			if not e.active or e.hp <= 0:
				continue
			var count = 0
			for other in main.pools.enemies:
				if other.active and other.hp > 0 and other.position.distance_to(e.position) <= cfg.radius:
					count += 1
			if count > best:
				best = count
				target = e
		var speed = cfg.speed*(1+0.12*main.passives.propulsion)
		spawn(key,origin,origin.direction_to(target.position)*speed,amount,cfg.life,{"target":target.position,"speed":speed,"evolved":evolved})
	elif key == "blade":
		for i in range(2 if evolved else 1):
			spawn(key,origin,Vector2.ZERO,amount,cfg.life,{"direction":direction,"origin":origin,"sign":1 if i == 0 else -1,"speed":cfg.speed*(1+0.12*main.passives.propulsion),"remaining_hits":cfg.hits,"evolved":evolved,"curve_index":1,"curve_points":_blade_curve(origin,direction,1 if i == 0 else -1)})
	else:
		spawn(key,origin,direction*cfg.speed*(1+0.12*main.passives.propulsion),amount,cfg.life,{"remaining_hits":cfg.evolved_hits if evolved else cfg.hits,"evolved":evolved})
	main.record("attack",{"weapon":key,"entity_id":"player","source_id":key,"damage":amount,"target_id":first_target_id,"evolved":evolved})
	main.audio("fire_" + key)
	return true

func spawn(key:String,position:Vector2,velocity:Vector2,damage:float,life:float,extra:Dictionary = {}) -> Dictionary:
	var p = main.acquire("projectiles",{"kind":key,"weapon":key,"position":position,"velocity":velocity,"damage":damage,"life":life,"age":0.0,"remaining_hits":1,"hits":{}}.merged(extra,true))
	if not p.is_empty():
		main.visual(p,key)
	return p

func explode(p:Dictionary) -> void:
	var cfg = C.WEAPONS.grenade
	var radius = cfg.radius*(1+0.15*main.passives.blast)
	for e in main.pools.enemies:
		if e.active and e.hp > 0 and e.position.distance_to(p.position) <= radius:
			main.hit_enemy(e,p.damage,p.id,"grenade")
	main.effect("explosion",p.position,0.45,p.position,p.evolved)
	main.record("explosion",{"entity_id":p.id,"source_id":"grenade","position":[p.position.x,p.position.y],"radius":radius})
	main.audio("explosion")
	if p.evolved:
		for i in range(cfg.children):
			spawn("rail",p.position+Vector2.from_angle(TAU*i/cfg.children)*cfg.child_offset,Vector2.from_angle(TAU*i/cfg.children)*cfg.child_speed,p.damage*cfg.child_damage,cfg.child_life,{"weapon":"grenade","evolved":true})
