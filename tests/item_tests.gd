extends RefCounted
class TestInput extends DrivingInput:
	var command := DrivingCommand.new()
	func get_command() -> DrivingCommand: return command

func run(s: SceneTree) -> void:
	_momentum(s)
	var main := load("res://scenes/main.tscn").instantiate() as Node3D
	var race := main.get_node("RaceManager") as RaceManager
	race.opponent_count = 1
	s.root.add_child(main)
	race.set_physics_process(false)
	race.start_race()
	race.session.advance(3)
	var world := main.get_node("Items") as ItemSystem
	var a := race.kart
	var b := race.competitors[1].kart
	for body in [a, b]:
		body.get_node("Recovery").set_physics_process(false)
		body.input_provider.set_physics_process(false)
		var input := TestInput.new()
		body.add_child(input)
		body.input_provider = input
	# Isolated flat fixture permits real hits/bounces without circuit turns.
	var floor_body := StaticBody3D.new()
	floor_body.position = Vector3(500, -0.5, 500)
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(150, 1, 150)
	floor_shape.shape = floor_box
	floor_body.add_child(floor_shape)
	main.add_child(floor_body)
	SurfaceDetector.tag_collision(floor_body, preload("res://resources/surfaces/asphalt.tres"))
	await s.physics_frame
	await s.physics_frame
	_rows(s, world)
	await _reachable_rows(s, world, a, b)
	await _inventory(s, world, a, b)
	await _pads(s, a)
	await _contacts(s, a, b, race)
	await _actors(s, world, a, b, main)
	# Cleanup is synchronous even though queued actor nodes leave at frame end.
	var inventory := a.get_node("Inventory") as KartInventory
	inventory.pickup(ItemCatalog.ITEMS[2])
	world.activate(a, inventory)
	a.receive_item_hit(Vector3.RIGHT * 4, 1, 0.8, 0.5, 0.8)
	race.restart_race()
	s.check(world.actors.is_empty() and not inventory.held and a.effects.remaining == 0, "Restart clears all actors, inventory and combat modifiers")
	s.check(world.rows[0].boxes[0].available, "Restart restores loot boxes")
	s.check(race.competitors[1].kart.get_node("Inventory").held == null, "Restart clears opponent inventory equally")
	s.check(race.session.next_checkpoint == 1 and race.session.lap_times.is_empty(), "Combat does not manufacture race progress")
	main.queue_free()
	await s.process_frame

func _reachable_rows(s: SceneTree, world: ItemSystem, a: KartController, b: KartController) -> void:
	_place(b, Vector3(530, 0.5, 530))
	for row in world.rows:
		for box in row.boxes:
			box.reset_box()
			_place(a, box.global_position - Vector3.UP * 0.6)
			for i in 5: await s.physics_frame
			s.check(a.get_node("Inventory").held != null and not box.available, "Real Area pickup reaches every source-track box: " + str(row.name) + "/" + str(box.name))
	world.reset_items()

func _momentum(s: SceneTree) -> void:
	for normal in [Vector3.RIGHT, Vector3.BACK, Vector3(1, 0, 1).normalized()]:
		for masses in [Vector2(100, 100), Vector2(70, 160)]:
			var a: Vector3 = -normal * 18 + normal.cross(Vector3.UP) * 16
			var b: Vector3 = normal * 4 + normal.cross(Vector3.UP) * 16
			var result := KartContactSolver.exchange(a, b, normal, masses.x, masses.y)
			s.check((result[0] * masses.x + result[1] * masses.y).distance_to(a * masses.x + b * masses.y) < 0.001, "Contact conserves mass-weighted planar momentum")
			s.check(result[0].length_squared() * masses.x + result[1].length_squared() * masses.y <= a.length_squared() * masses.x + b.length_squared() * masses.y + 0.01, "Contact cannot create kinetic energy")
			s.near(result[0].dot(normal.cross(Vector3.UP)), 16, "Side contact preserves tangential forward speed")
	var rear := KartContactSolver.exchange(Vector3(0, 0, -20), Vector3(0, 0, -10), Vector3.BACK, 100, 100)
	s.check(rear[0].z < -10 and rear[1].z < -10, "Rear-end impact transfers forward momentum without stopping either kart")
	var head := KartContactSolver.exchange(Vector3(0, 0, -20), Vector3(0, 0, 20), Vector3.BACK, 100, 100)
	s.check(head[0].distance_to(Vector3(0, 0, -20)) > rear[0].distance_to(Vector3(0, 0, -20)), "Head-on relative impact is stronger than a rear-end impact")
	var separating := KartContactSolver.exchange(Vector3.RIGHT * 5, Vector3.ZERO, Vector3.RIGHT, 100, 100)
	s.check(separating[0] == Vector3.RIGHT * 5 and separating[1] == Vector3.ZERO, "Separating contacts never generate repeated impulses")
	var resting := KartContactSolver.exchange(Vector3.FORWARD * 20, Vector3.FORWARD * 20, Vector3.RIGHT, 100, 100)
	s.check(resting[0] == resting[1] and resting[0].length() == 20, "Parallel rubbing does not farm energy or lose forward speed")

