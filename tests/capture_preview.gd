extends SceneTree
## Optional rendered inspection helper; requires a graphics/display driver.
## godot --path . --script tests/capture_preview.gd
var ticks := 0
var main: Node3D

func _initialize() -> void:
	_start.call_deferred()

func _start() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	root.size = Vector2i(1280, 720)
	await create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	root.get_texture().get_image().save_png("res://artifacts/first_drive.png")
	main.get_node("ChaseCamera").set_process(false)
	main.get_node("HUD").visible = false
	var camera := main.get_node("ChaseCamera") as Camera3D
	camera.position = Vector3(0, 230, 1)
	camera.look_at(Vector3.ZERO, Vector3.FORWARD)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 215
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/circuit_overview.png")
	print("Saved rendered previews to artifacts/")
	quit()
