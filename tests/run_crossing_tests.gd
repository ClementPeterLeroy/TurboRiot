extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
func run() -> void:
	await preload("res://tests/crossing_collision_tests.gd").new().run(self)
	var expected := 16 if "--upper-only" in OS.get_cmdline_user_args() else 52
	if checks != expected:
		failures += 1
		push_error("Crossing suite did not complete: expected %d checks, got %d" % [expected,checks])
	print("Crossing regression: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
