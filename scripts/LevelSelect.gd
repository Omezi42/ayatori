extends Control

@onready var grid_container = $VBoxContainer/ScrollContainer/GridContainer
@onready var back_button = $VBoxContainer/Footer/BackButton

func _ready() -> void:
	if GameSave:
		GameSave.customization_changed.connect(apply_theme_colors)
	
	# 全体テーマ設定
	var ui_theme = Theme.new()
	ui_theme.set_color("font_outline_color", "Label", ThemeConfig.TEXT_DARK)
	ui_theme.set_constant("outline_size", "Label", 8)
	self.theme = ui_theme

	# ホームボタンをヘッダーに追加
	var header = $VBoxContainer/Header
	var home_btn = Button.new()
	home_btn.name = "HomeButton"
	home_btn.text = ""
	home_btn.custom_minimum_size = ThemeConfig.MIN_TAP_SIZE
	var home_tex = load("res://assets/ic_field_farm_01_trimmed.svg")
	if home_tex:
		home_btn.icon = home_tex
		home_btn.add_theme_constant_override("icon_max_width", 28)
	home_btn.pressed.connect(_on_back_pressed)
	header.add_child(home_btn)
	header.move_child(home_btn, 0)
	
	# レベルデータの読み込み
	var level_manager = LevelManager.new()
	level_manager.create_default_levels()
	var levels = level_manager.level_data_list
	
	# ステージカードの生成
	for i in range(levels.size()):
		var card = _create_stage_card(i, levels[i])
		grid_container.add_child(card)
		
	back_button.pressed.connect(_on_back_pressed)
	
	apply_theme_colors()

func apply_theme_colors() -> void:
	var bg_rect = get_node_or_null("Background")
	if bg_rect and bg_rect is ColorRect:
		bg_rect.color = GameSave.get_current_bg_color()
	var hand_bg = get_node_or_null("HandBackground")
	if hand_bg and hand_bg.has_method("queue_redraw"):
		hand_bg.queue_redraw()
	
	# 戻るボタンのスタイル
	var back_normal = ThemeConfig.create_button_style(ThemeConfig.PRIMARY_LIGHT, 4)
	back_normal.content_margin_left = 20
	back_normal.content_margin_right = 20
	back_normal.content_margin_top = 10
	back_normal.content_margin_bottom = 10
	var back_pressed = ThemeConfig.create_pressed_style(ThemeConfig.PRIMARY_LIGHT)
	back_pressed.content_margin_left = 20
	back_pressed.content_margin_right = 20
	ThemeConfig.apply_button_theme(back_button, back_normal, back_pressed)
	back_button.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	ThemeConfig.setup_button_animations(back_button)
	
	# ホームボタンのスタイル
	var header = $VBoxContainer/Header
	var home_btn = header.get_node_or_null("HomeButton") as Button
	if home_btn:
		var home_normal = ThemeConfig.create_button_style(ThemeConfig.PRIMARY, 4, ThemeConfig.RADIUS_XL)
		home_normal.content_margin_left = 12
		home_normal.content_margin_right = 12
		home_normal.content_margin_top = 8
		home_normal.content_margin_bottom = 8
		var home_pressed = home_normal.duplicate()
		home_pressed.content_margin_top += 4
		home_pressed.content_margin_bottom -= 4
		ThemeConfig.apply_icon_button_theme(home_btn, home_normal, home_pressed)
		ThemeConfig.setup_button_animations(home_btn)
		
	# ステージカードのスタイル更新
	if grid_container:
		for card in grid_container.get_children():
			if card is PanelContainer:
				var card_style = ThemeConfig.create_panel_style(
					Color(ThemeConfig.PRIMARY.r, ThemeConfig.PRIMARY.g, ThemeConfig.PRIMARY.b, 0.92),
					ThemeConfig.RADIUS_LG,
					6
				)
				card.add_theme_stylebox_override("panel", card_style)

func _update_bg_color() -> void:
	apply_theme_colors()

