class_name RaceSetup
extends RefCounted
enum Mode { QUICK_RACE, TIME_TRIAL }
var mode := Mode.QUICK_RACE
var opponents := 6
var difficulty := 2 # Preserve the saved development scene's Challenging default.
var laps := 3
var controller := -2 # -2 keyboard + any pad; -1 keyboard; >=0 assigned pad.
var circuit_id: StringName = &"reference"

func validated() -> RaceSetup:
	var result := RaceSetup.new()
	result.mode = Mode.TIME_TRIAL if mode == Mode.TIME_TRIAL else Mode.QUICK_RACE
	result.opponents = 0 if result.mode == Mode.TIME_TRIAL else clampi(opponents, 0, 6)
	result.difficulty = clampi(difficulty, 0, 2)
	result.laps = clampi(laps, 1, 20)
	result.controller = controller if controller >= -2 and controller < 16 else -2
	result.circuit_id = circuit_id if circuit_id in TrackRegistry.IDS else &"reference"
	return result

func items_enabled() -> bool:
	return mode == Mode.QUICK_RACE
