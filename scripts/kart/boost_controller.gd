class_name BoostController
extends RefCounted
## No additive stacking, and never mutate KartConfig. Equal/stronger effects
## refresh the longer remaining duration; weaker requests are ignored.
var source: StringName = &""
var remaining: float = 0.0
var strength: float = 1.0
var direction := Vector3.ZERO
var direction_remaining: float = 0.0

func active() -> bool:
	return remaining > 0.0

func activate(new_source: StringName, multiplier: float, duration: float, policy: KartConfig.BoostPolicy) -> bool:
	if not is_finite(multiplier) or not is_finite(duration) or multiplier <= 1 or duration <= 0:
		return false
	if active() and policy == KartConfig.BoostPolicy.STRONGEST_WINS:
		if multiplier < strength:
			return false
		remaining = maxf(remaining, duration)
	else:
		remaining = duration
	strength = multiplier
	source = new_source
	if new_source != &"boost_pad":
		direction = Vector3.ZERO
		direction_remaining = 0.0
	return true

func advance(delta: float) -> void:
	direction_remaining = maxf(0.0, direction_remaining - delta)
	if direction_remaining == 0.0:
		direction = Vector3.ZERO
	remaining = maxf(0.0, remaining - delta)
	if remaining <= 0:
		clear()

func clear() -> void:
	source = &""
	remaining = 0.0
	strength = 1.0
	direction = Vector3.ZERO
	direction_remaining = 0.0
