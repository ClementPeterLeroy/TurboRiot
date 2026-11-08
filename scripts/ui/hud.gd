class_name RaceHUD
extends CanvasLayer

@export var kart: KartController
@export var race: RaceManager
@onready var speed_label: Label = $Margin/Stack/Speed
@onready var direction_label: Label = $Margin/Stack/Direction
@onready var debug_label: Label = $DebugPanel/Debug
@onready var race_label: Label = $Margin/Stack/RaceTimes
@onready var indicator: Label = $Overlay/Countdown
@onready var card: PanelContainer = $Overlay/Center/Card
@onready var card_title: Label = $Overlay/Center/Card/Stack/Title
@onready var card_text: Label = $Overlay/Center/Card/Stack/Scroll/Text
@onready var primary: Button = $Overlay/Center/Card/Stack/Primary
@onready var ready_button: Button = $Overlay/Center/Card/Stack/Ready
var debug_visible := false

func _ready() -> void:
	primary.pressed.connect(_on_primary)
	ready_button.pressed.connect(race.return_to_ready)
	$Overlay/Center/Card/Stack/Exit.pressed.connect(func() -> void: get_tree().quit())
	_refresh()

func _process(_delta: float) -> void:
	if not kart or not race:
		return
	speed_label.text = "%03d  km/h" % roundi(Vector2(kart.velocity.x, kart.velocity.z).length() * 3.6)
	direction_label.text = "REVERSE" if kart.signed_speed < -0.1 else ("FORWARD" if kart.signed_speed > 0.1 else "STOPPED")
	if Input.is_action_just_pressed("debug_hud"):
		debug_visible = not debug_visible
		race.set_debug_visible(debug_visible)
	$DebugPanel.visible = debug_visible
	if debug_visible:
		debug_label.text = "FPS %d | Ground %s\nPosition %.1f, %.1f, %.1f\nThrottle %.2f  Brake %.2f  Steering %.2f\nValidated gate %d | Next %d" % [
			Engine.get_frames_per_second(), kart.is_on_floor(), kart.position.x, kart.position.y,
			kart.position.z, kart.current_command.throttle, kart.current_command.brake, kart.current_command.steering,
			race.session.latest_checkpoint, race.session.next_checkpoint % race.session.checkpoint_count]
	_refresh()

func _refresh() -> void:
	if not race:
		return
	var session := race.session
	$Margin.visible = session.state == RaceSession.State.COUNTDOWN or session.state == RaceSession.State.RACING
	race_label.text = "LAP %d / %d     TOTAL %s\nLAP TIME   %s\nLAST   %s     BEST   %s" % [
		session.current_lap(), session.lap_count, format_time(session.race_time),
		format_time(session.current_lap_time()), optional_time(session.last_lap_time()), optional_time(session.best_lap_time())]
	indicator.text = session.indicator()
	indicator.visible = not indicator.text.is_empty()
	card.visible = session.state == RaceSession.State.READY or session.state == RaceSession.State.FINISHED
	ready_button.visible = session.state == RaceSession.State.FINISHED
	if session.state == RaceSession.State.READY:
		card_title.text = "READY TO RACE"
		card_text.text = "%d laps. Follow the circuit in order.\n\nEnter / Space / Pad A starts the countdown.\nR recovers your kart; the clock keeps running.\nF5 / Pad X restarts the whole race." % session.lap_count
		primary.text = "Start Race"
	elif session.state == RaceSession.State.FINISHED:
		card_title.text = "TIME TRIAL COMPLETE"
		card_text.text = "FINAL TIME   %s\nBEST LAP      %s\n\n" % [format_time(session.final_time), format_time(session.best_lap_time())]
		for i in session.lap_times.size():
			card_text.text += "Lap %d     %s\n" % [i + 1, format_time(session.lap_times[i])]
		primary.text = "Restart Race"

func _on_primary() -> void:
	if race.session.state == RaceSession.State.READY:
		race.start_race()
	else:
		race.restart_race()

static func format_time(seconds: float) -> String:
	var milliseconds := maxi(0, floori(seconds * 1000.0 + 0.000001))
	return "%02d:%02d.%03d" % [milliseconds / 60000, (milliseconds / 1000) % 60, milliseconds % 1000]

static func optional_time(seconds: float) -> String:
	return format_time(seconds) if seconds > 0.0 else "--:--.---"
