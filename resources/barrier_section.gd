@tool
class_name BarrierSection
extends Resource
## Overrides one side/both sides of a lap interval. Last matching section wins.
enum Sides { BOTH, LEFT, RIGHT }
@export_range(0.0, 1.0) var start_fraction: float = 0.82:
	set(value):
		start_fraction = value
		emit_changed()
@export_range(0.0, 1.0) var end_fraction: float = 0.88:
	set(value):
		end_fraction = value
		emit_changed()
@export var sides: Sides = Sides.LEFT:
	set(value):
		sides = value
		emit_changed()
@export var barriers_enabled: bool = false:
	set(value):
		barriers_enabled = value
		emit_changed()
## -1 retains the side's clearance curve.
@export_range(-1.0, 25.0) var clearance_override: float = -1.0:
	set(value):
		clearance_override = value
		emit_changed()

func applies(fraction: float, side: float) -> bool:
	if sides == Sides.LEFT and side > 0 or sides == Sides.RIGHT and side < 0:
		return false
	if start_fraction <= end_fraction:
		return fraction >= start_fraction and fraction < end_fraction
	return fraction >= start_fraction or fraction < end_fraction
