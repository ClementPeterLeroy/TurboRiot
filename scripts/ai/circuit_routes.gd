class_name CircuitRoutes
extends RefCounted
## Shared station space for disjoint, directed alternatives on a closed lap.
var mask := 0
var main_length := 0.0
var alternatives: Array[Dictionary] = []
var canonical := PackedFloat32Array()
var stations := PackedFloat32Array()

func configure(track: TrackBuilder, variant: int, include_alternatives: bool) -> Curve3D:
	mask = variant
	main_length = track.curve.get_baked_length()
	alternatives.clear()
	canonical = PackedFloat32Array([0,main_length])
	stations = canonical.duplicate()
	if include_alternatives:
		for branch in track.route_branches:
			var points := PackedVector3Array()
			var offsets := PackedFloat32Array()
			var count := maxi(2,ceili(branch.curve.get_baked_length()/2))
			var bounds := AABB(track.to_global(branch.curve.get_point_position(0)),Vector3.ZERO)
			for i in range(count+1):
				var p := track.to_global(branch.curve.sample_baked(branch.curve.get_baked_length()*i/count,true))
				points.append(p)
				offsets.append(lerpf(branch.entry_offset,branch.exit_offset,float(i)/count))
				bounds = bounds.expand(p)
			alternatives.append({"points":points,"offsets":offsets,"bounds":bounds.grow(branch.width),"branch":branch})
	if variant == 0: return track.curve
	var curve := Curve3D.new()
	curve.bake_interval = .2
	canonical.clear()
	stations.clear()
	var distance := 0.0
	var offset := 0.0
	while offset < main_length:
		var selected: RouteBranch
		for i in track.route_branches.size():
			var branch := track.route_branches[i]
			if variant & (1 << i) and offset >= branch.entry_offset and offset <= branch.entry_offset+1.01:
				selected = branch
				break
		if selected:
			var count := maxi(2,ceili(selected.curve.get_baked_length()))
			for i in range(count+1):
				var p := selected.curve.sample_baked(selected.curve.get_baked_length()*i/count,true)
				if curve.point_count > 0: distance += p.distance_to(curve.get_point_position(curve.point_count-1))
				curve.add_point(p)
				canonical.append(lerpf(selected.entry_offset,selected.exit_offset,float(i)/count))
				stations.append(distance)
			offset = selected.exit_offset+1
		else:
			var p := track.sample_center(offset)
			if curve.point_count > 0: distance += p.distance_to(curve.get_point_position(curve.point_count-1))
			curve.add_point(p)
			canonical.append(offset)
			stations.append(distance)
			offset += 1
	distance += track.sample_center(main_length).distance_to(curve.get_point_position(curve.point_count-1))
	curve.add_point(track.sample_center(main_length))
	canonical.append(main_length)
	stations.append(distance)
	return curve

func interpolate(a: PackedFloat32Array, b: PackedFloat32Array, value: float) -> float:
	var low := 0
	var high := a.size()-1
	while high-low > 1:
		var middle := (low+high)/2
		if a[middle] <= value: low=middle
		else: high=middle
	return lerpf(b[low],b[high],clampf((value-a[low])/maxf(.00001,a[high]-a[low]),0,1))

func from_canonical(value: float) -> float:
	return interpolate(canonical,stations,fposmod(value,main_length)) if mask != 0 else value

func to_canonical(value: float) -> float:
	return interpolate(stations,canonical,value) if mask != 0 else value

func project_alternatives(position: Vector3, best: Vector3, distance: float, spacing: float) -> Vector3:
	for data in alternatives:
		if not data.bounds.has_point(position): continue
		for i in data.points.size()-1:
			var a: Vector3 = data.points[i]
			var edge: Vector3 = data.points[i+1]-a
			var t := clampf((position-a).dot(edge)/maxf(.0001,edge.length_squared()),0,1)
			var p := a+edge*t
			if position.distance_squared_to(p) < distance:
				distance = position.distance_squared_to(p)
				var offset := lerpf(data.offsets[i],data.offsets[i+1],t)
				best = Vector3(offset,(position-p).dot(edge.normalized().cross(Vector3.UP)),int(offset/spacing))
	return best

func minimum_interval_length(start: float, finish: float) -> float:
	var length := fposmod(finish-start,main_length)
	var result := length
	for data in alternatives:
		var branch: RouteBranch = data.branch
		var entry := fposmod(branch.entry_offset-start,main_length)
		# Serialized gate fractions are float32. An entry coincident with a
		# gate can round a millimetre behind it; it still belongs to this interval.
		if minf(entry,main_length-entry) < .02: entry=0
		if entry+branch.exit_offset-branch.entry_offset <= length+.01:
			result -= maxf(0,branch.exit_offset-branch.entry_offset-branch.curve.get_baked_length())
	return maxf(1,result)
