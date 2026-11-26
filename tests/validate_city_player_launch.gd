extends SceneTree
## godot --path . --script tests/validate_city_player_launch.gd
## Omit --headless/--fixed-fps for native presentation verification.
var failures := 0
var checks := 0
func _initialize() -> void: run.call_deferred()
func check(value: bool, label: String) -> void:
	checks+=1
	if not value:
		failures+=1
		push_error(label)
func run() -> void:
	await preload("res://tests/city_square_launch_tests.gd").new().run(self)
	var report := {"checks":checks,"failures":failures,"passed":failures==0,"native_rendering":DisplayServer.get_name()!="headless","engine":Engine.get_version_info().string}
	FileAccess.open("res://artifacts/v061_city_player_launch.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("CITY_PLAYER_LAUNCH_RESULT ",JSON.stringify(report))
	quit(0 if failures==0 else 1)
