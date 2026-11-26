extends SceneTree
const OUT := "res://resources/tracks/city_square/"
func _initialize() -> void: run.call_deferred()

func make_curve(points: Array, closed: bool) -> Curve3D:
	var curve := Curve3D.new()
	curve.bake_interval = .15
	for i in points.size():
		var p := Vector3(points[i][0],points[i][1],points[i][2])
		var before: Array = points[maxi(0,i-1)]
		var after: Array = points[mini(points.size()-1,i+1)]
		if closed and i == 0: before = points[points.size()-2]
		if closed and i == points.size()-1: after = points[1]
		var a := Vector3(before[0],before[1],before[2])
		var b := Vector3(after[0],after[1],after[2])
		var tangent := (b-a).normalized()*minf(6,minf(a.distance_to(p),b.distance_to(p))*.28)
		# Flat landings must remain flat across widened intersections; otherwise
		# a neighbouring plaza cuts a vertical lip into the rising approach.
		if is_equal_approx(p.y,a.y) or is_equal_approx(p.y,b.y):tangent.y=0
		curve.add_point(p,-tangent,tangent)
	return curve

func stairs_height(s: float, length: float, left: bool) -> float:
	var drop := 0.0
	var flights := [[.17,.68,5.4]] if left else [[.09,.26,1.8],[.40,.57,1.8],[.72,.89,1.8]]
	for flight in flights:
		var t := clampf((s/length-flight[0])/(flight[1]-flight[0]),0,1)
		drop += flight[2]*t*t*(3-2*t)
	return 8.2-drop

func inner_curve(points: Array, corner_shift: float) -> Curve3D:
	var adjusted := points.duplicate(true)
	for i in [2,3,4]:
		var weight := 1.0 if i == 3 else .5
		adjusted[i][0] -= corner_shift*weight
		adjusted[i][2] += corner_shift*weight
	var flat := make_curve(adjusted,false)
	var result := Curve3D.new()
	result.bake_interval=.15
	for i in 81:
		var s := flat.get_baked_length()*i/80
		var p := flat.sample_baked(s,true)
		p.y=stairs_height(s,flat.get_baked_length(),true)
		result.add_point(p)
	return result

