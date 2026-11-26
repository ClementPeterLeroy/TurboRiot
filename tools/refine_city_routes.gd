extends SceneTree
## Targeted vertical edit. Preserve every existing point/handle XZ coordinate.
const DIR := "res://resources/tracks/city_square/"
func _initialize() -> void: run.call_deferred()

func station(curve: Curve3D, point: Vector3) -> float:
	return curve.get_closest_offset(point)

func grade(s: float, flights: Array) -> float:
	var height := 8.2
	for f in flights:
		var t := clampf((s-f[0])/(f[1]-f[0]),0,1)
		height-=f[2]*t*t*(3-2*t)
	return height

func rows(curve: Curve3D, start: float, finish: float, width: float, wood := false) -> Array:
	var result: Array=[]
	var count := ceili(finish-start)
	for i in range(count+1):
		var s := lerpf(start,finish,float(i)/count)
		var p := curve.sample_baked(s,true)
		var f := curve.sample_baked(minf(s+.15,curve.get_baked_length()),true)-curve.sample_baked(maxf(s-.15,0),true)
		var right := f.cross(Vector3.UP).normalized()
		result.append({"offset":s,"position":[p.x,p.y,p.z],"right":[right.x,right.y,right.z],"width":width,"wood":wood})
	return result

func run() -> void:
	var plan: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DIR+"structural_plan.json"))
	var old_survey: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DIR+"survey.json"))
	if old_survey.get("structural_revision",0)>=1:
		push_error("Structural route edit already applied; review artist changes before rebaking.")
		quit(1)
		return
	var track := load("res://scenes/tracks/city_square.tscn").instantiate() as AuthoredCircuit
	var curve := track.curve
	var old := curve.duplicate() as Curve3D
	var left := track.route_branches[0]
	var old_left := left.curve.duplicate() as Curve3D
	var entry := left.entry_offset
	var finish := left.exit_offset
	var changes := []
	for pair in [[curve,old,entry,finish,plan.stair_flights.right],[left.curve,old_left,0.0,old_left.get_baked_length(),plan.stair_flights.left]]:
		var target: Curve3D=pair[0]
		var original: Curve3D=pair[1]
		for i in target.point_count:
			var p := original.get_point_position(i)
			var offset := station(original,p)
			if offset<float(pair[2])-.01 or offset>float(pair[3])+.01:continue
			p.y=grade(offset-float(pair[2]),pair[4])
			target.set_point_position(i,p)
			var a := original.get_point_in(i)
			var b := original.get_point_out(i)
			a.y=0
			b.y=0
			target.set_point_in(i,a)
			target.set_point_out(i,b)
	for b in track.route_branches:
		b.entry_offset=station(curve,old.sample_baked(b.entry_offset,true))
		b.exit_offset=station(curve,old.sample_baked(b.exit_offset,true))
	var new_length := curve.get_baked_length()
	var samples: Array=[]
	# Retain the original survey's XZ cross-sections. Only change their Y and
	# mapped stations/wood width; existing mesh footprint is the authority.
	for row in old_survey.samples:
		var p := Vector3(row.position[0],row.position[1],row.position[2])
		var delta := 0.0
		if row.offset>=entry and row.offset<=finish:
			delta=grade(row.offset-entry,plan.stair_flights.right)-p.y
			p.y+=delta
		var mapped := station(curve,p)
		if row.offset>=old.get_baked_length()-.01:mapped=new_length
		var copy: Dictionary=row.duplicate(true)
		copy.position[1]=p.y
		copy.offset=mapped
		if row.wood:copy.width=plan.dock_width
		if row.offset>=entry-8 and row.offset<=finish+8:changes.append({"old":row.position.duplicate(),"new":copy.position.duplicate()})
		samples.append(copy)
	for i in old_survey.branches.size():
		var data: Dictionary=old_survey.branches[i]
		var resource: RouteBranch=track.route_branches[i]
		for row in data.rows:
			var p := Vector3(row.position[0],row.position[1],row.position[2])
			var before: Array=row.position.duplicate()
			if i==0:p.y=grade(row.offset,plan.stair_flights.left)
			row.position[1]=p.y
			row.offset=station(resource.curve,p)
			if i==0:changes.append({"old":before,"new":row.position.duplicate()})
		data.entry=resource.entry_offset
		data.exit=resource.exit_offset
		data.length=resource.curve.get_baked_length()
	var gates := PackedFloat32Array()
	for f in track.checkpoint_fractions:gates.append(station(curve,old.sample_baked(f*old.get_baked_length(),true))/new_length)
	for i in track.width_profile.point_count:
		var p := track.width_profile.get_point_position(i)
		var original := old.sample_baked(p.x*old.get_baked_length(),true)
		p.x=station(curve,original)/new_length if p.x<.99999 else 1.0
		if is_equal_approx(p.y,13):p.y=plan.dock_width
		track.width_profile.set_point_value(i,p.y)
		track.width_profile.set_point_offset(i,p.x)
	track.runoff_interval=Vector2(station(curve,old.sample_baked(track.runoff_interval.x,true)),station(curve,old.sample_baked(track.runoff_interval.y,true)))
	var flights: Array=[]
	for side in ["right","left"]:
		var before := old if side=="right" else old_left
		var source := curve if side=="right" else left.curve
		var start := entry if side=="right" else 0.0
		for f in plan.stair_flights[side]:
			var a := before.sample_baked(start+f[0],true)
			var b := before.sample_baked(start+f[1],true)
			a.y=grade(f[0],plan.stair_flights[side])
			b.y=grade(f[1],plan.stair_flights[side])
			flights.append({"side":side,"start":[a.x,a.y,a.z],"end":[b.x,b.y,b.z],"drop":f[2],"width":20.0,"start_offset":station(source,a),"end_offset":station(source,b)})
	old_survey.samples=samples
	old_survey.length=new_length
	old_survey.gates=Array(gates)
	old_survey.stair_flights=flights
	old_survey.structural_revision=1
	old_survey.height_edits=changes
	FileAccess.open(DIR+"survey.json",FileAccess.WRITE).store_string(JSON.stringify(old_survey,"\t"))
	ResourceSaver.save(curve,DIR+"centerline.tres")
	for b in track.route_branches:ResourceSaver.save(b,b.resource_path)
	ResourceSaver.save(track.width_profile,DIR+"widths.tres")
	FileAccess.open("res://.godot/city_structural_metadata.json",FileAccess.WRITE).store_string(JSON.stringify({"gates":Array(gates),"runoff":[track.runoff_interval.x,track.runoff_interval.y]}))
	print("CITY_STRUCTURAL_ROUTES length=",new_length," branches=",track.route_branches[0].curve.get_baked_length()," / ",left.exit_offset-left.entry_offset)
	track.free()
	quit()
