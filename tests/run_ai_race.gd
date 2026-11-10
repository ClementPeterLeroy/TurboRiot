extends SceneTree
## Real physical AI-only race, no scripted transforms/gate injection.
## godot --headless --fixed-fps 60 --path . --script tests/run_ai_race.gd
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main := load("res://scenes/main.tscn").instantiate() as Node3D
	main.get_node("Items").enabled = "--items" in OS.get_cmdline_user_args()
	var race := main.get_node("RaceManager") as RaceManager
	var idle_human := "--idle-human" in OS.get_cmdline_user_args()
	race.ai_only = not idle_human
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--laps="): race.lap_count = clampi(argument.get_slice("=", 1).to_int(), 1, 20)
	root.add_child(main)
	race.start_race()
	var started := Time.get_ticks_usec()
	var brakes := 0
	var drifts := 0
	var mini := 0
	var last_report := 0
	var elapsed := 0.0
	while not race.race_complete and elapsed < race.race_timeout_seconds + 5:
		await physics_frame
		elapsed += 1.0 / Engine.physics_ticks_per_second
		for record in race.competitors:
			var input := record.kart.input_provider as AIInput
			if not input: continue
			if input.get_command().brake > 0: brakes += 1
			if record.kart.drift.active: drifts += 1
			if record.kart.boost.source == &"mini_turbo": mini += 1
		if int(elapsed) / 10 > last_report:
			last_report = int(elapsed) / 10
			var states: Array[String] = []
			for record in race.competitors:
				states.append("%s:L%d/G%d %.1fm/s R%d" % [record.display_name, record.session.lap_times.size(), record.session.next_checkpoint,
					record.kart.velocity.length(), record.recoveries])
			print("AI %.0fs " % elapsed, " | ".join(states))
	var item_world := main.get_node("Items") as ItemSystem
	var pickups := 0
	var uses := 0
	for record in race.competitors:
		pickups += record.kart.get_node("Inventory").collected
		uses += record.kart.get_node("Inventory").used
	print("ITEM RACE: enabled=%s pickups=%d uses=%d active=%d" % [item_world.enabled, pickups, uses, item_world.actors.size()])
	var failed := item_world.enabled and (pickups == 0 or uses == 0)
	for record in race.standings():
		print("RESULT %d %s laps=%d time=%.3f recoveries=%d dnf=%s" % [record.finish_order, record.display_name,
			record.session.lap_times.size(), record.session.final_time, record.recoveries, record.dnf])
		if idle_human and record.is_player:
			failed = failed or not record.dnf
		else:
			failed = failed or record.dnf or record.session.lap_times.size() != race.lap_count or record.finish_order == 0
	for record in race.competitors:
		var inventory := record.kart.get_node("Inventory") as KartInventory
		failed = failed or inventory.used > inventory.collected
	var wall_seconds := (Time.get_ticks_usec() - started) / 1000000.0
	print("AI RACE: racers=%d laps=%d brake_frames=%d drift_frames=%d mini_turbo_frames=%d simulation=%.1fs wall=%.2fs result=%s" % [
		race.competitors.size(), race.lap_count, brakes, drifts, mini, elapsed, wall_seconds, "FAIL" if failed else "PASS"])
	var results: Array[Dictionary] = []
	for record in race.standings():
		results.append({"order": record.finish_order, "name": record.display_name, "laps": record.session.lap_times,
			"time": record.session.final_time, "recoveries": record.recoveries, "dnf": record.dnf})
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var report := FileAccess.open("res://artifacts/v05_ai_race_%d_%d_%d_%s_%s.json" % [race.difficulty, race.competitors.size(), race.lap_count, "idle" if idle_human else "all_ai", "items" if item_world.enabled else "baseline"], FileAccess.WRITE)
	report.store_string(JSON.stringify({"difficulty": race.difficulty, "racers": race.competitors.size(), "laps": race.lap_count,
		"simulation_seconds": elapsed, "wall_seconds": wall_seconds, "items_enabled": item_world.enabled,
		"pickups": pickups, "item_uses": uses, "active_items": item_world.actors.size(), "brake_frames": brakes, "drift_frames": drifts,
		"mini_turbo_frames": mini, "passed": not failed, "results": results}, "\t"))
	report.close()
	main.queue_free()
	await process_frame
	quit(1 if failed else 0)
