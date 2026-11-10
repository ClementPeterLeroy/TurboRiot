class_name BoostController
extends RefCounted
## No additive stacking, and never mutate KartConfig. Equal/stronger effects
## refresh the longer remaining duration; weaker requests are ignored.
var source: StringName = &""
var remaining: float = 0.0
var strength: float = 1.0
var direction := Vector3.ZERO
var direction_remaining: float = 0.0
var mushroom_remaining := 0.0
var feedback_remaining := 0.0
var feedback_serial := 0 # Monotonic; a new accepted pad/mushroom starts a burst.

func active() -> bool:
	return remaining > 0.0

func activate(new_source: StringName, multiplier: float, duration: float, policy: KartConfig.BoostPolicy, source_duration: float = -1.0) -> bool:
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
	var own_duration := duration if source_duration < 0 else source_duration
	if policy == KartConfig.BoostPolicy.REPLACE:
		mushroom_remaining = 0
		feedback_remaining = 0
	if new_source == &"mushroom":
		mushroom_remaining = maxf(mushroom_remaining, own_duration)
	if new_source in [&"mushroom", &"boost_pad"]:
		feedback_remaining = maxf(feedback_remaining, own_duration)
		feedback_serial += 1
	if new_source != &"boost_pad":
		direction = Vector3.ZERO
		direction_remaining = 0.0
	return true

func advance(delta: float) -> void:
	mushroom_remaining = maxf(0, mushroom_remaining - delta)
	feedback_remaining = maxf(0, feedback_remaining - delta)
	direction_remaining = maxf(0.0, direction_remaining - delta)
	if direction_remaining == 0.0:
		direction = Vector3.ZERO
	remaining = maxf(0.0, remaining - delta)
	if remaining <= 0:
		clear()

func clear() -> void:
	mushroom_remaining = 0
	feedback_remaining = 0
	source = &""
	remaining = 0.0
	strength = 1.0
	direction = Vector3.ZERO
	direction_remaining = 0.0
