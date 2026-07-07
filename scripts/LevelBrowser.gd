extends Control

@onready var list_vbox = $VBoxContainer/ScrollContainer/ListVBox
@onready var search_input = $VBoxContainer/SearchHBox/SearchInput
@onready var sort_option = $VBoxContainer/SearchHBox/SortOption
@onready var loading_label = $LoadingLabel

func _ready() -> void:
	if GameSave:
		GameSave.customization_changed.connect(apply_theme_colors)
	
	# UIセットアップ
	sort_option.add_item("新着順")
	sort_option.add_item("人気順")
	sort_option.add_item("いいね順")
	
	var back_btn = $VBoxContainer/HeaderHBox/BackButton
	var create_btn = $VBoxContainer/HeaderHBox/CreateButton
	var search_btn = $VBoxContainer/SearchHBox/SearchButton
	
	back_btn.pressed.connect(_on_back_pressed)
	create_btn.pressed.connect(_on_create_pressed)
	search_btn.pressed.connect(_on_search_pressed)
	
	if GameSave and GameSave.has_method("add_settings_to"):
		GameSave.add_settings_to(self)
	
	FirebaseManager.levels_fetched.connect(_on_levels_fetched)
	FirebaseManager.fetch_failed.connect(_on_fetch_failed)
	
	FirebaseManager.load_completed.connect(_on_level_loaded)
	FirebaseManager.load_failed.connect(_on_load_failed)
	
	_fetch_data()
	apply_theme_colors()

func apply_theme_colors() -> void:
	var bg_rect = get_node_or_null("Background")
	if bg_rect and bg_rect is ColorRect:
		bg_rect.color = GameSave.get_current_bg_color()
	var hand_bg = get_node_or_null("HandBackground")
	if hand_bg and hand_bg.has_method("queue_redraw"):
		hand_bg.queue_redraw()
	
	# ボタンスタイル適用
	var back_btn = $VBoxContainer/HeaderHBox/BackButton
	var create_btn = $VBoxContainer/HeaderHBox/CreateButton
	var search_btn = $VBoxContainer/SearchHBox/SearchButton
	
	var btn_normal = ThemeConfig.create_button_style(ThemeConfig.PRIMARY, 4, ThemeConfig.RADIUS_LG)
	btn_normal.content_margin_left = 16
	btn_normal.content_margin_right = 16
	btn_normal.content_margin_top = 8
	btn_normal.content_margin_bottom = 8
	var btn_pressed = btn_normal.duplicate()
	btn_pressed.content_margin_top += 4
	btn_pressed.content_margin_bottom -= 4
	
	var sec_normal = ThemeConfig.create_button_style(ThemeConfig.PRIMARY_LIGHT, 4, ThemeConfig.RADIUS_LG)
	sec_normal.content_margin_left = 16
	sec_normal.content_margin_right = 16
	sec_normal.content_margin_top = 8
	sec_normal.content_margin_bottom = 8
	var sec_pressed = sec_normal.duplicate()
	sec_pressed.content_margin_top += 4
	sec_pressed.content_margin_bottom -= 4
	
	for btn in [back_btn, create_btn]:
		ThemeConfig.apply_button_theme(btn, sec_normal, sec_pressed)
		ThemeConfig.setup_button_animations(btn)
		
	ThemeConfig.apply_button_theme(search_btn, btn_normal, btn_pressed)
	ThemeConfig.setup_button_animations(search_btn)
	
	if search_input:
		ThemeConfig.apply_line_edit_theme(search_input)
	if sort_option:
		ThemeConfig.apply_option_button_theme(sort_option, sec_normal, sec_pressed)
		ThemeConfig.setup_button_animations(sort_option)
	
	# リスト内のレベルカードのスタイル更新
	if list_vbox:
		for card in list_vbox.get_children():
			if card is PanelContainer:
				card.add_theme_stylebox_override("panel", ThemeConfig.create_panel_style(ThemeConfig.BG_WHITE, ThemeConfig.RADIUS_MD, 4))
				for gc in card.get_children():
					if gc is HBoxContainer:
						for box_child in gc.get_children():
							if box_child is VBoxContainer:
								for lbl in box_child.get_children():
									if lbl is Label and lbl.name != "MetaLabel":
										lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
									elif lbl is Label:
										lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_MID)
									elif lbl is Button:
										ThemeConfig.apply_button_theme(lbl, btn_normal, btn_pressed)

func _update_bg_color() -> void:
	apply_theme_colors()

func _fetch_data() -> void:
	loading_label.text = "読込中..."
	loading_label.show()
	for child in list_vbox.get_children():
		child.queue_free()
		
	var sort_type = "newest"
	if sort_option.selected == 1:
		sort_type = "popular"
	elif sort_option.selected == 2:
		sort_type = "likes"
		
	FirebaseManager.fetch_levels(sort_type, search_input.text.strip_edges())

func _on_search_pressed() -> void:
	_fetch_data()

