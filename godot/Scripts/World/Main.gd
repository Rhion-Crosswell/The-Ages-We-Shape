extends Node2D

const PLAYER = preload("res://Scripts/Player/Player.gd")
const HUD = preload("res://Scripts/UI/HUD.gd")
const ART = preload("res://Scripts/World/ForegroundArt.gd")
const WAYSTONE = preload("res://Scripts/World/Waystone.gd")
const SATCHEL = preload("res://Scripts/World/Satchel.gd")
const PARALLAX_ART = preload("res://Scripts/World/ParallaxLayer.gd")
const QUEST_TARGET = preload("res://Scripts/Quests/QuestTarget.gd")
const QUEST_UI = preload("res://Scripts/UI/QuestUI.gd")
const ELEMENTAL_TARGET = preload("res://Scripts/World/ElementalTarget.gd")
const SYSTEMS_UI = preload("res://Scripts/UI/SystemsUI.gd")
const START_MENU = preload("res://Scripts/UI/StartMenu.gd")
const DIALOGUE_UI = preload("res://Scripts/World/AcademyDialogueUI.gd")
const MONUMENT = preload("res://Scripts/World/AcademyMonument.gd")
const RESOURCE_NODE = preload("res://Scripts/World/ResourceNode.gd")
const ACADEMY_PROP = preload("res://Scenes/World/Ingeniarii/AcademyProp.tscn")
const STONE_PLATFORM = preload("res://Scenes/World/Ingeniarii/StonePlatform.tscn")
const OPENING_CINEMATIC = preload("res://Scripts/World/AcademyOpeningCinematic.gd")
const UNDERGROUND_ART = preload("res://Scripts/World/UndergroundChamberArt.gd")
const ANCIENT_DEVICE_ART = preload("res://Scripts/World/AncientDeviceArt.gd")
const ACADEMY_GATE = preload("res://Scripts/World/AcademyGate.gd")
const ARTIFACT_CHAMBER = preload("res://Scenes/World/Ingeniarii/artifact_chamber.tscn")
const AREA_DOOR = preload("res://Scripts/World/AreaDoor.gd")

var world_tint: CanvasModulate
var grounds_root: Node2D
var chamber_root: Node2D
var player: CharacterBody2D
var underground_gate_shape: CollisionShape2D
var weather_fx: CPUParticles2D
var hidden_stairs: Node2D
var pulse_lights: Array[PointLight2D] = []
var cinematic: CanvasLayer
var academy_gate: Node2D
var courtyard_monument: Node2D
var pulse_time := 0.0
var normal_light_energy: Array[float] = []
var npc_targets: Dictionary = {}

