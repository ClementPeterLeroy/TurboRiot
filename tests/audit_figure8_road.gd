extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
    var world := TrackRegistry.get_definition(&"figure_8").instantiate_race()
    world.managed=true
    root.add_child(world)
    var t := world.get_node("Track") as TrackBuilder
    var length := t.curve.get_baked_length()
    var max_grade := 0.0
    var min_radius := INF
    var samples: Array[Dictionary]=[]
    for i in ceili(length*2):
        var offset: float=length*i/ceili(length*2)
        var p := t.sample_center(offset)
        var f := t.sample_forward(offset)
        max_grade=maxf(max_grade,absf(f.y)/Vector2(f.x,f.z).length())
        var a := t.sample_forward(fposmod(offset-.5,length))
        var b := t.sample_forward(fposmod(offset+.5,length))
        var angle := absf(Vector2(a.x,a.z).angle_to(Vector2(b.x,b.z)))
        if angle>.00001:min_radius=minf(min_radius,1.0/angle)
        samples.append({"offset":offset,"position":[p.x,p.y,p.z]})
    var points: Array[Dictionary]=[]
    for i in t.curve.point_count:
        var p := t.curve.get_point_position(i)
        points.append({"position":[p.x,p.y,p.z],"offset":t.curve.get_closest_offset(p)})
    var prefix := "figure8_road_before"
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--prefix="):prefix=arg.get_slice("=",1)
    var result := {"length":length,"max_grade":max_grade,"min_radius":min_radius,"width":t.road_width,"vertices":t.road_vertices.size(),"points":points,"samples":samples}
    FileAccess.open("res://artifacts/%s.json"%prefix,FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
    print("ROAD_AUDIT length=",length," max_grade=",max_grade," radius=",min_radius)
    world.queue_free()
    await process_frame
    quit()