func _create_stage_card(index: int, level_data: LevelData) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(240, 220)
	
	var card_style = ThemeConfig.create_panel_style(
		Color(ThemeConfig.PRIMARY.r, ThemeConfig.PRIMARY.g, ThemeConfig.PRIMARY.b, 0.92),
		ThemeConfig.RADIUS_LG,
		6
	)
	panel.add_theme_stylebox_override("panel", card_style)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", ThemeConfig.SPACING_SM)
	panel.add_child(vbox)
	
	# ステージ番号
	var num_label = Label.new()
	num_label.text = "STAGE %d" % [index + 1]
	num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_label.add_theme_font_size_override("font_size", 16)
	num_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	vbox.add_child(num_label)
	
	# サムネイル
	var thumb_control = Control.new()
	thumb_control.custom_minimum_size = Vector2(180, 100)
	vbox.add_child(thumb_control)
	if level_data.target_sequence.size() > 0:
		_create_thumbnail(level_data.target_sequence, level_data.layout_id, thumb_control)
	
	# ステージ名
	var title_label = Label.new()
	title_label.text = level_data.level_name
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	title_label.add_theme_color_override("font_color", ThemeConfig.TEXT_LIGHT)
	vbox.add_child(title_label)
	
	# 星表示
	var stars_count = 0
	if GameSave:
		stars_count = GameSave.get_level_stars(level_data.level_name)
	var stars_text = ""
	for j in range(stars_count):
		stars_text += "★"
	for j in range(3 - stars_count):
		stars_text += "☆"
		
	var stars_label = Label.new()
	stars_label.text = stars_text
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	stars_label.add_theme_color_override("font_color", ThemeConfig.STAR_GOLD)
	stars_label.add_theme_constant_override("outline_size", 4)
	stars_label.add_theme_color_override("font_outline_color", ThemeConfig.STAR_OUTLINE)
	vbox.add_child(stars_label)
	
	# 透明なクリッカブルボタン（カード全体をタップ可能に）
	var btn = Button.new()
	var empty_style = StyleBoxEmpty.new()
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0, 0, 0, 0.15)
	pressed_style.corner_radius_top_left = ThemeConfig.RADIUS_LG
	pressed_style.corner_radius_top_right = ThemeConfig.RADIUS_LG
	pressed_style.corner_radius_bottom_left = ThemeConfig.RADIUS_LG
	pressed_style.corner_radius_bottom_right = ThemeConfig.RADIUS_LG
	
	btn.add_theme_stylebox_override("normal", empty_style)
	btn.add_theme_stylebox_override("hover", empty_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_stylebox_override("focus", empty_style)
	btn.pressed.connect(func(): _on_level_selected(index))
	panel.add_child(btn)
	
	# ホバーアニメーション（カード浮き上がり）
	panel.mouse_entered.connect(func():
		var tw = panel.create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
		tw.tween_property(panel, "scale", Vector2(1.05, 1.05), 0.3)
	)
	panel.mouse_exited.connect(func():
		var tw = panel.create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
		tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.3)
	)
	panel.pivot_offset = panel.custom_minimum_size / 2.0
	
	return panel

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Title.tscn")

func _on_level_selected(idx: int) -> void:
	FirebaseManager.set_meta("selected_official_level", idx)
	if FirebaseManager.has_meta("ugc_target"):
		FirebaseManager.remove_meta("ugc_target")
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _create_thumbnail(sequence: Array, layout_id: int, parent_control: Control) -> void:
	var line = Line2D.new()
	line.width = 4.0
	line.default_color = Color(1, 1, 1, 0.9)
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	
	var base_positions = PinLayout.get_positions(layout_id)
	var scaled_positions = []
	
	var min_x = 9999.0
	var max_x = -9999.0
	var min_y = 9999.0
	var max_y = -9999.0
	for p in base_positions:
		if p.x < min_x: min_x = p.x
		if p.x > max_x: max_x = p.x
		if p.y < min_y: min_y = p.y
		if p.y > max_y: max_y = p.y
		
	var size_x = max_x - min_x
	var size_y = max_y - min_y
	var scale_factor = 1.0
	if size_x > 0 and size_y > 0:
		scale_factor = min(160.0 / (size_x + 20), 80.0 / (size_y + 20))
	
	var offset_x = (180.0 - size_x * scale_factor) / 2.0
	var offset_y = (100.0 - size_y * scale_factor) / 2.0
	
	for p in base_positions:
		var sp = Vector2(
			(p.x - min_x) * scale_factor + offset_x,
			(p.y - min_y) * scale_factor + offset_y
		)
		scaled_positions.append(sp)
	
	for pin_id in sequence:
		if pin_id >= 0 and pin_id < scaled_positions.size():
			line.add_point(scaled_positions[pin_id])
			
	if sequence.size() > 0:
		var first_pin = sequence[0]
		if first_pin >= 0 and first_pin < scaled_positions.size():
			line.add_point(scaled_positions[first_pin])
			
	parent_control.add_child(line)
