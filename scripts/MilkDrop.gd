extends Area2D

const GameConfig = preload("res://scripts/GameConfig.gd")
const DirectionUtil = preload("res://scripts/DirectionUtil.gd")

var velocity := Vector2.RIGHT
var age := 0.0
var active := false
var owner_enemy
var last_dir := "e"

var sprite: AnimatedSprite2D

func _ready() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = load(GameConfig.MILK.spriteframes)
	sprite.scale = Vector2(0.58, 0.58)
	add_child(sprite)

func setup(at_position: Vector2, direction: Vector2, owner) -> void:
	global_position = at_position
	velocity = direction.normalized() * GameConfig.MILK.speed
	age = 0.0
	active = true
	visible = true
	owner_enemy = owner
	if owner_enemy != null:
		owner_enemy.milk_count += 1
	process_mode = Node.PROCESS_MODE_INHERIT
	last_dir = DirectionUtil.play_direction(sprite, "fly", velocity, last_dir)

func deactivate() -> void:
	if active and owner_enemy != null:
		owner_enemy.milk_count = max(0, owner_enemy.milk_count - 1)
	active = false
	visible = false
	owner_enemy = null
	process_mode = Node.PROCESS_MODE_DISABLED

func step_milk(delta: float) -> void:
	if not active:
		return
	age += delta
	global_position += velocity * delta
	last_dir = DirectionUtil.play_direction(sprite, "fly", velocity, last_dir)
	if age >= GameConfig.MILK.life:
		deactivate()
