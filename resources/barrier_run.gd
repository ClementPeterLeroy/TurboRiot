@tool
class_name BarrierRun
extends Resource
## Editable physical fence, independent of the road. Gaps are normalized arc
## intervals along this run, not along the road; wrapped intervals are allowed.
@export var points := PackedVector3Array():
	set(value):
		points = value
		emit_changed()
@export var gaps := PackedVector2Array():
	set(value):
		gaps = value
		emit_changed()
@export var closed: bool = true:
	set(value):
		closed = value
		emit_changed()

func path() -> Curve3D:
	var result := Curve3D.new()
	result.bake_interval = 0.15
	for point in points:
		result.add_point(point)
	if closed and points.size() > 2:
		result.add_point(points[0])
	return result

func enabled_at(fraction: float) -> bool:
	for gap in gaps:
		if gap.x <= gap.y and fraction >= gap.x and fraction < gap.y:
			return false
		if gap.x > gap.y and (fraction >= gap.x or fraction < gap.y):
			return false
	return true
