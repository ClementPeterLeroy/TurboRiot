@tool
class_name CheckpointGate
extends Node3D
## A bounded, directed plane, equivalent to an Area crossing but swept between
## physics samples. Fast movement cannot tunnel through it. Forward is -Z.
@export var gate_index: int = 0
@export var gate_width: float = 10.0
@export var gate_height: float = 4.0

func _ready() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(gate_width, gate_height, 0.04)
	$Debug.mesh = mesh
	$Debug.position.y = gate_height * 0.5

func crossing_fraction(from: Vector3, to: Vector3) -> float:
	var inverse := global_transform.affine_inverse()
	var a := inverse * from
	var b := inverse * to
	# Only a transition from behind to in front counts. Sitting on the plane,
	# backing across it, or entering sideways cannot repeatedly trigger it.
	if a.z <= 0.0 or b.z > 0.0:
		return -1.0
	var fraction := a.z / (a.z - b.z)
	var intersection := a.lerp(b, fraction)
	if absf(intersection.x) > gate_width * 0.5 or intersection.y < 0.0 or intersection.y > gate_height:
		return -1.0
	return fraction

func set_debug_visible(value: bool) -> void:
	$Debug.visible = value

func recovery_transform() -> Transform3D:
	return global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 0.65, -2.0))