func _rows(s: SceneTree, world: ItemSystem) -> void:
	s.check(world.rows.size() == 3, "Exactly three configured blue-marker loot rows")
	var count := 0
	for row in world.rows:
		s.check(row.boxes.size() == 4, "Each loot row contains four boxes")
		for index in row.boxes.size():
			var box := row.boxes[index]
			count += 1
			s.check(absf(box.position.x) + 0.825 < world.track.road_width / 2, "Pickup volume lies inside usable asphalt")
			if index > 0: s.near(box.position.distance_to(row.boxes[index - 1].position), 3.2, "Loot spacing is even")
		s.check(absf(row.global_basis.x.dot(world.track.sample_forward(row.track_offset))) < 0.001, "Loot row spans perpendicular to road tangent")
	s.check(count == 12, "Exactly twelve configured boxes")
	s.check(ItemCatalog.ITEMS.size() == 4, "Only four active item definitions")
	var ids := {}
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 1000: ids[ItemCatalog.choose(rng).identifier] = true
	s.check(ids.size() == 4 and not ids.has(ItemCatalog.RESERVED), "Weighted pool includes 5A–5D and never reserved 5E")
	for item: ItemDefinition in ItemCatalog.ITEMS:
		s.check(item.model != null and item.icon != null and item.weight > 0, "Each item has replaceable model, icon and positive weight: " + item.display_name)
		var model := item.model.instantiate() as Node3D
		world.add_child(model)
		var bounded := true
		for child in model.get_children():
			if child is MeshInstance3D:
				bounded = bounded and child.position.length() < 1.5 and child.scale.length() < 3
		s.check(bounded and model.get_child_count() > 8, "Item details retain local transforms and a bounded recognizable model")
		model.queue_free()

func _place(body: KartController, at: Vector3) -> void:
	body.safe_spawn = Transform3D(Basis.IDENTITY, at)
	body.reset_to_spawn()
	body.driving_enabled = true
	(body.input_provider as TestInput).command = DrivingCommand.new()

func _inventory(s: SceneTree, world: ItemSystem, a: KartController, b: KartController) -> void:
	_place(a, Vector3(500, 0.5, 500))
	_place(b, Vector3(520, 0.5, 500))
	var inventory := a.get_node("Inventory") as KartInventory
	s.check(inventory.pickup(ItemCatalog.ITEMS[0]), "Empty player inventory accepts an item")
	s.check(not inventory.pickup(ItemCatalog.ITEMS[1]) and inventory.held == ItemCatalog.ITEMS[0], "Full inventory rejects replacement")
	s.check(not inventory.request(true, 0.1), "Held startup button cannot consume pickup")
	inventory.request(false, 0.1)
	s.check(inventory.request(true, 0.1), "New item press is recognized")
	s.check(not inventory.request(true, 0.1), "Held item press cannot retrigger")
	s.check(world.activate(a, inventory) and not inventory.held, "Mushroom activation consumes inventory")
	s.check(a.boost.source == &"mushroom" and is_equal_approx(a.boost.remaining, 1.8), "Mushroom has distinct source and 1.8-second timer")
	s.check(a.boost.direction_remaining == 0, "Mushroom does not lock movement direction")
	a.activate_directional_boost(Vector3.FORWARD, 1.5, 1.4)
	a.activate_item_boost(&"mushroom", 1.4, 1.8)
	s.near(a.boost.strength, 1.5, "Mushroom and pad use strongest cap, never additive stacking")
	a.boost.advance(2)
	s.check(not a.boost.active(), "Mushroom and pad bonuses expire")
	var box := world.rows[0].boxes[0]
	box.reset_box()
	s.check(box.try_collect(a) and not box.available, "Eligible pickup atomically disappears")
	s.check(not box.try_collect(b) and b.get_node("Inventory").held == null, "One box cannot grant two simultaneous pickups")
	box.remaining = 0.01
	await s.physics_frame
	await s.physics_frame
	s.check(box.available, "Loot box respawns after its timer")
	s.check(not box.try_collect(a) and box.available, "Full inventory leaves respawned box available")
	a.reset_to_spawn()
	s.check(not inventory.held and a.effects.remaining == 0, "Recovery clears held item and combat modifiers")
	s.check(not inventory.request(true, 0.1), "Recovery preserves press-until-release protection")
	box.reset_box()
	s.check(box.try_collect(b), "Opponent uses exactly the same pickup and inventory API")
	b.get_node("Inventory").clear()

