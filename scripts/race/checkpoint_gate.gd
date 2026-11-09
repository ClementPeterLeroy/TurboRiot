@tool
class_name CheckpointGate
extends Node3D
## A bounded, directed plane, equivalent to an Area crossing but swept between
## physics samples. Fast movement cannot tunnel through it. Forward is -Z.
@export var gate_index: int = 0
@export var gate_width: float = 10.0
@export var gate_height: float = 4.0
var left_extent: float = -1.0
var right_extent: float = -1.0
var route_curve: Curve3D
var route_transform := Transform3D.IDENTITY
var route_offset: float = 0.0
var route_window: float = INF
var legal_outline := PackedVector2Array()

func _ready() -> void:
	var mesh := BoxMesh.new()
	var left := left_extent if left_extent >= 0 else gate_width * 0.5
	var right := right_extent if right_extent >= 0 else gate_width * 0.5
	mesh.size = Vector3(left + right, gate_height, 0.04)
	$Debug.mesh = mesh
	$Debug.position = Vector3((right - left) * 0.5, gate_height * 0.5, 0)

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
	var left := left_extent if left_extent >= 0 else gate_width * 0.5
	var right := right_extent if right_extent >= 0 else gate_width * 0.5
	if intersection.x < -left or intersection.x > right or intersection.y < 0.0 or intersection.y > gate_height:
		return -1.0
	if route_curve:
		var point := route_transform.affine_inverse() * from.lerp(to, fraction)
		if not legal_outline.is_empty() and not Geometry2D.is_point_in_polygon(Vector2(point.x, point.z), legal_outline):
			return -1.0
		var length := route_curve.get_baked_length()
		var difference := absf(route_curve.get_closest_offset(point) - route_offset)
		if minf(difference, length - difference) > route_window:
			return -1.0 # A broad cross-section must never catch another route leg.
	return fraction

func set_debug_visible(value: bool) -> void:
	$Debug.visible = value

func recovery_transform() -> Transform3D:
	return global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 0.65, -2.0))