func _ready() -> void:
	SaveManager.load_game()
	grounds_root = Node2D.new()
	grounds_root.name = "AcademyGrounds"
	add_child(grounds_root)
	var art := Node2D.new()
	art.name = "AcademyArchitecture"
	art.set_script(ART)
	art.z_index = -1
	grounds_root.add_child(art)
	WorldStateManager.state_changed.connect(func(key: String, value: Variant):
		art.queue_redraw()
		_on_world_state_changed(key, value))
	world_tint = CanvasModulate.new()
	world_tint.color = WorldClock.get_ambient_tint().lerp(Color(0.74,0.66,0.90),0.32)
	grounds_root.add_child(world_tint)
	for light_at in [Vector2(560,452),Vector2(1080,448),Vector2(1900,450),Vector2(2280,450),Vector2(3200,449),Vector2(4040,450),Vector2(4750,450),Vector2(5440,450)]:
		_add_warm_light(light_at)
	for light_at in [Vector2(910,430),Vector2(1450,414),Vector2(4400,400)]:
		_add_arcane_light(light_at)
	_add_ambient_motes()
	_build_parallax()
	_build_walkways()
	_build_academy_props()
	_build_underground_entrance()

	player = CharacterBody2D.new()
	player.name = "Player"
	player.set_script(PLAYER)
	player.position = Vector2(clampf(GameManager.player_position.x, 90.0, 5600.0), GameManager.player_position.y if GameManager.player_position.x <= 5600.0 else 520.0)
	if GameManager.checkpoint_position.x > 5750.0:
		GameManager.checkpoint_position = Vector2(120,520)
	add_child(player)
	var stone := Area2D.new()
	stone.name = "EntranceWaystone"
	stone.set_script(WAYSTONE)
	stone.position = Vector2(95,582)
	grounds_root.add_child(stone)

	# The first encounter greets the player; the first clue lies in the courtyard.
	_add_quest_target("professor_aldren", "Professor Aldren", "npc", Vector2(1690,571), Color(0.61,0.37,0.84))
	_add_quest_target("mira", "Mira", "npc", Vector2(1110,571), Color(0.78,0.52,0.84))
	_add_quest_target("darian", "Darian", "npc", Vector2(4210,571), Color(0.83,0.57,0.42))
	_add_quest_target("selene", "Selene", "npc", Vector2(5050,571), Color(0.52,0.68,0.86))
	_add_quest_target("damaged_lantern", "Damaged magical lantern", "clue", Vector2(4110,532), Color(0.92,0.65,0.37))
	_add_quest_target("ancient_markings", "Ancient pillar markings", "clue", Vector2(4720,490), Color(0.82,0.72,0.54))
	_add_quest_target("arcane_machine", "Malfunctioning arcane machine", "clue", Vector2(4410,535), Color(0.68,0.48,0.94))
	_add_quest_target("ancient_mechanism", "Sealed underground mechanism", "console", Vector2(5550,571), Color(0.70,0.44,0.96))
	_add_quest_target("hidden_collectible", "Observatory fragment", "clue", Vector2(3695,423), Color(0.84,0.72,0.41))
	_add_quest_target("signal_crystal", "Resonant crystal", "clue", Vector2(930,540), Color(0.58,0.72,1.0))
	_add_quest_target("thesis_page", "Loose thesis page", "clue", Vector2(1560,550), Color(0.81,0.66,0.44))
	_add_quest_target("archive_ledger", "Scraped ledger", "clue", Vector2(2130,548), Color(0.78,0.68,0.47))
	_add_quest_target("prism_lens", "Prism lens", "clue", Vector2(3220,436), Color(0.58,0.69,1.0))
	_add_quest_target("research_gate", "Sealed research entrance", "console", Vector2(5790,571), Color(0.67,0.43,0.88))
	_add_quest_target("archive_console", "Research console", "console", Vector2(5200,571), Color(0.67,0.43,0.88))
	_add_quest_target("scotia_dispatch", "Scotia field dispatch", "console", Vector2(5600,571), Color(0.55,0.76,0.48))
	for target_data in QuestManager.ACADEMY_CATALOG.TARGETS:
		var target_id := str(target_data.id)
		if npc_targets.has(target_id): continue
		var title := str(target_data.get("title", target_id.replace("_", " ").capitalize()))
		if NPCRelationshipManager.PROFILES.has(target_id): title = str(NPCRelationshipManager.PROFILES[target_id].name)
		var target_position := Vector2(float(target_data.x), float(target_data.y))
		if target_id == "master_vaelis": target_position = Vector2(5450,571)
		if target_id in ["vaelis_appointment", "vaelis_letter"]: target_position.x = 5400.0 if target_id == "vaelis_appointment" else 5520.0
		if target_position.x > 5860.0: continue
		_add_quest_target(target_id, title, str(target_data.kind), target_position, target_data.get("accent", Color(0.72,0.56,0.88)))
	NPCRelationshipManager.npc_location_changed.connect(_on_npc_location_changed)
	_sync_npc_schedules()

	for anchor in [{"id":"academy_crane","x":430.0,"y":300.0},{"id":"bridge_lantern","x":1240.0,"y":275.0},{"id":"archive_rig","x":2110.0,"y":290.0},{"id":"garden_vines","x":3370.0,"y":310.0},{"id":"sky_dock","x":4680.0,"y":270.0},{"id":"observatory","x":5550.0,"y":285.0}]:
		TraversalManager.register_anchor(anchor.id,Vector2(anchor.x,anchor.y),"mechanical" if anchor.id in ["academy_crane","archive_rig"] else "arcane")
	for target_data in [{"id":"lower_crystal","x":990.0,"y":545.0,"kind":"crystal","pair":"arcane+frost"},{"id":"steam_vent","x":1770.0,"y":545.0,"kind":"steam","pair":"fire+frost"},{"id":"garden_vines","x":2790.0,"y":545.0,"kind":"vines","pair":"arcane+nature"},{"id":"burning_roots","x":3670.0,"y":545.0,"kind":"vines","pair":"fire+nature"},{"id":"airship_relay","x":4920.0,"y":545.0,"kind":"machinery","pair":"machinery+storm"}]:
		var reactor := Node2D.new()
		reactor.set_script(ELEMENTAL_TARGET)
		reactor.target_id=target_data.id; reactor.target_kind=target_data.kind; reactor.required_pair=target_data.pair; reactor.position=Vector2(target_data.x,target_data.y); grounds_root.add_child(reactor)
	for node_data in [{"id":"vein_a","resource":"bronze","x":640.0},{"id":"herb_a","resource":"herb","x":1180.0},{"id":"crystal_a","resource":"crystal","x":1520.0},{"id":"gear_a","resource":"gear","x":2185.0},{"id":"herb_b","resource":"herb","x":3030.0},{"id":"crystal_b","resource":"crystal","x":3850.0},{"id":"bronze_b","resource":"bronze","x":4730.0},{"id":"herb_c","resource":"herb","x":5550.0}]:
		var resource_node:=Area2D.new(); resource_node.set_script(RESOURCE_NODE); resource_node.node_id=node_data.id; resource_node.resource_id=node_data.resource; resource_node.position=Vector2(node_data.x,550); grounds_root.add_child(resource_node)

	var hud := CanvasLayer.new()
	hud.set_script(HUD)
	add_child(hud)
	player.connect("resources_changed", Callable(hud, "set_resources"))
	var quest_ui := CanvasLayer.new()
	quest_ui.set_script(QUEST_UI)
	add_child(quest_ui)
	var dialogue_ui := CanvasLayer.new()
	dialogue_ui.set_script(DIALOGUE_UI)
	add_child(dialogue_ui)
	var systems_ui := CanvasLayer.new()
	systems_ui.set_script(SYSTEMS_UI)
	add_child(systems_ui)
	var start_menu := CanvasLayer.new()
	start_menu.set_script(START_MENU)
	add_child(start_menu)
	cinematic = CanvasLayer.new()
	cinematic.set_script(OPENING_CINEMATIC)
	add_child(cinematic)
	if GameManager.satchel_active:
		_spawn_satchel(GameManager.satchel_position)

