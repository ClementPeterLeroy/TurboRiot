extends CanvasLayer

@export var kart: KartController
@onready var speed_label: Label = $Margin/Stack/Speed
@onready var direction_label: Label = $Margin/Stack/Direction
@onready var debug_label: Label = $Margin/Stack/Debug
var debug_visible := false

func _process(_delta: float) -> void:
	if not kart:
		return
	speed_label.text = "%03d  km/h" % roundi(Vector2(kart.velocity.x, kart.velocity.z).length() * 3.6)
	direction_label.text = "REVERSE" if kart.signed_speed < -0.1 else ("FORWARD" if kart.signed_speed > 0.1 else "STOPPED")
	if Input.is_action_just_pressed("debug_hud"):
		debug_visible = not debug_visible
	debug_label.visible = debug_visible
	if debug_visible:
		debug_label.text = "FPS %d | Ground %s\nPosition %.1f, %.1f, %.1f\nThrottle %.2f  Brake %.2f  Steering %.2f" % [
			Engine.get_frames_per_second(), kart.is_on_floor(), kart.position.x, kart.position.y,
			kart.position.z, kart.current_command.throttle, kart.current_command.brake, kart.current_command.steering]
