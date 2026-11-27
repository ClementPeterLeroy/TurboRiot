extends Node3D
var managed := false
var _music_session: RaceSession

func _ready() -> void:
	if managed: return
	if not $RaceManager.ai_only:
		var definition := TrackRegistry.get_definition(get_meta("circuit_id",&"reference"))
		_music().bind_session($RaceManager.session,definition.racing_music,definition.final_lap_music)
		_music_session=$RaceManager.session
	if "--auto-start" in OS.get_cmdline_user_args():
		$RaceManager.start_race.call_deferred()

func _process(_delta: float) -> void:
	if managed: return
	if Input.is_action_just_pressed("exit_game"):
		set_process(false)
		await _music().shutdown()
		get_tree().quit()
	if Input.is_action_just_pressed("reset_kart"):
		$Kart/Recovery.recover()
	if Input.is_action_just_pressed("start_race"):
		$RaceManager.start_race()
	if Input.is_action_just_pressed("restart_race"):
		$RaceManager.restart_race()

func _exit_tree() -> void:
	if _music_session:_music().release_session(_music_session)

func _music() -> MusicController:
	return get_node("/root/MusicManager") as MusicController
