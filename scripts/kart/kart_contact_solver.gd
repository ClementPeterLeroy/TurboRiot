class_name KartContactSolver
extends Node
## Resolve each actual contacting pair once after all CharacterBody movement.
signal impact(position: Vector3, strength: float)
var karts: Array[KartController] = []
var pairs_resolved := 0

func _ready() -> void:
	process_physics_priority = 5

static func exchange(a: Vector3, b: Vector3, normal: Vector3, mass_a: float, mass_b: float,
		restitution: float = 0.1, maximum_delta: float = 18.0) -> Array[Vector3]:
	normal.y = 0
	if normal.length_squared() < 0.001: return [a, b]
	normal = normal.normalized()
	var closing := -(a - b).dot(normal)
	if closing <= 0: return [a, b] # Resting/separating contacts never add energy.
	mass_a = maxf(1, mass_a)
	mass_b = maxf(1, mass_b)
	var impulse := (1 + clampf(restitution, 0, 0.5)) * closing / (1 / mass_a + 1 / mass_b)
	impulse = minf(impulse, maximum_delta * minf(mass_a, mass_b))
	return [a + normal * impulse / mass_a, b - normal * impulse / mass_b]

func _physics_process(_delta: float) -> void:
	var pairs := {}
	var velocities := {}
	var frame := Engine.get_physics_frames()
	pairs_resolved = 0
	for kart in karts:
		if not kart.driving_enabled or kart.contact_frame != frame: continue
		for contact in kart.kart_contacts:
			var other := contact.other as KartController
			if not is_instance_valid(other) or not other.driving_enabled: continue
			var a := kart.get_instance_id()
			var b := other.get_instance_id()
			var key := "%d:%d" % [mini(a, b), maxi(a, b)]
			if pairs.has(key): continue
			pairs[key] = true
			if not velocities.has(kart): velocities[kart] = kart.contact_velocity if kart.contact_frame == frame else kart.velocity
			if not velocities.has(other): velocities[other] = other.contact_velocity if other.contact_frame == frame else other.velocity
			var va: Vector3 = velocities[kart]
			var vb: Vector3 = velocities[other]
			var normal: Vector3 = contact.normal
			normal.y = 0
			var closing := maxf(0, -(va - vb).dot(normal.normalized()))
			var result := exchange(va, vb, normal, kart.config.impact_mass, other.config.impact_mass,
				minf(kart.config.impact_restitution, other.config.impact_restitution), minf(kart.config.impact_max_delta, other.config.impact_max_delta))
			velocities[kart] = result[0]
			velocities[other] = result[1]
			pairs_resolved += 1
			if closing > 2: impact.emit(contact.position, closing)
	for kart: KartController in velocities:
		# Preserve the engine's floor/ceiling resolution and actual wall response.
		# Restore only the planar pre-contact motion, with the pair impulse above.
		var planar: Vector3 = velocities[kart]
		planar.y = 0
		for normal in kart.environment_contacts: planar = planar.slide(normal)
		if not kart.environment_contacts.is_empty(): planar *= kart.config.wall_retention
		kart.velocity.x = planar.x
		kart.velocity.z = planar.z
		kart.signed_speed = kart.velocity.dot(-kart.global_basis.z)