func run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT+"layout.json"))
	var curve := make_curve(data.points,true)
	var entry := curve.get_closest_offset(curve.get_point_position(data.branch_entry_index))
	var exit := curve.get_closest_offset(curve.get_point_position(data.branch_exit_index))
	# Add stations through each stair flight so smooth collision has the same
	# descent as its visible steps, with broad landings on the outer route.
	var horizontal := curve.duplicate() as Curve3D
	var rebuilt := Curve3D.new()
	rebuilt.bake_interval = .15
	for i in curve.point_count:
		var p := curve.get_point_position(i)
		var offset := curve.get_closest_offset(p)
		if i >= data.branch_entry_index and i <= data.branch_exit_index:
			continue
		if i == data.branch_exit_index+1:
			for j in 81:
				var s := entry+(exit-entry)*j/80
				var c := horizontal.sample_baked(s,true)
				c.y=stairs_height(s-entry,exit-entry,false)
				rebuilt.add_point(c)
		rebuilt.add_point(p,curve.get_point_in(i),curve.get_point_out(i))
	curve=rebuilt
	ResourceSaver.save(curve,OUT+"centerline.tres")
	entry=curve.get_closest_offset(horizontal.get_point_position(data.branch_entry_index))
	exit=curve.get_closest_offset(horizontal.get_point_position(data.branch_exit_index))
	var inner_points: Array=[]
	for pixel in data.inner_pixels: inner_points.append([(pixel[0]-520)*.75,8.2,(pixel[1]-300)*.75])
	var low := 0.0
	var high := 2.0
	for i in 18:
		var mid := (low+high)/2
		if inner_curve(inner_points,mid).get_baked_length() < exit-entry: low=mid
		else: high=mid
	var inner := inner_curve(inner_points,(low+high)/2)
	var branch := RouteBranch.new()
	branch.label="Left street / long stairs"
	branch.curve=inner
	branch.width=20
	branch.entry_offset=entry
	branch.exit_offset=exit
	ResourceSaver.save(branch,OUT+"left_street.tres")
	var fountain_points: Array=[]
	for pixel in data.fountain_alternate_pixels: fountain_points.append([(pixel[0]-520)*.75,10.5,(pixel[1]-300)*.75])
	var fountain := RouteBranch.new()
	fountain.label="Fountain east side"
	fountain.curve=make_curve(fountain_points,false)
	fountain.width=22
	fountain.entry_offset=curve.get_closest_offset(Vector3(data.points[3][0],10.5,data.points[3][2]))
	fountain.exit_offset=curve.get_closest_offset(Vector3(data.points[10][0],10.5,data.points[10][2]))
	ResourceSaver.save(fountain,OUT+"fountain_lane.tres")
	var samples: Array=[]
	var length := curve.get_baked_length()
	for i in range(ceili(length)+1):
		var offset := length*i/ceili(length)
		var p := curve.sample_baked(offset,true)
		var forward := (curve.sample_baked(fposmod(offset+.2,length),true)-curve.sample_baked(fposmod(offset-.2,length),true)).normalized()
		var r := forward.cross(Vector3.UP).normalized()
		var width := 22.0 if i*1.0/ceili(length)<fountain.entry_offset/length or offset>length-22 else 20.0
		if offset>length*.8 and absf(p.x+120)<1.5:width=22.0
		if offset>=fountain.entry_offset and offset<=fountain.exit_offset:width=22
		var wood_start := curve.get_closest_offset(Vector3(data.points[27][0],2,data.points[27][2]))
		var wood_end := curve.get_closest_offset(Vector3(data.points[42][0],2,data.points[42][2]))
		if offset>=wood_start and offset<=wood_end:width=13
		if offset>wood_end and offset<length-22 and not (offset>length*.8 and absf(p.x+120)<1.5):width=10
		samples.append({"offset":offset,"position":[p.x,p.y,p.z],"right":[r.x,r.y,r.z],"width":width,"wood":offset>=wood_start and offset<=wood_end})
	var branches: Array=[]
	for route in [branch,fountain]:
		var rows: Array=[]
		for i in range(ceili(route.curve.get_baked_length())+1):
			var s: float = route.curve.get_baked_length()*i/ceili(route.curve.get_baked_length())
			var p: Vector3 = route.curve.sample_baked(s,true)
			var f: Vector3 = (route.curve.sample_baked(minf(s+.2,route.curve.get_baked_length()),true)-route.curve.sample_baked(maxf(0,s-.2),true)).normalized()
			var r: Vector3 = f.cross(Vector3.UP).normalized()
			rows.append({"offset":s,"position":[p.x,p.y,p.z],"right":[r.x,r.y,r.z],"width":route.width})
		branches.append({"label":route.label,"entry":route.entry_offset,"exit":route.exit_offset,"length":route.curve.get_baked_length(),"rows":rows})
	var gates: Array=[]
	for index in data.checkpoints:
		gates.append(curve.get_closest_offset(Vector3(data.points[index][0],data.points[index][1],data.points[index][2]))/length)
	# Validate the whole avenue before it splits around the fountain, rather
	# than putting a narrow, angled gate in the middle of the fork.
	gates[2]=110.0/length
	var widths := Curve.new()
	widths.max_value=30
	var previous := -1.0
	for row in samples:
		if row.width!=previous:
			if widths.point_count>0:widths.add_point(Vector2(maxf(0,row.offset/length-.002),previous))
			widths.add_point(Vector2(row.offset/length,row.width))
			previous=row.width
	if widths.get_point_position(widths.point_count-1).x<1:widths.add_point(Vector2(1,22))
	ResourceSaver.save(widths,OUT+"widths.tres")
	FileAccess.open(OUT+"survey.json",FileAccess.WRITE).store_string(JSON.stringify({"length":length,"samples":samples,"branches":branches,"gates":gates,"fountain":data.fountain_center},"\t"))
	print("CITY_ROUTES length=",length," city outer=",exit-entry," inner=",inner.get_baked_length())
	quit()
