extends RefCounted
## Launch through the real application and human input path, not injected AI.
func run(s: SceneTree) -> void:
	var app := load("res://scenes/app.tscn").instantiate() as TurboApplication
	app.settings.path="res://.godot/city_launch_regression.cfg"
	app.auto_pause_on_focus_loss=false
	s.root.add_child(app)
	for mode in [RaceSetup.Mode.TIME_TRIAL,RaceSetup.Mode.QUICK_RACE]:
		var setup := RaceSetup.new()
		setup.mode=mode
		setup.circuit_id=&"delfino_square_ds"
		setup.controller=-2
		await app.start_session(setup,true)
		var race := app.game.get_node("RaceManager") as RaceManager
		var kart := race.kart
		var camera := app.game.get_node("ChaseCamera") as Camera3D
		var ground := race.track.get_node("Ground") as Node3D
		s.check(ground.transform.is_equal_approx(Transform3D.IDENTITY),"City authored meshes remain aligned with their curve and grid")
		var hit := race.track.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(kart.global_position+Vector3.UP*2,kart.global_position-Vector3.UP*3,1,[kart.get_rid()]))
		s.check(not hit.is_empty() and str(hit.collider.name)=="PavedStreetsCollision","City grid is above its real paved road in mode "+str(mode))
		var start := kart.global_position
		Input.action_press("accelerate")
		for i in 360:await s.physics_frame
		Input.action_release("accelerate")
		await s.process_frame
		s.check(race.phase==RaceSession.State.RACING and kart.driving_enabled,"City countdown enables human driving in mode "+str(mode))
		s.check(kart.global_position.distance_to(start)>30 and kart.velocity.length()>18 and kart.is_on_floor(),"City human acceleration follows the supported avenue in mode "+str(mode))
		var distance := camera.global_position.distance_to(kart.global_position)
		s.check(camera.current and camera.target==kart and distance>7 and distance<14,"City active chase camera follows without collapsing against misplaced scenery")
		var screen := camera.unproject_position(kart.global_position+Vector3.UP*.2)/Vector2(s.root.size)
		s.check(not camera.is_position_behind(kart.global_position) and absf(screen.x-.5)<.15 and screen.y>.2 and screen.y<.95,"City kart remains visibly framed by the chase camera")
		print("CITY_PLAYER_LAUNCH mode=",mode," speed=",kart.velocity.length()," camera_distance=",distance," screen=",screen)
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			s.root.get_texture().get_image().save_png("res://artifacts/v061_city_player_launch_%d.png"%mode)
		app.return_home()
		for i in 3:await s.process_frame
	app.queue_free()
	await s.process_frame
