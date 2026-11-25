class_name RacingLine
extends RefCounted
## Cached world-space samples of the actual source circuit. No route shortcuts.
var points := PackedVector3Array()
var forwards := PackedVector3Array()
var curvatures := PackedFloat32Array()
var corridor := PackedVector2Array()
var length := 0.0
var spacing := 2.0
var road_half_width := 0.0
var outline := PackedVector2Array()
var routes := CircuitRoutes.new()

func build(track: TrackBuilder, variant := 0, include_alternatives := true) -> void:
	var source := routes.configure(track,variant,include_alternatives)
	length = source.get_baked_length()
	road_half_width = track.road_width * 0.5
	var count := maxi(4, ceili(length / 2.0))
	spacing = length / count
	points.resize(count)
	forwards.resize(count)
	curvatures.resize(count)
	corridor.resize(count)
	for i in count:
		if variant == 0:
			points[i] = track.to_global(track.sample_center(i * spacing))
			forwards[i] = (track.global_basis * track.sample_forward(i * spacing)).normalized()
		else:
			points[i] = track.to_global(source.sample_baked(i*spacing,true))
			forwards[i] = (track.global_basis * (source.sample_baked(fposmod(i*spacing+.2,length),true)-source.sample_baked(fposmod(i*spacing-.2,length),true)).normalized()).normalized()
		corridor[i] = track.corridor_limits(routes.to_canonical(i * spacing))
	for i in count:
		var before := forwards[posmod(i - 1, count)]
		var after := forwards[(i + 1) % count]
		# Lateral corner planning measures heading, not changing road grade.
		before.y=0
		after.y=0
		before=before.normalized()
		after=after.normalized()
		curvatures[i] = absf(before.signed_angle_to(after, Vector3.UP)) / (2.0 * spacing)
	outline.clear()
	for point in track.legal_outline():
		var world := track.to_global(Vector3(point.x, 0, point.y))
		outline.append(Vector2(world.x, world.z))

func index_at(offset: float) -> int:
	return int(fposmod(offset, length) / spacing) % points.size()

func point_at(offset: float, lateral: float = 0.0) -> Vector3:
	var normalized := fposmod(offset, length) / spacing
	var index := int(normalized) % points.size()
	var next := (index + 1) % points.size()
	var direction := forwards[index].lerp(forwards[next], normalized - floorf(normalized)).normalized()
	return points[index].lerp(points[next], normalized - floorf(normalized)) + direction.cross(Vector3.UP) * lateral

func project(position: Vector3, hint: int = -1) -> Vector3:
	# Result: source offset, signed lateral distance, segment index. Search a
	# bounded neighborhood normally; only teleports/lost tracks need a full scan.
	var best := Vector3.ZERO
	var distance := INF
	var count := points.size()
	var scans := count if hint < 0 else 25
	for scan in scans:
		var index := scan if hint < 0 else posmod(hint + scan - 12, count)
		var a := points[index]
		var segment := points[(index + 1) % count] - a
		# Include height when acquiring a route: projected crossings are separate roads.
		var fraction := clampf((position - a).dot(segment) / segment.length_squared(), 0, 1)
		var closest := a + segment * fraction
		var squared := position.distance_squared_to(closest)
		if squared < distance:
			distance = squared
			best = Vector3(fposmod((index + fraction) * spacing, length),
				(position - closest).dot(forwards[index].cross(Vector3.UP).normalized()), index)
	var alternative := routes.project_alternatives(position,best,distance,spacing)
	if alternative != best: return alternative
	if hint >= 0 and distance > 18.0 * 18.0:
		return project(position)
	return best

func from_canonical(offset: float) -> float:
	return routes.from_canonical(offset)

func minimum_interval_length(start: float, finish: float) -> float:
	return routes.minimum_interval_length(start,finish)

func legal(position: Vector3, projection: Vector3) -> bool:
	if not outline.is_empty() and not Geometry2D.is_point_in_polygon(Vector2(position.x, position.z), outline):
		return false
	var limits := corridor[int(projection.z)]
	return projection.y >= -limits.x and projection.y <= limits.y

func planned_speed(offset: float, speed: float, config: KartConfig, profile: AIDriverProfile) -> float:
	var target := config.max_forward_speed * profile.speed_fraction
	var deceleration := config.braking * profile.braking_confidence * 0.65
	var horizon := maxf(18.0, speed * speed / (2 * deceleration) + speed * 0.7)
	var distance := 0.0
	while distance <= horizon:
		var curvature := curvatures[index_at(offset + distance)]
		var corner_speed := sqrt(profile.lateral_acceleration / maxf(curvature, 0.0001))
		target = minf(target, sqrt(corner_speed * corner_speed + 2 * deceleration * maxf(0, distance - 3)))
		distance += spacing
	return target
