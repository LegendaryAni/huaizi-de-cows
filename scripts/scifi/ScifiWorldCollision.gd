extends Node2D
## Baked visual-prop footprints: these bodies are invisible in normal play.
const C = preload("res://scripts/scifi/ScifiConfig.gd")
const DATA = "res://assets/sprites/scifi/map_obstacles.json"

var footprints: Array[Rect2] = []
var obstacle_count := 0

func _ready() -> void:
	var file := FileAccess.open(DATA, FileAccess.READ)
	if file == null:
		push_error("Missing authoritative map collision data: " + DATA)
		return
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or data.get("map_size",[]).size() != 2 or int(data.map_size[0]) != 4096 or int(data.map_size[1]) != 2305:
		push_error("Invalid map collision data")
		return
	for entry in data.get("obstacles",[]):
		var coords: Array = entry.get("rect",[])
		if coords.size() != 4: continue
		var rect := Rect2(float(coords[0]),float(coords[1]),float(coords[2]),float(coords[3]))
		_add_box(rect,"Prop_%02d_%02d" % [int(entry.get("kind",0)),obstacle_count])
		footprints.append(rect)
		obstacle_count += 1
	# Visible perimeter crates are not pass-through scenery.
	_add_box(Rect2(-200,-180,4250,230),"NorthFence")
	_add_box(Rect2(-200,2255,4500,220),"SouthFence")
	_add_box(Rect2(-200,0,250,2305),"WestFence")
	_add_box(Rect2(4046,0,250,2305),"EastFence")

func _add_box(rect: Rect2, name_value: String) -> void:
	var body := StaticBody2D.new()
	body.name = name_value
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = rect.get_center()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collider.shape = shape
	body.add_child(collider)
	add_child(body)

func clear_at(position: Vector2, radius: float) -> bool:
	# Used only for safe spawn placement; authoritative collision uses Godot physics.
	if position.x - radius < C.BOUNDS.position.x or position.y - radius < C.BOUNDS.position.y:
		return false
	if position.x + radius > C.BOUNDS.end.x or position.y + radius > C.BOUNDS.end.y:
		return false
	for r in footprints:
		var nearest := position.clamp(r.position,r.end)
		if nearest.distance_squared_to(position) < radius * radius:
			return false
	return true

func safe_spawn(wanted: Vector2, radius: float) -> Vector2:
	var start := wanted.clamp(C.BOUNDS.position + Vector2.ONE*radius,C.BOUNDS.end - Vector2.ONE*radius)
	if clear_at(start,radius): return start
	for ring in range(1,11):
		for i in range(16):
			var pos := (start + Vector2.from_angle(TAU*i/16.0) * float(ring*44)).clamp(C.BOUNDS.position+Vector2.ONE*radius,C.BOUNDS.end-Vector2.ONE*radius)
			if clear_at(pos,radius): return pos
	return C.MAP_SIZE / 2
