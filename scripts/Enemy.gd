extends CharacterBody2D

const GameConfig = preload("res://scripts/GameConfig.gd")
const DirectionUtil = preload("res://scripts/DirectionUtil.gd")

signal request_milk(enemy, direction: Vector2)

var enemy_type := "normal"
var stats := {}
var hp := 1.0
var active := false
var milk_timer := 0.0
var milk_count := 0
var hit_flash := 0.0
var last_dir := "s"

var sprite: AnimatedSprite2D

func _ready() -> void:
	sprite = AnimatedSprite2D.new()
	add_child(sprite)

func setup(kind: String, at_position: Vector2, initial_milk_timer := -1.0) -> void:
	enemy_type = kind
	stats = GameConfig.ENEMY_STATS[kind]
	hp = stats.hp
	active = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	global_position = at_position
	milk_timer = initial_milk_timer if initial_milk_timer >= 0.0 else 0.2
	milk_count = 0
	hit_flash = 0.0
	sprite.sprite_frames = load(stats.spriteframes)
	sprite.scale = Vector2(0.78, 0.78)
	sprite.modulate = Color.WHITE
	last_dir = DirectionUtil.play_direction(sprite, stats.anim_prefix, Vector2.DOWN, last_dir)

func deactivate() -> void:
	active = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	milk_count = 0

func step_enemy(delta: float, player_pos: Vector2) -> void:
	if not active:
		return
	if hit_flash > 0.0:
		hit_flash = max(0.0, hit_flash - delta)
		sprite.modulate = Color(1.8, 1.8, 1.8, 1.0)
	else:
		sprite.modulate = Color.WHITE
	var to_player := player_pos - global_position
	var distance := to_player.length()
	var desired := Vector2.ZERO
	if distance <= stats.active_range:
		if enemy_type == "ranged":
			if distance < stats.keep_distance * 0.84:
				desired = -to_player.normalized()
			elif distance > stats.keep_distance * 1.12:
				desired = to_player.normalized()
			else:
				desired = Vector2.ZERO
			milk_timer -= delta
			if milk_timer <= 0.0 and milk_count < stats.max_milk and distance < stats.active_range:
				milk_timer = stats.shoot_interval
				request_milk.emit(self, to_player.normalized())
		else:
			desired = to_player.normalized()
	global_position += desired * stats.speed * delta
	global_position.x = clamp(global_position.x, 40.0, GameConfig.MAP_SIZE.x - 40.0)
	global_position.y = clamp(global_position.y, 40.0, GameConfig.MAP_SIZE.y - 40.0)
	if desired.length_squared() > 0.001:
		last_dir = DirectionUtil.play_direction(sprite, stats.anim_prefix, desired, last_dir)

func take_damage(amount: float) -> bool:
	hp -= amount
	hit_flash = 0.09
	return hp <= 0.0