func _pads(s: SceneTree, a: KartController) -> void:
	_place(a, Vector3(500, 0.5, 500))
	for i in 20: await s.physics_frame
	a.velocity = Vector3.BACK * 7
	var yaw := a.rotation.y
	a.activate_directional_boost(Vector3.FORWARD, 1.5, 1.4)
	s.check(a.velocity.z < -5 and a.rotation.y == yaw, "Reverse pad entry changes initial velocity without forcibly turning body")
	s.check(a.boost.direction == Vector3.ZERO and a.boost.direction_remaining == 0, "Pad leaves no persistent directional override")
	var provider := a.input_provider as TestInput
	provider.command = DrivingCommand.new(0, 1, 0.6)
	var speed := a.velocity.length()
	for i in 5: await s.physics_frame
	s.check(a.rotation.y != yaw and a.velocity.length() < speed, "Pad permits immediate ordinary braking and steering")
	provider.command = DrivingCommand.new(1, 0, 0.7, true)
	a.velocity = Vector3.FORWARD * 18 + Vector3.RIGHT * 2
	for i in 3: await s.physics_frame
	s.check(a.drift.active, "Pad permits ordinary drift without a redirect phase")
	provider.command = DrivingCommand.new()
	for i in 100: await s.physics_frame
	s.check(not a.boost.active(), "Pad bonus expires without directional residue")

func _contacts(s: SceneTree, a: KartController, b: KartController, race: RaceManager) -> void:
	_place(a, Vector3(500, 0.5, 510))
	_place(b, Vector3(500, 0.5, 506))
	for i in 20: await s.physics_frame
	a.velocity = Vector3.FORWARD * 20
	b.velocity = Vector3.FORWARD * 8
	var saw_contact := false
	var transferred := false
	var maximum_pairs := 0
	for i in 30:
		await s.physics_frame
		var solver := race.get_node("KartContacts") as KartContactSolver
		maximum_pairs = maxi(maximum_pairs, solver.pairs_resolved)
		if solver.pairs_resolved > 0:
			saw_contact = true
			transferred = transferred or (b.velocity.z < -8 and a.velocity.z < -5)
	s.check(saw_contact and transferred, "Real moving CharacterBodies exchange rear-end momentum and keep moving")
	s.check(maximum_pairs == 1, "Reciprocal slide contacts resolve one unordered pair per tick")
	s.check(a.position.distance_to(b.position) > 1.9, "Momentum exchange preserves physical nonpenetration")

func _spawn(world: ItemSystem, index: int, owner: KartController, at: Vector3, direction := Vector3.FORWARD) -> ItemActor:
	var actor := ItemActor.new()
	actor.system = world
	actor.source = owner
	actor.definition = ItemCatalog.ITEMS[index]
	actor.direction = direction
	world.add_child(actor)
	actor.global_position = at
	world.actors.append(actor)
	actor.reset_physics_interpolation()
	return actor

