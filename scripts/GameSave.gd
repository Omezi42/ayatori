extends Node

var total_stars: int = 0
var current_theme: int = 0 # 0: Normal, 1: Monochrome, 2: Dark

const SAVE_PATH = "user://ayatori_save.json"

var effect_rect: ColorRect

func _ready() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	effect_rect = ColorRect.new()
	effect_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(effect_rect)
	

	
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	uniform int theme_mode = 0;
	uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
	void fragment() {
		vec4 c = texture(screen_texture, SCREEN_UV);
		if (theme_mode == 1) { // Monochrome
			float gray = dot(c.rgb, vec3(0.299, 0.587, 0.114));
			COLOR = vec4(gray, gray, gray, c.a);
		} else if (theme_mode == 2) { // Dark
			// 少し青みがかったダークモード（単純な反転ではない）
			vec3 dark = vec3(c.r * 0.3 + 0.1, c.g * 0.3 + 0.1, c.b * 0.4 + 0.2);
			COLOR = vec4(dark, c.a);
		} else {
			COLOR = c;
		}
	}
	"""
	var mat = ShaderMaterial.new()
	mat.shader = shader
	effect_rect.material = mat
	
	load_data()
	apply_theme()

func save_data() -> void:
	var data = {
		"total_stars": total_stars,
		"current_theme": current_theme
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			var json = JSON.parse_string(text)
			if json:
				if json.has("total_stars"): total_stars = json["total_stars"]
				if json.has("current_theme"): current_theme = json["current_theme"]

func add_stars(amount: int) -> void:
	total_stars += amount
	save_data()

func apply_theme() -> void:
	if effect_rect and effect_rect.material:
		effect_rect.material.set_shader_parameter("theme_mode", current_theme)

func add_settings_to(target: Node) -> void:
	var settings_panel = PanelContainer.new()
	settings_panel.visible = false
	settings_panel.custom_minimum_size = Vector2(300, 200)
	
	# Try to find a good position based on viewport
	settings_panel.position = Vector2(850, 400)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(1.0, 1.0, 1.0, 1.0)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.15)
	panel_style.shadow_size = 12
	panel_style.shadow_offset = Vector2(2, 6)
	panel_style.content_margin_left = 16
	panel_style.content_margin_right = 16
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 32
	settings_panel.add_theme_stylebox_override("panel", panel_style)
	
	var set_vbox = VBoxContainer.new()
	settings_panel.add_child(set_vbox)
	
	var vol_label = Label.new()
	vol_label.text = "音量"
	vol_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	set_vbox.add_child(vol_label)
	
	var vol_slider = HSlider.new()
	var master_bus = AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		vol_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus)) * 100.0
	else:
		vol_slider.value = 50
	vol_slider.value_changed.connect(_on_volume_changed)
	set_vbox.add_child(vol_slider)
	
	var theme_label = Label.new()
	theme_label.text = "画面テーマ"
	theme_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	set_vbox.add_child(theme_label)
	
	var theme_btn = OptionButton.new()
	theme_btn.add_item("通常")
	theme_btn.add_item("モノクロ")
	theme_btn.add_item("ダーク")
	theme_btn.selected = current_theme
	theme_btn.item_selected.connect(func(idx):
		current_theme = idx
		apply_theme()
		save_data()
	)
	set_vbox.add_child(theme_btn)
	
	target.add_child(settings_panel)
	
	var settings_btn = Button.new()
	settings_btn.text = ""
	var gear_tex = load("res://resources/gear_icon.svg")
	if gear_tex:
		settings_btn.icon = gear_tex
		settings_btn.add_theme_constant_override("icon_max_width", 32)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.92, 0.62, 0.75, 0.95)
	btn_style.corner_radius_top_left = 32
	btn_style.corner_radius_top_right = 32
	btn_style.corner_radius_bottom_left = 32
	btn_style.corner_radius_bottom_right = 32
	btn_style.shadow_color = Color(0.8, 0.35, 0.5, 0.3)
	btn_style.shadow_size = 4
	btn_style.content_margin_left = 20
	btn_style.content_margin_right = 20
	btn_style.content_margin_top = 10
	btn_style.content_margin_bottom = 10
	
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(0.96, 0.72, 0.82, 1.0)
	
	settings_btn.add_theme_stylebox_override("normal", btn_style)
	settings_btn.add_theme_stylebox_override("hover", btn_hover)
	settings_btn.add_theme_stylebox_override("pressed", btn_style)
	settings_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	settings_btn.add_theme_color_override("icon_normal_color", Color.WHITE)
	settings_btn.add_theme_color_override("icon_hover_color", Color.WHITE)
	settings_btn.add_theme_color_override("icon_pressed_color", Color.WHITE)
	
	settings_btn.position = Vector2(1150, 620) # Bottom right
	settings_btn.pressed.connect(func(): 
		settings_panel.visible = !settings_panel.visible
	)
	
	settings_btn.pivot_offset = Vector2(36, 26) # Approximate center
	settings_btn.mouse_entered.connect(func(): _animate_button(settings_btn, Vector2(1.05, 1.05)))
	settings_btn.mouse_exited.connect(func(): _animate_button(settings_btn, Vector2(1.0, 1.0)))
	settings_btn.button_down.connect(func(): _animate_button(settings_btn, Vector2(0.95, 0.95)))
	settings_btn.button_up.connect(func():
		if settings_btn.is_hovered():
			_animate_button(settings_btn, Vector2(1.05, 1.05))
		else:
			_animate_button(settings_btn, Vector2(1.0, 1.0))
	)
	
	target.add_child(settings_btn)


func _animate_button(btn: Button, target_scale: Vector2) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", target_scale, 0.3)

func _on_volume_changed(val: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val / 100.0))

