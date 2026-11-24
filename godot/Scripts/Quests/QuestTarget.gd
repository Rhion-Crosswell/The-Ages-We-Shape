extends Area2D
@export var target_id := ""
@export var display_name := ""
@export_enum("npc", "clue", "console") var target_kind := "npc"
@export var accent := Color(0.75, 0.53, 0.92)
var player_nearby := false
const NPC_TEXTURES := {
	"professor_aldren": "res://Assets/Characters/NPCs/professor_aldren.png",
	"mira": "res://Assets/Characters/NPCs/mira.png",
	"darian": "res://Assets/Characters/NPCs/darian.png",
	"selene": "res://Assets/Characters/NPCs/selene.png",
	"academy_spell_instructor": "res://Assets/Characters/NPCs/spell_instructor.png",
	"fountain_caretaker": "res://Assets/Characters/NPCs/fountain_caretaker.png",
	"academy_alchemist": "res://Assets/Characters/NPCs/academy_alchemist.png",
	"master_vaelis": "res://Assets/Characters/NPCs/master_vaelis.png"
}
static var _npc_texture_cache: Dictionary = {}

func _ready() -> void:
	add_to_group("interactables")
	add_to_group("quest_targets")
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	# Keep the visible prompt, Area2D enter signal, and Player interaction range aligned.
	shape.radius = 88.0 if target_kind == "npc" else 104.0
	collision.shape = shape
	collision.name = "InteractionRange"
	add_child(collision)
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if target_kind == "npc":
		_add_npc_character()

func _add_npc_character() -> void:
	if NPC_TEXTURES.has(target_id):
		var portrait := Sprite2D.new()
		portrait.name = "NPCArtwork"
		portrait.texture = _load_npc_texture(target_id)
		portrait.position = Vector2(0, -64)
		portrait.scale = Vector2.ONE * 0.25
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		portrait.z_index = 2
		add_child(portrait)
	# A small feet-level blocker keeps physical collision separate from artwork
	# and from the wider player-facing interaction range.
	var body := StaticBody2D.new()
	body.name = "NPCBodyCollision"
	body.position = Vector2(0, -12)
	body.collision_layer = 4
	body.collision_mask = 0
	var body_shape := CollisionShape2D.new()
	body_shape.name = "CollisionShape2D"
	var footprint := RectangleShape2D.new()
	footprint.size = Vector2(22, 24)
	body_shape.shape = footprint
	body.add_child(body_shape)
	add_child(body)

static func _load_npc_texture(npc_id: String) -> Texture2D:
	if _npc_texture_cache.has(npc_id):
		return _npc_texture_cache[npc_id] as Texture2D
	var image := Image.load_from_file(str(NPC_TEXTURES.get(npc_id, "")))
	if image == null or image.is_empty():
		push_error("Could not load NPC artwork for %s" % npc_id)
		return null
	var texture := ImageTexture.create_from_image(image)
	_npc_texture_cache[npc_id] = texture
	return texture

func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var in_range := is_instance_valid(player) and global_position.distance_to(player.global_position) <= 88.0
	if in_range != player_nearby:
		player_nearby = in_range
		queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		queue_redraw()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		queue_redraw()

func _draw() -> void:
	if target_kind == "npc":
		pass
	elif target_kind == "clue":
		if target_id == "damaged_lantern":
			draw_line(Vector2(0,16),Vector2(0,-33),Color(0.58,0.38,0.25),4)
			draw_rect(Rect2(-12,-41,24,26),Color(0.24,0.17,0.25))
			draw_arc(Vector2(0,-28),16,PI,TAU,24,Color(0.84,0.61,0.37),3)
			draw_circle(Vector2(0,-29),6,Color(0.93,0.47,1.0,0.88))
			draw_line(Vector2(-6,-36),Vector2(4,-23),Color(0.96,0.83,1.0),2)
		elif target_id == "ancient_markings":
			draw_rect(Rect2(-17,-48,34,50),Color(0.25,0.20,0.21))
			draw_rect(Rect2(-21,-51,42,8),Color(0.63,0.44,0.34))
			for offset in [-7.0,0.0,7.0]: draw_line(Vector2(offset,-41),Vector2(offset+4,-19),Color(0.92,0.66,0.43),2)
		elif target_id == "arcane_machine":
			draw_rect(Rect2(-25,-35,50,38),Color(0.22,0.17,0.26))
			draw_rect(Rect2(-30,-41,60,9),Color(0.68,0.47,0.35))
			draw_arc(Vector2(0,-20),14,0,TAU,32,Color(0.73,0.46,0.99),3)
			draw_circle(Vector2(0,-20),5,Color(0.81,0.61,1.0))
		elif target_id == "dormant_device":
			draw_rect(Rect2(-27,-22,54,24),Color(0.20,0.16,0.23))
			draw_arc(Vector2(0,-37),23,0,TAU,32,Color(0.72,0.48,0.96,0.86),3)
			draw_colored_polygon(PackedVector2Array([Vector2(0,-54),Vector2(11,-38),Vector2(0,-23),Vector2(-11,-38)]),accent)
		else:
			draw_circle(Vector2.ZERO,25,Color(accent,0.16))
			draw_colored_polygon(PackedVector2Array([Vector2(0,-27),Vector2(14,-5),Vector2(11,17),Vector2(-11,17),Vector2(-14,-5)]),accent)
			draw_colored_polygon(PackedVector2Array([Vector2(0,-27),Vector2(0,16),Vector2(11,17),Vector2(14,-5)]),Color(0.9,0.94,1.0,0.52))
		draw_arc(Vector2.ZERO,28,0,TAU,32,Color(0.91,0.71,0.43),2)
	else:
		draw_rect(Rect2(-24,-29,48,37),Color(0.17,0.15,0.21))
		draw_rect(Rect2(-19,-24,38,27),Color(0.27,0.22,0.34))
		draw_rect(Rect2(-24,-31,48,5),Color(0.81,0.59,0.35))
		draw_arc(Vector2(0,-13),10,0,TAU,24,accent,2)
		draw_circle(Vector2.ZERO,3,Color(0.84,0.74,1.0))
	if player_nearby:
		var label_y := -142 if target_kind == "npc" else -45
		draw_string(ThemeDB.fallback_font,Vector2(-65,label_y),"F   " + display_name,HORIZONTAL_ALIGNMENT_LEFT,190,11,Color(0.98,0.84,0.58))
