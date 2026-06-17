extends Area2D

const GameConfig = preload("res://scripts/GameConfig.gd")

var value := 1
var active := false
var attracting := false
var sprite: Sprite2D

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = load(GameConfig.XP.sprite)
	sprite.scale = Vector2(0.58, 0.58)
	add_child(sprite)

func setup(at_position: Vector2, amount: int) -> void:
	global_position = at_position
	value = amount
	active = true
	attracting = false
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT

func deactivate() -> void:
	active = false
	attracting = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED

func step_xp(delta: float, player_pos: Vector2) -> bool:
	if not active:
		return false
	var distance := global_position.distance_to(player_pos)
	if distance <= GameConfig.XP.pickup_range:
		attracting = true
	if attracting:
		global_position = global_position.move_toward(player_pos, GameConfig.XP.speed * delta)
		sprite.scale = Vector2(0.58, 0.58) * (1.0 + sin(Time.get_ticks_msec() * 0.015) * 0.08)
	return distance <= GameConfig.PLAYER.radius
