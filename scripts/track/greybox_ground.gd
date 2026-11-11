@tool
extends Node3D
## Original neutral terrain; reference bitmap assets are never loaded by Godot.
func _ready() -> void:
	var track := get_parent() as TrackBuilder
	var ground := RiotGeometry.box(self, "Grass", Vector3(track.playable_half_extents.x * 2, 0.6, track.playable_half_extents.y * 2),
		Vector3(0, -0.38, 0), RiotGeometry.material(Color("519a62")), true)
	SurfaceDetector.tag_collision(ground, preload("res://resources/surfaces/grass.tres"))
