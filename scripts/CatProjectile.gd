extends Area2D

const GameConfig = preload("res://scripts/GameConfig.gd")
const DirectionUtil = preload("res://scripts/DirectionUtil.gd")

var cat_type := "orange"
var stats := {}
var velocity := Vector2.RIGHT
var age := 0.0
var active := false
var damage := 1.0
var hit_ids := {}
var target_position := Vector2.ZERO
var start_position := Vector2.ZERO
var total_hits := 0
var last_dir := "e"

var sprite: AnimatedSprite2D

func _ready() -> void:
	sprite = AnimatedSprite2D.new()
	add_child(sprite)

func setup(kind: String, at_position: Vector2, direction: Vector2, final_damage: float, final_speed: float, target_pos: Vector2) -> void:
	cat_type = kind
	stats = GameConfig.CAT_STATS[kind]
	global_position = at_position
	start_position = at_position
	target_position = target_pos
	velocity = direction.normalized() * final_speed
	damage = final_damage
	age = 0.0
	total_hits = 0
	hit_ids.clear()
	active = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	sprite.sprite_frames = load(stats.spriteframes)
	sprite.scale = Vector2(0.72, 0.72)
	last_dir = DirectionUtil.play_direction(sprite, "spin" if cat_type == "cow" else "fly", velocity, last_dir)

func deactivate() -> void:
	active = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED

func step_projectile(delta: float) -> void:
	if not active:
		return
	age += delta
	if cat_type == "cow":
		var t := age * 8.0
		var curve := Vector2(-velocity.y, velocity.x).normalized() * sin(t) * 210.0
		global_position += (velocity + curve) * delta
	else:
		global_position += velocity * delta
	var prefix := "spin" if cat_type == "cow" else "fly"
	last_dir = DirectionUtil.play_direction(sprite, prefix, velocity, last_dir)
	if age >= stats.life or global_position.distance_to(start_position) > stats.get("sweep_range", 1400.0) + 1100.0:
		deactivate()
