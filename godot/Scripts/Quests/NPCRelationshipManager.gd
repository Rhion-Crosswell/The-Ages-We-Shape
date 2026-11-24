extends Node
## Stable NPC identity, memories, relationship states, and Academy schedules.
## Dialogue and quests query this service instead of storing NPC state in UI.
signal npc_updated(npc_id: String, state: Dictionary)
signal npc_location_changed(npc_id: String, location: String)
const SAVE_VERSION := 1
const PROFILES := {
	"professor_aldren":{"name":"Professor Aldren","personality":"Measured, conscientious, privately fearful of repeating an old mistake.","motivation":"Keep students safe while the Academy learns from its history.","schedule":{"Dawn":Vector2(1690,571),"Morning":Vector2(1690,571),"Afternoon":Vector2(1690,571),"Evening":Vector2(1690,571),"Night":Vector2(1690,571),"Late Night":Vector2(1690,571)}},
	"mira":{"name":"Mira","personality":"Direct, curious, and loyal to her friends.","motivation":"Keep fellow students safe without surrendering their choices.","schedule":{"Dawn":Vector2(1110,571),"Morning":Vector2(1110,571),"Afternoon":Vector2(1370,571),"Evening":Vector2(2580,571),"Night":Vector2(1110,571),"Late Night":Vector2(1110,571)}},
	"edrin":{"name":"Edrin","personality":"Inventive, guarded, and willing to take risks for practical improvements.","motivation":"Make safer magical conduits available to field researchers.","schedule":{"Dawn":Vector2(2580,571),"Morning":Vector2(2740,571),"Afternoon":Vector2(4250,571),"Evening":Vector2(2740,571),"Night":Vector2(2580,571),"Late Night":Vector2(2580,571)}},
	"darian":{"name":"Darian","personality":"Practical, dry-humored, and proud of repairable machinery.","motivation":"Prove magical machines can be maintained rather than merely admired.","schedule":{"Dawn":Vector2(4250,571),"Morning":Vector2(4250,571),"Afternoon":Vector2(4640,571),"Evening":Vector2(4420,571),"Night":Vector2(4250,571),"Late Night":Vector2(4250,571)}},
	"selene":{"name":"Selene","personality":"Patient, exacting, and protective of people erased from official records.","motivation":"Restore history without turning private pain into public spectacle.","schedule":{"Dawn":Vector2(5050,571),"Morning":Vector2(5050,571),"Afternoon":Vector2(5310,571),"Evening":Vector2(5000,571),"Night":Vector2(5050,571),"Late Night":Vector2(5050,571)}},
	"academy_spell_instructor":{"name":"Academy Spell Instructor","personality":"Demanding but attentive to different forms of mastery.","motivation":"Teach safe, intentional Arcane practice.","schedule":{"Dawn":Vector2(1370,571),"Morning":Vector2(1370,571),"Afternoon":Vector2(1810,571),"Evening":Vector2(1370,571),"Night":Vector2(1370,571),"Late Night":Vector2(1370,571)}},
	"fountain_caretaker":{"name":"Fountain Caretaker","personality":"Warm, observant, and respectful of inherited craft.","motivation":"Keep the courtyard waterworks useful and understood.","schedule":{"Dawn":Vector2(1930,571),"Morning":Vector2(1930,571),"Afternoon":Vector2(2200,571),"Evening":Vector2(1930,571),"Night":Vector2(1930,571),"Late Night":Vector2(1930,571)}},
	"academy_alchemist":{"name":"Academy Alchemist","personality":"Curious, precise, and willing to revise a formula when evidence supports it.","motivation":"Make practical alchemy safer and more adaptable.","schedule":{"Dawn":Vector2(3060,571),"Morning":Vector2(3060,571),"Afternoon":Vector2(3670,571),"Evening":Vector2(3060,571),"Night":Vector2(3060,571),"Late Night":Vector2(3060,571)}},
	"master_vaelis":{"name":"Master Vaelis","personality":"Diplomatic, restless, and careful about what he carries across borders.","motivation":"Deliver a warning about a discovery beyond Alterra.","schedule":{"Dawn":Vector2(5450,571),"Morning":Vector2(5450,571),"Afternoon":Vector2(5520,571),"Evening":Vector2(5450,571),"Night":Vector2(5450,571),"Late Night":Vector2(5450,571)}}
}
var states: Dictionary = {}
var schedule_phase := "Morning"

