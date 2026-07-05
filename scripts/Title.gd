extends Control

func _ready() -> void:
	# Setup styling for start button
	var btn = $StartButton
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.98, 0.7, 0.8, 1.0)
	btn_style.corner_radius_top_left = 32
	btn_style.corner_radius_top_right = 32
	btn_style.corner_radius_bottom_left = 32
	btn_style.corner_radius_bottom_right = 32
	btn_style.shadow_color = Color(0.9, 0.4, 0.6, 0.5)
	btn_style.shadow_size = 8
	btn_style.content_margin_top = 20
	btn_style.content_margin_bottom = 20
	btn_style.content_margin_left = 60
	btn_style.content_margin_right = 60
	
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(1.0, 0.8, 0.9, 1.0)
	
	btn.add_theme_stylebox_override("normal", btn_style)
	btn.add_theme_stylebox_override("hover", btn_hover)
	btn.add_theme_stylebox_override("pressed", btn_style)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_constant_override("outline_size", 4)
	btn.add_theme_color_override("font_outline_color", Color(0.9, 0.4, 0.6, 0.8))
	
	btn.pivot_offset = btn.size / 2.0
	btn.mouse_entered.connect(func(): _animate_button(btn, Vector2(1.1, 1.1)))
	btn.mouse_exited.connect(func(): _animate_button(btn, Vector2(1.0, 1.0)))
	btn.pressed.connect(_on_start_pressed)
	
	# Title animation
	var title = $TitleLabel
	title.pivot_offset = title.size / 2.0
	var tween = create_tween().set_loops()
	tween.tween_property(title, "scale", Vector2(1.05, 1.05), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(title, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _animate_button(btn: Button, target_scale: Vector2) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", target_scale, 0.3)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
