extends SceneTree
## Native menu captures; source curves are loaded through the actual application.
func _initialize(): run.call_deferred()
func run():
 var app=load("res://scenes/app.tscn").instantiate()
 app.settings.path="res://.godot/gallery_preview.cfg"
 app.auto_pause_on_focus_loss=false
 root.add_child(app)
 for row in [[1920,1080,1.0],[1280,720,1.0],[960,540,1.0],[1024,768,1.25]]:
  app.settings.resolution=Vector2i(row[0],row[1])
  app.settings.ui_scale=row[2]
  app.settings.vsync=false
  app.settings.apply_display(root)
  var setup=RaceSetup.new()
  setup.circuit_id=&"figure_8"
  app.show_circuits(setup)
  for i in 15: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://artifacts/v061_gallery_%d_%d_%s.png"%[row[0],row[1],str(row[2])])
  print("GALLERY ",row," card ",app.menu.gallery.cards[0].get_global_rect())
 app.queue_free()
 await process_frame
 quit()