func _build_parallax() -> void:
	var parallax_speeds := [0.12,0.36,0.68]
	for layer in range(3):
		var parallax := Parallax2D.new()
		parallax.scroll_scale = Vector2(parallax_speeds[layer],1)
		parallax.repeat_size = Vector2(1280,0)
		parallax.z_index = -5+layer
		grounds_root.add_child(parallax)
		var decor := Node2D.new()
		decor.set_script(PARALLAX_ART)
		decor.set("layer_index",layer)
		parallax.add_child(decor)

func _build_walkways() -> void:
	# The Academy Grounds end at a discoverable underground doorway. The chamber is a different scene.
	_add_ground(0,5860)
	_add_platform(2300,500,240)
	_add_platform(2625,470,190)
	_add_platform(2920,448,270)
	_add_platform(3325,470,260)
	_add_platform(3695,495,220)
	var boundary := StaticBody2D.new()
	boundary.name = "AcademyGroundsEastBoundary"
	boundary.position = Vector2(5850,480)
	boundary.collision_layer = 2
	var boundary_shape := CollisionShape2D.new()
	var boundary_rect := RectangleShape2D.new()
	boundary_rect.size = Vector2(28,210)
	boundary_shape.shape = boundary_rect
	boundary.add_child(boundary_shape)
	grounds_root.add_child(boundary)