func _ready() -> void:
	for id in PROFILES: if not states.has(id): states[id] = _new_state()
	schedule_phase = WorldClock.phase
	WorldClock.phase_changed.connect(_on_phase_changed)

func _new_state() -> Dictionary:
	return {"relationship":"Unknown","trust":0,"affinity":0,"memories":[],"flags":{},"location_override":null}

func reset_progress() -> void:
	states.clear(); schedule_phase = "Morning"
	for id in PROFILES: states[id] = _new_state()

func remember(npc_id: String, memory_id: String, trust_delta: int = 0, affinity_delta: int = 0, flags: Dictionary = {}) -> bool:
	if not PROFILES.has(npc_id): return false
	if not states.has(npc_id): states[npc_id] = _new_state()
	var state: Dictionary = states[npc_id]
	for previous in state.memories:
		if str(previous.get("id", "")) == memory_id: return false
	state.memories.append({"id":memory_id,"time":Time.get_unix_time_from_system(),"trust":trust_delta,"affinity":affinity_delta})
	state.trust = clampi(int(state.trust) + trust_delta, -10, 10)
	state.affinity = clampi(int(state.affinity) + affinity_delta, -10, 10)
	for key in flags: state.flags[key] = flags[key]
	state.relationship = relationship_state(npc_id)
	npc_updated.emit(npc_id, state); SaveManager.save_game(); return true

func set_flag(npc_id: String, flag: String, value: Variant = true) -> void:
	if not states.has(npc_id): return
	states[npc_id].flags[flag] = value; npc_updated.emit(npc_id, states[npc_id]); SaveManager.save_game()

func has_flag(npc_id: String, flag: String) -> bool:
	return bool(states.get(npc_id, {}).get("flags", {}).get(flag, false))

func relationship_state(npc_id: String) -> String:
	var trust := int(states.get(npc_id, {}).get("trust", 0))
	if trust <= -6: return "Hostile"
	if trust <= -2: return "Strained"
	if trust >= 5: return "Trusted"
	if trust >= 2: return "Friendly"
	if not states.get(npc_id, {}).get("memories", []).is_empty(): return "Known"
	return "Unknown"

func has_memory(npc_id: String, memory_id: String) -> bool:
	for entry in states.get(npc_id, {}).get("memories", []):
		if str(entry.get("id", "")) == memory_id: return true
	return false

func position_for(npc_id: String) -> Vector2:
	var state: Dictionary = states.get(npc_id, {})
	var override: Variant = state.get("location_override")
	if override is Vector2: return override
	return PROFILES.get(npc_id, {}).get("schedule", {}).get(schedule_phase, Vector2.ZERO)

func set_location_override(npc_id: String, position: Variant) -> void:
	if not states.has(npc_id): return
	states[npc_id].location_override = position
	npc_location_changed.emit(npc_id, "override")

func _on_phase_changed(phase: String) -> void:
	schedule_phase = phase
	for npc_id in PROFILES: npc_location_changed.emit(npc_id, phase)

func save_data() -> Dictionary:
	var saved_states := states.duplicate(true)
	for id in saved_states:
		var override: Variant = saved_states[id].get("location_override")
		if override is Vector2: saved_states[id].location_override = [override.x, override.y]
	return {"version":SAVE_VERSION,"states":saved_states,"schedule_phase":schedule_phase}

func load_data(data: Dictionary) -> void:
	if int(data.get("version", 0)) > SAVE_VERSION: return
	for id in PROFILES:
		var saved: Dictionary = data.get("states", {}).get(id, _new_state())
		saved.merge(_new_state(), false); states[id] = saved
		var override: Variant = states[id].get("location_override")
		if override is Array and override.size() >= 2: states[id].location_override = Vector2(float(override[0]), float(override[1]))
	schedule_phase = str(data.get("schedule_phase", WorldClock.phase))
