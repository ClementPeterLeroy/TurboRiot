class_name KartEffects
extends RefCounted
## Bounded temporary combat modifiers; independent of immutable KartConfig.
var remaining := 0.0
var immunity_remaining := 0.0
var speed_multiplier := 1.0
var grip_multiplier := 1.0

func apply(duration: float, speed: float, grip: float) -> bool:
	if immunity_remaining > 0 or duration <= 0: return false
	remaining = duration
	immunity_remaining = 0.65
	speed_multiplier = clampf(speed, 0.4, 1)
	grip_multiplier = clampf(grip, 0.25, 1)
	return true

func advance(delta: float) -> void:
	immunity_remaining = maxf(0, immunity_remaining - delta)
	remaining = maxf(0, remaining - delta)
	if remaining == 0:
		speed_multiplier = 1
		grip_multiplier = 1

func clear() -> void:
	remaining = 0
	immunity_remaining = 0
	speed_multiplier = 1
	grip_multiplier = 1