func _build_academy_props() -> void:
	var root := "res://Assets/Environments/Ingeniarii/"
	# Entrance district: the extracted facade is scenery; the tiled street remains walkable collision.
	_add_prop(root+"Architecture/entrance_facade.png",Vector2(210,571),Vector2(1.0,1.0),-2,true)
	_add_prop(root+"Decorations/lantern_post.png",Vector2(520,571),Vector2(0.68,0.68),1,true)
	_add_prop(root+"Decorations/banner_large.png",Vector2(700,319),Vector2(0.88,0.88),1,false,true)
	_add_prop(root+"Decorations/crate_small.png",Vector2(540,571),Vector2(0.82,0.82),1,true)
	_add_prop(root+"Decorations/crate_large.png",Vector2(600,571),Vector2(0.66,0.66),1,true)
	_add_prop(root+"Decorations/barrel.png",Vector2(657,571),Vector2(0.72,0.72),1,true)
	_add_prop(root+"Decorations/cart.png",Vector2(758,571),Vector2(0.86,0.86),1,true)
	# Courtyard: warm lamps, a crystal fountain, flowers, and daily academy activity.
	_add_prop(root+"Decorations/lantern_post.png",Vector2(1090,571),Vector2(0.68,0.68),1,true)
	_add_prop(root+"Decorations/banner_large.png",Vector2(1230,306),Vector2(0.82,0.82),1,false,true)
	_add_prop(root+"Decorations/planter.png",Vector2(1375,571),Vector2(0.78,0.78),1,true)
	var fountain := Node2D.new(); fountain.name="CourtyardCrystalFountain"; fountain.set_script(MONUMENT); fountain.position=Vector2(1510,571); fountain.z_index=1; grounds_root.add_child(fountain)
	courtyard_monument = fountain
	_add_prop(root+"Decorations/shrub_gold.png",Vector2(850,571),Vector2(0.72,0.72),1,true)
	_add_prop(root+"Decorations/shrub_red.png",Vector2(1720,571),Vector2(0.72,0.72),1,true)
	_add_prop(root+"Backgrounds/statue.png",Vector2(1850,370),Vector2(0.62,0.62),-2)
	# The observatory walk: original stairs, bridge supports, and a deliberately small gap.
	_add_prop(root+"Platforms/staircase.png",Vector2(2130,571),Vector2(0.92,0.92),1,true)
	_add_prop(root+"Platforms/short_bridge.png",Vector2(2300,489),Vector2(1.7,1.7),-1,false,true)
	_add_prop(root+"Platforms/short_bridge.png",Vector2(2920,437),Vector2(1.8,1.8),-1,false,true)
	_add_prop(root+"Platforms/stone_column.png",Vector2(2780,571),Vector2(0.72,0.72),-1,true)
	_add_prop(root+"Platforms/stone_column.png",Vector2(3480,571),Vector2(0.72,0.72),-1,true)
	_add_prop(root+"Decorations/lantern_post.png",Vector2(3260,571),Vector2(0.68,0.68),1,true)
	_add_prop(root+"Decorations/banner_large.png",Vector2(3530,300),Vector2(0.76,0.76),1,false,true)
	_add_prop(root+"Decorations/shrub_gold.png",Vector2(2220,571),Vector2(0.64,0.64),1,true)
	_add_prop(root+"Decorations/shrub_red.png",Vector2(3850,571),Vector2(0.76,0.76),1,true)
	# Lower research entrance: dusk-dark masonry, a rune seal, and the faint answer below.
	_add_prop(root+"Backgrounds/ruined_arches.png",Vector2(4390,414),Vector2(1.95,1.75),-2)
	_add_prop(root+"Platforms/stone_column.png",Vector2(4140,571),Vector2(0.92,0.92),-1,true)
	_add_prop(root+"Platforms/stone_column.png",Vector2(4440,571),Vector2(0.92,0.92),-1,true)
	_add_prop(root+"Decorations/brazier.png",Vector2(4250,571),Vector2(0.72,0.72),1,true)
	_add_prop(root+"Decorations/banner_large.png",Vector2(4490,292),Vector2(0.84,0.84),1,false,true)
	_add_prop(root+"Decorations/house_sign.png",Vector2(4750,380),Vector2(0.92,0.92),1)
	_add_prop(root+"Decorations/lantern_post.png",Vector2(4860,571),Vector2(0.68,0.68),1,true)
	# A visible dispatch and small garden extend the safe walk toward the rest of Alterra.
	_add_prop(root+"Decorations/planter.png",Vector2(5160,571),Vector2(0.76,0.76),1,true)
	_add_prop(root+"Decorations/shrub_gold.png",Vector2(5500,571),Vector2(0.7,0.7),1,true)
	_add_prop(root+"Decorations/lantern_post.png",Vector2(5550,571),Vector2(0.68,0.68),1,true)
	hidden_stairs = _add_prop(root+"Platforms/staircase.png",Vector2(5680,571),Vector2(1.12,1.12),1,true)
	hidden_stairs.visible = WorldStateManager.has_event("ancient_staircase")

func _add_prop(path: String, at: Vector2, size: Vector2, z: int, bottom := false, top := false) -> Node2D:
	var prop := ACADEMY_PROP.instantiate() as Node2D
	prop.set("art_texture",load(path))
	prop.set("art_scale",size)
	prop.set("anchor_bottom",bottom)
	prop.set("anchor_top",top)
	prop.position=at
	prop.z_index=z
	grounds_root.add_child(prop)
	return prop

