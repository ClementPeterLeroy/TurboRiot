class_name KartEffects
extends RefCounted
## Bounded temporary combat modifiers; independent of immutable KartConfig.
var remaining := 0.0
var immunity_remaining := 0.0
var speed_multiplier := 1.0
var grip_multiplier := 1.0
var recovery_remaining := 0.0
var spin_angle := 0.0
var total_rotation := 0.0
var _duration := 0.0
var _recovery_seconds := 0.0
var _hit_speed := 1.0
var _hit_grip := 1.0
var _control := 1.0
var _inertia_basis := Basis.IDENTITY

func apply(duration: float, speed: float, grip: float, rotation_degrees := 0.0,
		control := 0.12, recovery_seconds := 0.35, entry_basis := Basis.IDENTITY) -> bool:
	if immunity_remaining > 0 or active() or not is_finite(duration) or duration <= 0: return false
	for value in [speed, grip, rotation_degrees, control, recovery_seconds]:
		if not is_finite(value): return false
	remaining = duration
	_duration = duration
	spin_angle = 0
	total_rotation = deg_to_rad(clampf(rotation_degrees, -720, 720))
	_recovery_seconds = clampf(recovery_seconds, 0.1, 0.8) if total_rotation != 0 else 0.0
	recovery_remaining = 0
	immunity_remaining = duration + _recovery_seconds + 0.35 if total_rotation != 0 else 0.65
	_hit_speed = clampf(speed, 0.25, 1)
	_hit_grip = clampf(grip, 0.1, 1)
	_control = clampf(control, 0, 0.5) if total_rotation != 0 else 1.0
	_inertia_basis = entry_basis.orthonormalized()
	speed_multiplier = _hit_speed
	grip_multiplier = _hit_grip
	return true

func active() -> bool:
	return remaining > 0 or recovery_remaining > 0

func spinning() -> bool:
	return remaining > 0 and total_rotation != 0

func control_authority() -> float:
	return lerpf(_control, 1, _recovery_progress()) if active() else 1.0

func driving_basis(body_basis: Basis) -> Basis:
	if total_rotation == 0 or not active(): return body_basis
	# A spinning vehicle slides under inertia, rather than following a tight
	# scripted circle. Afterward traction aligns with its actual final heading.
	return _inertia_basis.slerp(body_basis.orthonormalized(), _recovery_progress())

func steer_inertia(yaw: float) -> void:
	if active(): _inertia_basis = Basis(Vector3.UP, yaw) * _inertia_basis

func driving_command(raw: DrivingCommand) -> DrivingCommand:
	if total_rotation == 0 or not active(): return raw
	var authority := control_authority()
	return DrivingCommand.new(raw.throttle * authority, raw.brake * lerpf(0.5, 1, authority),
		raw.steering * authority, false, raw.use_item)

func _recovery_progress() -> float:
	if remaining > 0: return 0.0
	if _recovery_seconds == 0: return 1.0
	var t := clampf(1 - recovery_remaining / _recovery_seconds, 0, 1)
	return t * t * (3 - 2 * t)

func advance(delta: float) -> float:
	immunity_remaining = maxf(0, immunity_remaining - delta)
	var previous_angle := spin_angle
	if remaining > 0:
		remaining = maxf(0, remaining - delta)
		var t := clampf(1 - remaining / _duration, 0, 1)
		spin_angle = total_rotation * t * t * (3 - 2 * t)
		if remaining == 0: recovery_remaining = _recovery_seconds
	else:
		recovery_remaining = maxf(0, recovery_remaining - delta)
	var recovery := _recovery_progress()
	speed_multiplier = lerpf(_hit_speed, 1, recovery)
	grip_multiplier = lerpf(_hit_grip, 1, recovery)
	return spin_angle - previous_angle

func clear() -> void:
	remaining = 0
	immunity_remaining = 0
	speed_multiplier = 1
	grip_multiplier = 1
	recovery_remaining = 0
	spin_angle = 0
	total_rotation = 0
	_duration = 0
	_recovery_seconds = 0
	_hit_speed = 1
	_hit_grip = 1
	_control = 1
	_inertia_basis = Basis.IDENTITY
