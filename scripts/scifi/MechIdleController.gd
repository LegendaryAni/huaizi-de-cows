extends Node2D
## Original independently layered 1103 menu rig. Pure UI animation, never gameplay physics.

const BASE := "res://assets/sprites/ui/runtime/scifi/v3_mech_layers/"
const DRAW_ORDER := ["backpack","legs","torso","left_arm","right_arm","weapon","head","effects"]
const PIVOTS := {
	"backpack": Vector2(590,540), "legs": Vector2(590,915),
	"torso": Vector2(593,715), "left_arm": Vector2(405,424),
	"right_arm": Vector2(811,420), "weapon": Vector2(915,505),
	"head": Vector2(592,349), "effects": Vector2(590,540)
}
var motion_enabled := true
var phase := 0.0
var pieces: Dictionary = {}
var frame_cost_micros := 0

func _ready() -> void:
	_build_rig()
	set_process(motion_enabled)

func _build_rig() -> void:
	for name in DRAW_ORDER:
		var sprite := Sprite2D.new()
		sprite.name = {"left_arm":"LeftArm","right_arm":"RightArm"}.get(name,name.capitalize())
		sprite.texture = load(BASE + name + ".png")
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.centered = false
		sprite.position = PIVOTS[name]
		sprite.offset = -PIVOTS[name]
		# Scene-tree child order controls rig overlap; do not render above main UI.
		add_child(sprite)
		pieces[name] = sprite

func set_reduced_motion(reduced: bool) -> void:
	motion_enabled = not reduced
	set_process(motion_enabled)
	if not motion_enabled:
		for name in pieces:
			var sprite: Sprite2D = pieces[name]
			sprite.rotation = 0.0
			sprite.position = PIVOTS[name]
			sprite.modulate = Color.WHITE
		if pieces.has("effects"):
			pieces["effects"].modulate.a = 0.72

func _process(delta: float) -> void:
	var begun: int = Time.get_ticks_usec()
	phase += clampf(delta,0.0,0.05)
	var breathing: float = sin(phase * TAU / 3.4)
	# Decoupled pivots: head, each arm and shoulder body have independent transforms.
	var torso: Sprite2D = pieces["torso"]
	torso.position = PIVOTS["torso"] + Vector2(0.0,-3.0 - 2.0*breathing)
	torso.rotation = deg_to_rad(0.18 * breathing)
	var head: Sprite2D = pieces["head"]
	head.rotation = deg_to_rad(1.35*sin(phase*TAU/8.9))
	head.position = PIVOTS["head"] + Vector2(0,-1.3*breathing)
	var left: Sprite2D = pieces["left_arm"]
	left.rotation = deg_to_rad(1.20*sin(phase*TAU/6.5+0.4))
	var right: Sprite2D = pieces["right_arm"]
	right.rotation = deg_to_rad(-1.1*sin(phase*TAU/7.1+1.2))
	var weapon: Sprite2D = pieces["weapon"]
	weapon.rotation = deg_to_rad(0.55*sin(phase*TAU/7.1+1.2))
	var glow: Sprite2D = pieces["effects"]
	glow.modulate.a = 0.48 + 0.20 * (0.5 + 0.5*sin(phase*TAU/4.8))
	frame_cost_micros = Time.get_ticks_usec() - begun

func motion_snapshot() -> Dictionary:
	return {
		"head_deg": rad_to_deg(float(pieces["head"].rotation)),
		"left_arm_deg": rad_to_deg(float(pieces["left_arm"].rotation)),
		"right_arm_deg": rad_to_deg(float(pieces["right_arm"].rotation)),
		"torso_y": float(pieces["torso"].position.y),
		"motion_enabled": motion_enabled,
		"controller_micros": frame_cost_micros
	}