func _build_underground_entrance() -> void:
	academy_gate = Node2D.new()
	academy_gate.name = "UndergroundEntranceArch"
	academy_gate.position = Vector2(5705, 582)
	academy_gate.z_index = 2
	academy_gate.set_script(ACADEMY_GATE)
	grounds_root.add_child(academy_gate)
	var gate_body := StaticBody2D.new()
	gate_body.name = "UndergroundEntranceBarrier"
	gate_body.position = Vector2(5705,493)
	gate_body.collision_layer = 2
	gate_body.collision_mask = 0
	underground_gate_shape = CollisionShape2D.new()
	var gate_rect := RectangleShape2D.new()
	gate_rect.size = Vector2(58,178)
	underground_gate_shape.shape = gate_rect
	underground_gate_shape.disabled = WorldStateManager.has_event("ancient_staircase")
	gate_body.add_child(underground_gate_shape)
	grounds_root.add_child(gate_body)
	var door := Node2D.new()
	door.name = "ArtifactChamberDoor"
	door.set_script(AREA_DOOR)
	door.destination = "artifact_chamber"
	door.display_name = "Descend to the Artifact Chamber"
	door.position = Vector2(5705, 565)
	grounds_root.add_child(door)

func _on_world_state_changed(key: String, value: Variant) -> void:
	if key == "event.fountain" or key == "event.darian_machine" or key == "event.academy_history" or key.begins_with("event.edrin_case") or key.begins_with("event.vaelis"):
		if is_instance_valid(courtyard_monument): courtyard_monument.queue_redraw()
		get_tree().call_group("quest_targets", "queue_redraw")
	if key == "event.ancient_staircase" and str(value) == "Revealed":
		if is_instance_valid(hidden_stairs): hidden_stairs.visible = true
		if is_instance_valid(underground_gate_shape): underground_gate_shape.set_deferred("disabled", true)
		if is_instance_valid(academy_gate): academy_gate.queue_redraw()
	if key == "event.ancient_device_activated":
		if is_instance_valid(courtyard_monument): courtyard_monument.queue_redraw()
		get_tree().call_group("quest_targets", "queue_redraw")
		var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
		var camera: Camera2D = player.get_node_or_null("Camera2D") as Camera2D if is_instance_valid(player) else null
		if is_instance_valid(camera):
			var shake := create_tween()
			shake.tween_property(camera,"offset",Vector2(7,-5),0.09)
			shake.tween_property(camera,"offset",Vector2(-5,4),0.11)
			shake.tween_property(camera,"offset",Vector2(3,-2),0.10)
			shake.tween_property(camera,"offset",Vector2.ZERO,0.18)

func _process(_delta: float) -> void:
	if is_instance_valid(world_tint):
		var awakening_tint := 0.52 if WorldStateManager.has_event("ancient_device_activated") else 0.32
		world_tint.color=WorldClock.get_ambient_tint().lerp(Color(0.74,0.56,0.89),awakening_tint)
	if WorldStateManager.has_event("ancient_device_activated"):
		pulse_time += _delta
		for i in range(mini(pulse_lights.size(), normal_light_energy.size())):
			if is_instance_valid(pulse_lights[i]):
				pulse_lights[i].energy = normal_light_energy[i] * (0.74 + absf(sin(pulse_time * 3.0 + float(i) * 0.67)) * 0.33)
	if is_instance_valid(weather_fx):
		weather_fx.emitting=WorldClock.weather in ["Rain","Heavy Rain","Magical Storm","Snow","Blizzard"]
		weather_fx.amount=110 if WorldClock.weather in ["Heavy Rain","Blizzard","Magical Storm"] else 48
		weather_fx.gravity=Vector2(0,45) if WorldClock.weather in ["Snow","Blizzard"] else Vector2(0,800)
		weather_fx.direction=Vector2(-0.45,1) if WorldClock.weather in ["Rain","Heavy Rain","Blizzard","Magical Storm"] else Vector2(0.08,1)

func _add_warm_light(at: Vector2) -> void:
	_add_point_light(at,Color(1.0,0.68,0.34,0.72),0.62,1.9)

func _add_arcane_light(at: Vector2) -> void:
	_add_point_light(at,Color(0.60,0.40,1.0,0.58),0.76,2.15)

func _add_point_light(at: Vector2, tint: Color, power: float, scale_value: float) -> void:
	var gradient := Gradient.new()
	gradient.set_color(0,tint)
	gradient.set_color(1,Color(tint.r,tint.g,tint.b,0.0))
	var texture := GradientTexture2D.new()
	texture.gradient=gradient
	texture.width=128
	texture.height=128
	texture.fill=GradientTexture2D.FILL_RADIAL
	var lamp := PointLight2D.new()
	lamp.position=at
	lamp.texture=texture
	lamp.energy=power
	lamp.texture_scale=scale_value
	grounds_root.add_child(lamp)
	pulse_lights.append(lamp)
	normal_light_energy.append(power)

