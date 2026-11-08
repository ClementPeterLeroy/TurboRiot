class_name RaceSession
extends RefCounted
## Deterministic race rules and timing. No nodes, devices or physics here.
signal state_changed(state: State)
signal lap_completed(lap_number: int, seconds: float)

enum State { READY, COUNTDOWN, RACING, FINISHED }

var state: State = State.READY
var lap_count: int = 3
var checkpoint_count: int = 12 # Includes finish gate zero.
var next_checkpoint: int = 1
var latest_checkpoint: int = 0
var countdown_remaining: float = 0.0
var race_time: float = 0.0
var lap_start_time: float = 0.0
var final_time: float = 0.0
var lap_times: Array[float] = []

func reset(to_countdown: bool = false) -> void:
	next_checkpoint = 1
	latest_checkpoint = 0
	countdown_remaining = 3.0 if to_countdown else 0.0
	race_time = 0.0
	lap_start_time = 0.0
	final_time = 0.0
	lap_times.clear()
	_set_state(State.COUNTDOWN if to_countdown else State.READY)

func start() -> void:
	if state == State.READY:
		reset(true)

func advance(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	if state == State.COUNTDOWN:
		countdown_remaining = maxf(0.0, countdown_remaining - delta)
		if countdown_remaining <= 0.000001:
			countdown_remaining = 0.0
			_set_state(State.RACING)
	elif state == State.RACING:
		race_time += delta

func cross_checkpoint(index: int, forward: bool = true) -> bool:
	if state != State.RACING or not forward:
		return false
	if index == 0:
		if next_checkpoint != checkpoint_count or current_lap_time() <= 0.0:
			return false
		var duration := current_lap_time()
		lap_times.append(duration)
		lap_start_time = race_time
		next_checkpoint = 1
		latest_checkpoint = 0
		lap_completed.emit(lap_times.size(), duration)
		if lap_times.size() >= lap_count:
			final_time = race_time
			_set_state(State.FINISHED)
		return true
	if index != next_checkpoint or index >= checkpoint_count:
		return false
	latest_checkpoint = index
	next_checkpoint += 1
	return true

func current_lap() -> int:
	return mini(lap_times.size() + 1, lap_count)

func current_lap_time() -> float:
	if state == State.FINISHED:
		return last_lap_time()
	return race_time - lap_start_time

func last_lap_time() -> float:
	return lap_times.back() if not lap_times.is_empty() else 0.0

func best_lap_time() -> float:
	return lap_times.min() if not lap_times.is_empty() else 0.0

func indicator() -> String:
	if state == State.COUNTDOWN:
		return str(clampi(ceili(countdown_remaining), 1, 3))
	if state == State.RACING and race_time < 0.85:
		return "GO!"
	return ""

func _set_state(value: State) -> void:
	state = value
	state_changed.emit(state)
