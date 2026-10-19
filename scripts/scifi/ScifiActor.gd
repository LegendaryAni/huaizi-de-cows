extends CharacterBody2D

const DIRS = ["e","se","s","sw","w","nw","n","ne"]
var sprite:AnimatedSprite2D
var hit_shape: CollisionShape2D
var asset_id = ""
var facing = "s"
var frame_sets:Dictionary = {}
var sprite_anchor := Vector2.ZERO
var feedback_remaining := 0.0
var feedback_duration := 0.12
var recoil_direction := Vector2.ZERO
var recoil_distance := 0.0
var impact_pause := 0.0
var frozen_by_game := false
var impact_tint := Color.WHITE
var native_sprite_scale := Vector2.ONE

# Only presentation is interrupted. Node/world position and combat timers stay unchanged.
func impact_feedback(direction: Vector2, strong: bool = false, weapon: String = "") -> void:
	feedback_duration = 0.16 if strong else 0.105
	feedback_remaining = feedback_duration
	recoil_direction = direction.normalized() if direction.length_squared() > 0.001 else Vector2.UP
	recoil_distance = 11.0 if strong else 5.0
	impact_pause = 0.038 if strong else 0.021
	var palette := {"rail": Color("a6f5ff"), "grenade": Color("ffd18d"), "blade": Color("f1faf4"), "arc": Color("d5b4ff"), "thermal": Color("ffac79"), "frost": Color("b8e9ff"), "hurt": Color("ff8e85")}
	impact_tint = palette.get(weapon, Color.WHITE)
	sprite.modulate = Color(1.55, 1.55, 1.55).lerp(impact_tint,0.30)
	sprite.position = sprite_anchor + recoil_direction * recoil_distance
	sprite.scale = native_sprite_scale * Vector2(1.07, 0.94)
	sprite.speed_scale = 0.0

func _process(delta: float) -> void:
	if frozen_by_game: return
	if impact_pause > 0.0:
		impact_pause = maxf(0.0, impact_pause - delta)
		sprite.speed_scale = 0.0 if impact_pause > 0.0 else 1.0
	if feedback_remaining <= 0.0: return
	feedback_remaining = maxf(0.0, feedback_remaining - delta)
	var fade := feedback_remaining / feedback_duration
	sprite.position = sprite_anchor + recoil_direction * recoil_distance * fade * fade
	sprite.scale = native_sprite_scale * Vector2(1.0 + 0.07 * fade, 1.0 - 0.06 * fade)
	var highlight := Color(1.0 + 0.62 * fade, 1.0 + 0.62 * fade, 1.0 + 0.62 * fade)
	sprite.modulate = highlight.lerp(impact_tint, 0.25 * fade)
	if feedback_remaining <= 0.0:
		sprite.position = sprite_anchor
		sprite.scale = native_sprite_scale
		sprite.modulate = Color.WHITE


func _init() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	max_slides = 4
	safe_margin = 0.04
	hit_shape = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 22.0
	hit_shape.shape = circle
	add_child(hit_shape)

func configure(id:String, factor:int) -> void:
	asset_id = id
	var sizes := {"1103":30.0,"2101":22.0,"2106":20.0,"2103":35.0,"2105":28.0,"3101":50.0}
	(hit_shape.shape as CircleShape2D).radius = float(sizes.get(id,22.0))
	collision_layer = 2 if id == "1103" else 4
	collision_mask = 5 if id == "1103" else 3 # player vs enemies, both vs terrain
	sprite.scale = Vector2.ONE * factor
	native_sprite_scale = sprite.scale
	var is_large = id in ["1103","3101"]
	sprite.position = Vector2(0,-27 if is_large else -19)*factor
	sprite_anchor = sprite.position
	feedback_remaining = 0.0
	impact_pause = 0.0
	sprite.modulate = Color.WHITE
	sprite.speed_scale = 1.0
	frame_sets.clear()
	var combined_path = "res://assets/sprites/scifi/units/%s/frames.tres" % id
	var combined:SpriteFrames = load(combined_path) if ResourceLoader.exists(combined_path) else null
	for action in ["Idle","Walk","Attack","Hurt","Faint","Shoot","Charge"]:
		var path = "res://assets/sprites/scifi/units/%s/%s.spriteframes.tres" % [id,action]
		if combined != null:
			frame_sets[action.to_lower()] = combined
		elif ResourceLoader.exists(path):
			frame_sets[action.to_lower()] = load(path)
	if frame_sets.has("idle"):
		sprite.sprite_frames = frame_sets.idle
	animate(Vector2.ZERO)

func animate(direction:Vector2, action:String = "") -> void:
	if direction.length_squared() > 0.001:
		facing = DIRS[int(round(fposmod(direction.angle(),TAU) / (TAU / 8.0))) % 8]
	var prefix = action if not action.is_empty() else ("walk" if direction.length_squared() > 0.001 else "idle")
	if not frame_sets.has(prefix):
		prefix = "idle"
	if not frame_sets.has(prefix):
		return
	if sprite.sprite_frames != frame_sets[prefix]:
		sprite.sprite_frames = frame_sets[prefix]
	var animation = prefix + "_" + facing
	if not sprite.sprite_frames.has_animation(animation):
		animation = sprite.sprite_frames.get_animation_names()[0]
	if sprite.animation != animation or not sprite.is_playing():
		sprite.play(animation)

func disable_collision() -> void:
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO

func freeze(value:bool) -> void:
	frozen_by_game = value
	sprite.speed_scale = 0.0 if value or impact_pause > 0.0 else 1.0