func _add_ambient_motes() -> void:
	for center in [Vector2(640,390),Vector2(2350,365),Vector2(4300,360)]:
		var motes := CPUParticles2D.new()
		motes.position=center
		motes.amount=24
		motes.lifetime=7.0
		motes.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		motes.emission_rect_extents=Vector2(760,260)
		motes.direction=Vector2(0.25,-0.55)
		motes.spread=40
		motes.initial_velocity_min=5
		motes.initial_velocity_max=22
		motes.gravity=Vector2(0,-3)
		motes.scale_amount_min=1.5
		motes.scale_amount_max=4
		motes.color=Color(0.73,0.61,1.0,0.42)
		grounds_root.add_child(motes)
	weather_fx=CPUParticles2D.new()
	weather_fx.position=Vector2(3000,-30)
	weather_fx.amount=48
	weather_fx.lifetime=2.4
	weather_fx.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	weather_fx.emission_rect_extents=Vector2(3000,40)
	weather_fx.direction=Vector2(-0.45,1)
	weather_fx.spread=8
	weather_fx.initial_velocity_min=260
	weather_fx.initial_velocity_max=420
	weather_fx.gravity=Vector2(0,800)
	weather_fx.scale_amount_min=0.7
	weather_fx.scale_amount_max=1.5
	weather_fx.color=Color(0.59,0.72,0.91,0.42)
	weather_fx.emitting=false
	grounds_root.add_child(weather_fx)

func _add_quest_target(id: String, title: String, kind: String, at: Vector2, accent: Color) -> void:
	var target := Area2D.new()
	target.name = id
	target.set_script(QUEST_TARGET)
	target.set("target_id",id)
	target.set("display_name",title)
	target.set("target_kind",kind)
	target.set("accent",accent)
	target.position=at
	grounds_root.add_child(target)
	if kind == "npc": npc_targets[id] = target

func _on_npc_location_changed(npc_id: String, _phase: String) -> void:
	if not npc_targets.has(npc_id): return
	var target: Node2D = npc_targets[npc_id]
	var position := NPCRelationshipManager.position_for(npc_id)
	target.position = position
	target.visible = position.x > -900

func _sync_npc_schedules() -> void:
	for npc_id in npc_targets: _on_npc_location_changed(str(npc_id), NPCRelationshipManager.schedule_phase)

func _add_ground(x: float,width: float) -> void:
	_add_platform(x,582,width,Color(0.13,0.11,0.16))

func _add_platform(x: float,y: float,width: float,_tint := Color(0.13,0.11,0.16)) -> void:
	var platform := STONE_PLATFORM.instantiate() as StaticBody2D
	platform.set("platform_width",width)
	platform.position=Vector2(x+width*0.5,y)
	grounds_root.add_child(platform)

func _spawn_satchel(pos: Vector2) -> void:
	var satchel := Area2D.new()
	satchel.set_script(SATCHEL)
	satchel.global_position=pos
	if is_instance_valid(chamber_root): chamber_root.add_child(satchel)
	else: grounds_root.add_child(satchel)

func enter_artifact_chamber() -> void:
	if not WorldStateManager.has_event("ancient_staircase"):
		GameManager.notify("The ancient mechanism has not opened the way below.")
		return
	if is_instance_valid(chamber_root): return
	GameManager.player_position = player.global_position
	grounds_root.get_parent().remove_child(grounds_root)
	chamber_root = ARTIFACT_CHAMBER.instantiate() as Node2D
	add_child(chamber_root)
	player.global_position = Vector2(130, 510)
	player.velocity = Vector2.ZERO
	_set_camera_limits(0, 2400)
	SaveManager.save_game()

func return_to_academy() -> void:
	if not is_instance_valid(chamber_root): return
	chamber_root.queue_free()
	chamber_root = null
	add_child(grounds_root)
	player.global_position = Vector2(5600, 510)
	player.velocity = Vector2.ZERO
	_set_camera_limits(0, 5860)
	GameManager.player_position = player.global_position
	SaveManager.save_game()

func _set_camera_limits(left: int, right: int) -> void:
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if is_instance_valid(camera):
		camera.limit_left = left
		camera.limit_right = right
		camera.reset_smoothing()
