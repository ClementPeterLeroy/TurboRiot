class_name AppSettings
extends RefCounted
const RESOLUTIONS := [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(1024, 768)]
var fullscreen := false
var resolution := Vector2i(1280, 720)
var vsync := true
var ui_scale := 1.0
var volumes := {"Master": 0.8, "Music": 0.35, "Effects": 0.7}
var muted := {"Master": false, "Music": false, "Effects": false}
var path := "user://settings.cfg"

static func number(value: Variant, fallback: float, minimum: float, maximum: float) -> float:
	if (value is float or value is int) and is_finite(float(value)): return clampf(float(value), minimum, maximum)
	return fallback

func copy() -> AppSettings:
	var result := AppSettings.new()
	result.path = path
	result.fullscreen = fullscreen
	result.resolution = resolution
	result.vsync = vsync
	result.ui_scale = ui_scale
	result.volumes = volumes.duplicate()
	result.muted = muted.duplicate()
	return result

func load_settings() -> Error:
	var file := ConfigFile.new()
	var error := file.load(path)
	if error != OK: return error # Fresh defaults are valid when absent/corrupt.
	var value: Variant = file.get_value("display", "fullscreen", false)
	fullscreen = value if value is bool else false
	value = file.get_value("display", "vsync", true)
	vsync = value if value is bool else true
	value = file.get_value("display", "resolution", Vector2i(1280, 720))
	resolution = value if value is Vector2i and value in RESOLUTIONS else Vector2i(1280, 720)
	ui_scale = number(file.get_value("display", "ui_scale", 1.0), 1.0, 0.85, 1.25)
	for bus: String in volumes:
		volumes[bus] = number(file.get_value("audio", bus, volumes[bus]), volumes[bus], 0, 1)
		value = file.get_value("audio", bus + "_muted", false)
		muted[bus] = value if value is bool else false
	return OK

func save_settings() -> Error:
	var file := ConfigFile.new()
	file.set_value("display", "fullscreen", fullscreen)
	file.set_value("display", "resolution", resolution)
	file.set_value("display", "vsync", vsync)
	file.set_value("display", "ui_scale", ui_scale)
	for bus: String in volumes:
		file.set_value("audio", bus, number(volumes[bus], 0.7, 0, 1))
		file.set_value("audio", bus + "_muted", muted[bus])
	return file.save(path)

func apply_audio() -> void:
	for bus: String in volumes:
		var index := AudioServer.get_bus_index(bus)
		if index < 0: continue
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.0001, volumes[bus])))
		AudioServer.set_bus_mute(index, muted[bus] or volumes[bus] == 0)

func apply_display(window: Window) -> void:
	window.content_scale_factor = ui_scale
	if DisplayServer.get_name() == "headless": return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	if not fullscreen:
		window.size = resolution
		window.move_to_center()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