func _actors(s: SceneTree, world: ItemSystem, a: KartController, b: KartController, main: Node3D) -> void:
	_place(a, Vector3(500, 0.5, 510))
	_place(b, Vector3(500, 0.5, 498))
	for i in 20: await s.physics_frame
	s.check(world.target_ahead(a, 40) == b and world.target_ahead(b, 40) == null, "Red-shell acquisition selects eligible ahead opponents, excludes owner and behind")
	var red := _spawn(world, 1, a, Vector3(500, 0.3, 507))
	red.target = b
	var hit := false
	for i in 35:
		await s.physics_frame
		hit = hit or b.effects.remaining > 0
	s.check(hit and not is_instance_valid(red), "Real red shell sweeps into target and applies one timed hit")
	s.check(b.velocity.length() > 0.1, "Shell hit is a controlled disturbance rather than an enforced full stop")
	s.check(not b.receive_item_hit(Vector3.RIGHT * 8, 1, 0.7, 0.5, 0.5), "Brief immunity prevents rapid repeated hit stacking")
	for i in 65: await s.physics_frame
	s.check(b.effects.remaining == 0 and b.effects.grip_multiplier == 1, "Hit effect expires and restores normal handling")
	_place(b, Vector3(505, 0.5, 499))
	red = _spawn(world, 1, a, Vector3(500, 0.3, 507))
	red.target = b
	var before := red.direction
	await s.physics_frame
	await s.physics_frame
	s.check(before.angle_to(red.direction) > 0 and before.angle_to(red.direction) <= deg_to_rad(red.definition.turn_degrees) / 60 * 3 + 0.001, "Red homing turn rate is bounded per physics tick")
	red.expire()
	red = _spawn(world, 1, a, Vector3(510, 0.3, 507))
	before = red.direction
	for i in 4: await s.physics_frame
	s.check(red.direction.is_equal_approx(before), "Red shell without eligible target keeps forward fallback")
	red.expire()
	var green := _spawn(world, 2, a, Vector3(510, 0.3, 507))
	green.target = b # Even an assigned target must have no steering effect.
	for i in 5: await s.physics_frame
	s.check(green.direction == Vector3.FORWARD and absf(green.position.x - 510) < 0.001, "Green shell travels straight without homing")
	green.expire()
	# Thin wall sweep: shell travels 0.5 m/tick, wall is only 0.04 m thick.
	var wall := StaticBody3D.new()
	wall.position = Vector3(510, 1, 500)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(8, 2, 0.04)
	collision.shape = shape
	wall.add_child(collision)
	main.add_child(wall)
	await s.physics_frame
	green = _spawn(world, 2, a, Vector3(510, 0.3, 502))
	for i in 8: await s.physics_frame
	s.check(is_instance_valid(green) and green.bounces == 1 and green.direction.z > 0, "Green shell reflects from thin world wall without tunnelling")
	if is_instance_valid(green):
		green.bounces = green.definition.maximum_bounces
		green.direction = Vector3.FORWARD
		green.global_position = Vector3(510, 0.3, 501)
	for i in 5: await s.physics_frame
	s.check(not is_instance_valid(green), "Green shell expires after bounded bounce count")
	shape.size = Vector3(8, 0.45, 0.04)
	wall.position.y = 0.225
	for i in 2: await s.physics_frame
	green = _spawn(world, 2, a, Vector3(510, 0.6, 500))
	for i in 3: await s.physics_frame
	s.check(not is_instance_valid(green), "Shell ground-follow cannot lift a projectile onto an untagged low wall")
	wall.queue_free()
	_place(a, Vector3(500, 0.5, 510))
	var banana := _spawn(world, 3, a, Vector3(500, 0.8, 510))
	for i in 25: await s.physics_frame
	s.check(is_instance_valid(banana) and banana.settled and a.effects.remaining == 0, "Banana settles and owner has deployment grace")
	if is_instance_valid(banana): banana.age = 1.1
	for i in 3: await s.physics_frame
	s.check(a.effects.remaining > 0 and a.effects.grip_multiplier < 0.5, "Banana causes a temporary slip after owner grace ends")
	s.check(not is_instance_valid(banana), "Banana is consumed by exactly one hit")
	a.reset_to_spawn()
	s.check(a.effects.remaining == 0 and a.effects.immunity_remaining == 0, "Recovery clears active hit and immunity state")
	# A close-range projectile must test its initial overlap, while excluding
	# its owner during grace. This is separate from forward cast_motion.
	_place(b, Vector3(500, 0.5, 498))
	for i in 15: await s.physics_frame
	var close := _spawn(world, 2, a, b.global_position)
	for i in 3: await s.physics_frame
	s.check(not is_instance_valid(close) and b.effects.remaining > 0, "Initial projectile overlap hits opponents instead of tunnelling")
	_place(a, Vector3(500, 0.5, 510))
	close = _spawn(world, 2, a, a.global_position)
	for i in 3: await s.physics_frame
	s.check(is_instance_valid(close) and a.effects.remaining == 0, "Fresh shell excludes its owner even when initial shapes overlap")
	if is_instance_valid(close): close.expire()
	a.velocity = Vector3.FORWARD * 20
	(a.input_provider as TestInput).command = DrivingCommand.new(1, 0, 0.5)
	var yaw := a.rotation.y
	a.receive_item_hit(Vector3.RIGHT * 5, 0.8, 0.78, 0.7, 0.75)
	for i in 3: await s.physics_frame
	s.check(a.velocity.length() > 10 and a.rotation.y != yaw, "A moving hit preserves forward motion and steering input")
	a.reset_to_spawn()
	var shell := _spawn(world, 2, a, Vector3(520, 0.3, 520))
	shell.age = shell.definition.lifetime - 0.001
	for i in 3: await s.physics_frame
	s.check(not is_instance_valid(shell), "Unused projectile lifetime bounds active-object accumulation")
	world.maximum_actors = 1
	world.reset_items()
	var inventory := a.get_node("Inventory") as KartInventory
	inventory.pickup(ItemCatalog.ITEMS[2])
	s.check(world.activate(a, inventory), "Available actor slot accepts shell")
	inventory.pickup(ItemCatalog.ITEMS[2])
	s.check(not world.activate(a, inventory) and inventory.held != null, "Actor cap preserves held item instead of silently consuming it")
	world.maximum_actors = 32
	world.reset_items()
