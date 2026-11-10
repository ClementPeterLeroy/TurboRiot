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
var item_label := Label.new()
var item_icon := TextureRect.new()

func _ready() -> void:
	var speed_lines := preload("res://scenes/ui/boost_speed_lines.tscn").instantiate() as BoostSpeedLines
	speed_lines.kart = kart
	add_child(speed_lines)
	move_child(speed_lines, 0) # Streaks remain behind the HUD and result panels.
	var item_row := HBoxContainer.new()
	item_icon.custom_minimum_size = Vector2(48, 48)
	item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item_row.add_child(item_icon)
	item_row.add_child(item_label)
	$Margin/Stack.add_child(item_row)
	if not race:
		return
	primary.pressed.connect(_on_primary)
	ready_button.pressed.connect(race.return_to_ready)
	$Overlay/Center/Card/Stack/Exit.pressed.connect(func() -> void: get_tree().quit())
	_refresh()

func _process(_delta: float) -> void:
	if not kart or not race:
		return
	var inventory := kart.get_node("Inventory") as KartInventory
	item_icon.texture = inventory.held.icon if inventory.held else null
	item_label.text = "%s\n%s" % [inventory.held.display_name, "READY: Space / Pad B" if inventory.cooldown == 0 else "Recharging..."] if inventory.held else "ITEM: empty\nDrive through a loot box"
	speed_label.text = "%03d  km/h" % roundi(Vector2(kart.velocity.x, kart.velocity.z).length() * 3.6)
	direction_label.text = "REVERSE" if kart.signed_speed < -0.1 else ("FORWARD" if kart.signed_speed > 0.1 else "STOPPED")
	if Input.is_action_just_pressed("debug_hud"):
		debug_visible = not debug_visible
		race.set_debug_visible(debug_visible)
	if InputMap.has_action("debug_ai") and Input.is_action_just_pressed("debug_ai"):
		race.debug_ai_index += 1
	$DebugPanel.visible = debug_visible
	if debug_visible:
		debug_label.text = "FPS %d | Ground %s\nPosition %.1f, %.1f, %.1f\nThrottle %.2f  Brake %.2f  Steering %.2f\nValidated gate %d | Next %d" % [
			Engine.get_frames_per_second(), kart.is_on_floor(), kart.position.x, kart.position.y,
			kart.position.z, kart.current_command.throttle, kart.current_command.brake, kart.current_command.steering,
			race.session.latest_checkpoint, race.session.next_checkpoint % race.session.checkpoint_count]
		debug_label.text += "\nSurface %s | %s | %.1f km/h\nDrift %s | Level %d | Charge %.2fs\nBoost %s | %.2fs" % [
			kart.surface_detector.current.identifier, "GROUNDED" if kart.is_on_floor() else "AIRBORNE",
			Vector2(kart.velocity.x, kart.velocity.z).length() * 3.6, kart.drift.active,
			kart.drift.level(kart.config), kart.drift.charge, kart.boost.source if kart.boost.active() else &"none", kart.boost.remaining]
		debug_label.text += "\nMushroom terrain %.2fs\nSpin %.0f/%.0f deg | Control %.0f%%" % [kart.boost.mushroom_remaining,
			rad_to_deg(kart.effects.spin_angle), rad_to_deg(kart.effects.total_rotation), kart.effects.control_authority() * 100]
		var presentation := get_parent().get_node_or_null("PresentationDebug")
		if presentation:
			debug_label.text += "\n%s\nF4 mode | F6 CSV | F7 FPS cap\nRender %.0f / Physics %.0f Hz | Cap %s" % [
				presentation.LABELS[presentation.mode], presentation.rendered_fps, presentation.physics_fps,
				str(Engine.max_fps) if Engine.max_fps > 0 else "uncapped"]
			if not presentation.latest.is_empty():
				debug_label.text += "\nCamera pitch %.3f | Screen Y %.2f\nCSV %s" % [presentation.latest.relative_pitch,
					presentation.latest.helmet_y, "ON" if presentation.capture_path != "" and presentation._file else "off"]
		debug_label.text += race.ai_debug_summary()
	$Margin/Stack/Charge.value = kart.drift.charge / maxf(0.01, kart.config.drift_charge_thresholds.z)
	$Margin/Stack/Charge.visible = kart.drift.active
	$Margin/Stack/Handling.text = "BOOST  %.1fs" % kart.boost.remaining if kart.boost.active() else \
		("DRIFT  Level %d" % kart.drift.level(kart.config) if kart.drift.active else "Shift / LB: drift + steer to charge")
	$Margin/Stack/Handling.modulate = Color(1, 0.85, 0.25) if kart.boost.active() else Color(0.6, 0.85, 1)
	if kart.effects.active() and kart.effects.total_rotation != 0:
		$Margin/Stack/Handling.text = "SPIN-OUT" if kart.effects.spinning() else "RECOVERING CONTROL"
		$Margin/Stack/Handling.modulate = Color(1, 0.65, 0.4)
	_refresh()

func _refresh() -> void:
	if not race:
		return
	var session := race.session
	# Fit the default seven-name table at 720p; longer fields/lap details still scroll.
	$Overlay/Center/Card/Stack/Scroll.custom_minimum_size.y = 330 if session.state == RaceSession.State.FINISHED and race.competitors.size() > 1 else 200
	$Margin.visible = session.state == RaceSession.State.COUNTDOWN or session.state == RaceSession.State.RACING
	race_label.text = "POSITION %d / %d    LAP %d / %d\nTOTAL %s     LAP %s\nLAST %s     BEST %s" % [
		race.player_position(), race.competitors.size(), session.current_lap(), session.lap_count, format_time(session.race_time),
		format_time(session.current_lap_time()), optional_time(session.last_lap_time()), optional_time(session.best_lap_time())]
	indicator.text = session.indicator()
	indicator.visible = not indicator.text.is_empty()
	card.visible = session.state == RaceSession.State.READY or session.state == RaceSession.State.FINISHED
	ready_button.visible = session.state == RaceSession.State.FINISHED
	if session.state == RaceSession.State.READY:
		card_title.text = "READY TO RACE"
		card_text.text = "%d racers, %d laps. Follow the circuit in order.\n\nEnter / Space / Pad A starts the countdown.\nR recovers your kart; the clock keeps running.\nF5 / Pad X restarts every racer." % [race.competitors.size(), session.lap_count]
		primary.text = "Start Race"
	elif session.state == RaceSession.State.FINISHED:
		card_title.text = "RACE RESULTS"
		var player := race.competitors[0]
		card_text.text = "POSITION %s / %d\nFINAL TIME   %s\nBEST LAP      %s\n\n" % [
			"DNF" if player.dnf else str(player.finish_order), race.competitors.size(),
			"DNF" if player.dnf else format_time(session.final_time), format_time(session.best_lap_time())]
		for record in race.standings():
			var status := format_time(record.session.final_time) if record.finish_order > 0 else ("DNF" if record.dnf else "RACING")
			card_text.text += "%s  %s   %s\n" % [str(record.finish_order) if record.finish_order > 0 else "—", record.display_name, status]
		if not race.race_complete:
			card_text.text += "\nOther racers are still finishing.\n"
		card_text.text += "\nYOUR LAPS\n"
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
