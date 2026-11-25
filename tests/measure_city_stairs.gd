extends SceneTree
func _initialize():run.call_deferred()
func run():
 var reports=[]
 for mask in [0,1]:
  var w=TrackRegistry.get_definition(&"delfino_square_ds").instantiate_race()
  w.managed=true
  w.get_node("Items").enabled=false
  var race=w.get_node("RaceManager")
  race.ai_only=true
  race.opponent_count=0
  root.add_child(w)
  race.start_race()
  race.set_physics_process(false)
  race.session.advance(3)
  var t=race.track
  var branch=t.route_branches[0]
  var kart=race.kart
  var driver=kart.input_provider
  var line=RacingLine.new()
  line.build(t,mask,false)
  driver.line=line
  var offset=line.from_canonical(branch.entry_offset-20)
  var forward=line.point_at(offset+.2)-line.point_at(offset-.2)
  forward.y=0
  kart.safe_spawn=Transform3D(Basis.looking_at(forward.normalized()),line.point_at(offset)+Vector3.UP*.65)
  kart.reset_to_spawn()
  driver.validated_offset=offset-10
  driver.expected_offset=line.from_canonical(branch.exit_offset+50)
  for i in 35:await physics_frame
  kart.velocity=forward.normalized()*17
  var elapsed=0.0
  var started=false
  var completed=false
  for i in 2000:
   await physics_frame
   var progress=line.routes.to_canonical(driver.current_offset)
   if progress>=branch.entry_offset-12:started=true
   if started:elapsed+=1.0/60
   if started and progress>=branch.exit_offset+12:
    completed=true
    break
  var report={"mask":mask,"seconds":elapsed,"completed":completed,"recoveries":race.competitors[0].recoveries}
  reports.append(report)
  print("CITY_STAIRS ",JSON.stringify(report))
  w.queue_free()
  await process_frame
 FileAccess.open("res://artifacts/v061_city_stair_times.json",FileAccess.WRITE).store_string(JSON.stringify(reports,"\t"))
 quit(0 if reports[0].completed and reports[1].completed else 1)
