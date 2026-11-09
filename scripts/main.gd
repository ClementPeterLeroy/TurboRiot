extends Node3D

func _ready() -> void:
	if "--auto-start" in OS.get_cmdline_user_args():
		$RaceManager.start_race.call_deferred()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("exit_game"):
		get_tree().quit()
	if Input.is_action_just_pressed("reset_kart"):
		$Kart/Recovery.recover()
	if Input.is_action_just_pressed("start_race"):
		$RaceManager.start_race()
	if Input.is_action_just_pressed("restart_race"):
		$RaceManager.restart_race()
