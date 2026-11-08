extends Node3D

func _ready() -> void:
	$Kart.safe_spawn = $Track.spawn_transform()
	$Kart.reset_to_spawn()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("exit_game"):
		get_tree().quit()
	if Input.is_action_just_pressed("reset_kart"):
		$Kart.reset_to_spawn()
