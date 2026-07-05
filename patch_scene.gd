extends SceneTree

func _init():
	var scene = load("res://scenes/Main.tscn")
	var root = scene.instantiate()
	
	# Add Particles
	var particles = CPUParticles2D.new()
	particles.name = "ClearParticles"
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 80
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(640, 10)
	particles.direction = Vector2(0, -1)
	particles.spread = 90
	particles.gravity = Vector2(0, 980)
	particles.initial_velocity_min = 400
	particles.initial_velocity_max = 800
	particles.scale_amount_min = 10
	particles.scale_amount_max = 20
	particles.position = Vector2(640, 720)
	particles.color = Color(1.0, 0.8, 0.9)
	root.add_child(particles)
	particles.owner = root
	
	# Add AudioStreamPlayer
	var audio = AudioStreamPlayer.new()
	audio.name = "ClearSound"
	root.add_child(audio)
	audio.owner = root

	var ui_manager = root.get_node("UIManager")
	
	# Create ResultPanel
	var result_panel = PanelContainer.new()
	result_panel.name = "ResultPanel"
	result_panel.visible = false
	var control = ui_manager.get_node("Control")
	control.add_child(result_panel)
	result_panel.owner = root
	result_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	result_panel.custom_minimum_size = Vector2(400, 300)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	result_panel.add_child(vbox)
	vbox.owner = root
	
	var next_btn = Button.new()
	next_btn.name = "NextButton"
	next_btn.text = "つぎへ"
	next_btn.add_theme_font_size_override("font_size", 32)
	vbox.add_child(next_btn)
	next_btn.owner = root
	
	var share_btn = Button.new()
	share_btn.name = "ResultShareButton"
	share_btn.text = "シェアする"
	share_btn.add_theme_font_size_override("font_size", 32)
	vbox.add_child(share_btn)
	share_btn.owner = root
	
	# update UIManager script path
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/Main.tscn")
	
	quit()