func _on_levels_fetched(levels: Array) -> void:
	loading_label.hide()
	for level in levels:
		var panel = PanelContainer.new()
		panel.add_theme_stylebox_override("panel", ThemeConfig.create_panel_style(ThemeConfig.BG_WHITE, ThemeConfig.RADIUS_MD, 4))
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", ThemeConfig.SPACING_SM)
		panel.add_child(hbox)
		
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_vbox)
		
		var title_label = Label.new()
		title_label.text = level["title"]
		title_label.add_theme_font_size_override("font_size", 28)
		title_label.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
		info_vbox.add_child(title_label)
		
		var meta_label = Label.new()
		meta_label.text = "コード: " + level["code"] + "  |  プレイ数: " + str(level["play_count"])
		meta_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_CAPTION)
		meta_label.add_theme_color_override("font_color", ThemeConfig.TEXT_MID)
		info_vbox.add_child(meta_label)
		
		if level.has("target_sequence") and level.has("layout_id"):
			var thumb_control = Control.new()
			thumb_control.custom_minimum_size = Vector2(150, 100)
			info_vbox.add_child(thumb_control)
			_create_thumbnail(level["target_sequence"], level["layout_id"], thumb_control)
		
		var like_vbox = VBoxContainer.new()
		like_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		var like_btn = Button.new()
		like_btn.custom_minimum_size = Vector2(100, ThemeConfig.MIN_TAP_SIZE.y)
		like_btn.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
		
		var current_likes = level.get("likes", 0)
		var is_liked = GameSave.has_liked(level["code"])
		
		if is_liked:
			like_btn.text = " " + str(current_likes)
			like_btn.icon = load("res://assets/ic_heart.svg")
			like_btn.add_theme_constant_override("icon_max_width", 20)
			like_btn.disabled = true
			like_btn.modulate = Color(1.0, 0.4, 0.6)
		else:
			like_btn.text = " " + str(current_likes)
			like_btn.icon = load("res://assets/ic_heart_empty.svg")
			like_btn.add_theme_constant_override("icon_max_width", 20)
			like_btn.pressed.connect(func():
				like_btn.disabled = true
				like_btn.text = " " + str(current_likes + 1)
				like_btn.icon = load("res://assets/ic_heart.svg")
				like_btn.modulate = Color(1.0, 0.4, 0.6)
				GameSave.add_like_record(level["code"])
				FirebaseManager.increment_like(level["code"])
			)
			
		like_vbox.add_child(like_btn)
		hbox.add_child(like_vbox)
		
		var play_btn = Button.new()
		play_btn.text = " 遊ぶ "
		play_btn.custom_minimum_size = Vector2(100, ThemeConfig.MIN_TAP_SIZE.y)
		play_btn.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
		var play_normal = ThemeConfig.create_button_style(ThemeConfig.PRIMARY, 4, ThemeConfig.RADIUS_LG)
		play_normal.content_margin_left = 16
		play_normal.content_margin_right = 16
		play_normal.content_margin_top = 8
		play_normal.content_margin_bottom = 8
		var play_pressed = play_normal.duplicate()
		play_pressed.content_margin_top += 4
		play_pressed.content_margin_bottom -= 4
		ThemeConfig.apply_button_theme(play_btn, play_normal, play_pressed)
		ThemeConfig.setup_button_animations(play_btn)
		play_btn.pressed.connect(func(): _play_level(level["code"], play_btn))
		
		var play_vbox = VBoxContainer.new()
		play_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		play_vbox.add_child(play_btn)
		hbox.add_child(play_vbox)
		
		list_vbox.add_child(panel)
		
	if levels.size() == 0:
		loading_label.text = "お題が見つかりませんでした"
		loading_label.show()

func _on_fetch_failed(err: String) -> void:
	loading_label.text = "エラー: " + err
	loading_label.show()

func _play_level(code: String, btn: Button) -> void:
	btn.text = "読込中"
	btn.disabled = true
	FirebaseManager.increment_play_count(code)
	FirebaseManager.load_level(code)

func _on_level_loaded(target_sequence: Array, layout_id: int, title: String, active_rules: Dictionary = {}) -> void:
	FirebaseManager.set_meta("ugc_target", target_sequence)
	FirebaseManager.set_meta("ugc_layout_id", layout_id)
	FirebaseManager.set_meta("ugc_title", title)
	FirebaseManager.set_meta("ugc_active_rules", active_rules)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_load_failed(err: String) -> void:
	print("Load Failed: ", err)
	loading_label.text = "エラー: " + err
	loading_label.show()
	await get_tree().create_timer(1.5).timeout
	_fetch_data()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Title.tscn")

func _on_create_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelEditor.tscn")

func _create_thumbnail(sequence: Array, layout_id: int, parent_control: Control) -> void:
	var line = Line2D.new()
	line.width = 4.0
	line.default_color = ThemeConfig.PRIMARY
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
		scale_factor = min(150.0 / (size_x + 20), 100.0 / (size_y + 20))
	
	var offset_x = (150.0 - size_x * scale_factor) / 2.0
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
