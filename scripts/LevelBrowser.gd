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
	if search_input:
		search_input.text_submitted.connect(func(_t): _on_search_pressed())
		# スマホ操作時に文字を確実に書き込める専用入力ボタンを自動配置
		if ThemeConfig.is_mobile_device():
			var prompt_btn = Button.new()
			prompt_btn.name = "MobilePromptBtn"
			prompt_btn.text = " 入力"
			prompt_btn.icon = load("res://assets/ic_edit.svg")
			prompt_btn.add_theme_constant_override("icon_max_width", 22)
			prompt_btn.custom_minimum_size = Vector2(110, 56)
			prompt_btn.add_theme_font_size_override("font_size", 22)
			ThemeConfig.apply_button_theme(prompt_btn, ThemeConfig.create_button_style(ThemeConfig.PRIMARY_LIGHT, 6, ThemeConfig.RADIUS_PILL))
			ThemeConfig.setup_button_animations(prompt_btn)
			prompt_btn.pressed.connect(func():
				if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
					var res = JavaScriptBridge.eval("window.prompt('検索キーワードを入力してください', '" + search_input.text.replace("'", "\\'") + "')")
					if res != null and str(res) != "null":
						search_input.text = str(res)
						_on_search_pressed()
				else:
					search_input.grab_focus()
					if DisplayServer.has_method("virtual_keyboard_show"):
						DisplayServer.virtual_keyboard_show(search_input.text)
			)
			var search_hbox = get_node_or_null("VBoxContainer/SearchHBox")
			if search_hbox:
				search_hbox.add_child(prompt_btn)
				search_hbox.move_child(prompt_btn, search_input.get_index())
	
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	
	if GameSave and GameSave.has_method("add_settings_to"):
		GameSave.add_settings_to(self)
	
	FirebaseManager.levels_fetched.connect(_on_levels_fetched)
	FirebaseManager.fetch_failed.connect(_on_fetch_failed)
	
	FirebaseManager.load_completed.connect(_on_level_loaded)
	FirebaseManager.load_failed.connect(_on_load_failed)
	
	if SoundManager:
		SoundManager.play_bgm("bgm_levelselect")
	_fetch_data()
	apply_theme_colors()

func apply_theme_colors() -> void:
	var bg_rect = get_node_or_null("Background")
	if bg_rect and bg_rect is ColorRect:
		bg_rect.color = GameSave.get_current_bg_color()
	var hand_bg = get_node_or_null("HandBackground")
	if hand_bg and hand_bg.has_method("queue_redraw"):
		hand_bg.queue_redraw()
	
	# ボタンスタイル適用 (横画面・スマホ両対応の大判3Dカプセル仕様)
	var back_btn = $VBoxContainer/HeaderHBox/BackButton
	var create_btn = $VBoxContainer/HeaderHBox/CreateButton
	var search_btn = $VBoxContainer/SearchHBox/SearchButton
	
	var btn_normal = ThemeConfig.create_button_style(ThemeConfig.PRIMARY, 6, ThemeConfig.RADIUS_PILL)
	btn_normal.content_margin_left = 20
	btn_normal.content_margin_right = 20
	btn_normal.content_margin_top = 10
	btn_normal.content_margin_bottom = 10
	var btn_pressed = ThemeConfig.create_pressed_style(ThemeConfig.PRIMARY, ThemeConfig.RADIUS_PILL)
	
	var sec_normal = ThemeConfig.create_button_style(ThemeConfig.PRIMARY_LIGHT, 6, ThemeConfig.RADIUS_PILL)
	sec_normal.content_margin_left = 20
	sec_normal.content_margin_right = 20
	sec_normal.content_margin_top = 10
	sec_normal.content_margin_bottom = 10
	var sec_pressed = ThemeConfig.create_pressed_style(ThemeConfig.PRIMARY_LIGHT, ThemeConfig.RADIUS_PILL)
	
	for btn in [back_btn, create_btn]:
		ThemeConfig.apply_button_theme(btn, sec_normal, sec_pressed)
		btn.custom_minimum_size = Vector2(130, 52)
		btn.add_theme_font_size_override("font_size", 22)
		ThemeConfig.setup_button_animations(btn)
		
	ThemeConfig.apply_button_theme(search_btn, btn_normal, btn_pressed)
	search_btn.custom_minimum_size = Vector2(130, 52)
	search_btn.add_theme_font_size_override("font_size", 22)
	ThemeConfig.setup_button_animations(search_btn)
	
	if search_input:
		ThemeConfig.apply_line_edit_theme(search_input)
	if sort_option:
		ThemeConfig.apply_option_button_theme(sort_option, sec_normal, sec_pressed)
		sort_option.custom_minimum_size = Vector2(150, 52)
		ThemeConfig.setup_button_animations(sort_option)
	
	# リスト内のレベルカードのスタイル更新
	if list_vbox:
		for card in list_vbox.get_children():
			if card is PanelContainer:
				card.add_theme_stylebox_override("panel", ThemeConfig.create_mobile_card_style(ThemeConfig.BG_WHITE, ThemeConfig.RADIUS_XL))
				for gc in card.get_children():
					if gc is HBoxContainer or gc is VBoxContainer:
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

func _on_viewport_size_changed() -> void:
	if not is_inside_tree():
		return
	var screen_size = get_viewport_rect().size
	var search_hbox = get_node_or_null("VBoxContainer/SearchHBox") as Container
	var header_hbox = get_node_or_null("VBoxContainer/HeaderHBox") as Container
	
	if header_hbox:
		var title_lbl = header_hbox.get_node_or_null("TitleLabel") as Label
		if title_lbl:
			title_lbl.add_theme_font_size_override("font_size", max(28, min(48, int(screen_size.x * 0.06))))
	
	if search_hbox and search_input:
		if screen_size.x < 650.0:
			search_input.custom_minimum_size = Vector2(0, 60)
		else:
			search_input.custom_minimum_size = Vector2(0, 52)

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
		panel.mouse_filter = Control.MOUSE_FILTER_PASS
		panel.add_theme_stylebox_override("panel", ThemeConfig.create_mobile_card_style(ThemeConfig.BG_WHITE, ThemeConfig.RADIUS_XL))
		
		var is_narrow = get_viewport_rect().size.x < 680.0
		var card_box: Container = VBoxContainer.new() if is_narrow else HBoxContainer.new()
		card_box.add_theme_constant_override("separation", ThemeConfig.SPACING_MD)
		panel.add_child(card_box)
		
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 8)
		card_box.add_child(info_vbox)
		
		var title_label = Label.new()
		title_label.text = level["title"]
		title_label.add_theme_font_size_override("font_size", 30 if is_narrow else 28)
		title_label.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
		title_label.add_theme_constant_override("outline_size", 4)
		title_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.8))
		info_vbox.add_child(title_label)
		
		var meta_label = Label.new()
		meta_label.text = "コード: " + level["code"] + "   プレイ数: " + str(level["play_count"])
		meta_label.add_theme_font_size_override("font_size", 18)
		meta_label.add_theme_color_override("font_color", ThemeConfig.TEXT_MID)
		info_vbox.add_child(meta_label)
		
		if level.has("target_sequence") and level.has("layout_id"):
			var thumb_control = Control.new()
			thumb_control.custom_minimum_size = Vector2(220, 130) if is_narrow else Vector2(180, 115)
			info_vbox.add_child(thumb_control)
			_create_thumbnail(level["target_sequence"], level["layout_id"], thumb_control)
		
		var btn_container: Container = HBoxContainer.new() if is_narrow else card_box
		if is_narrow:
			btn_container.add_theme_constant_override("separation", 16)
			card_box.add_child(btn_container)

		var like_vbox = VBoxContainer.new()
		if is_narrow: like_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		like_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		var like_btn = Button.new()
		like_btn.mouse_filter = Control.MOUSE_FILTER_PASS
		like_btn.custom_minimum_size = Vector2(140, 64 if is_narrow else 56)
		if is_narrow: like_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		like_btn.add_theme_font_size_override("font_size", 24 if is_narrow else 22)
		like_btn.add_theme_constant_override("icon_max_width", 24)
		
		var current_likes = level.get("likes", 0)
		var is_liked = GameSave.has_liked(level["code"])
		
		if is_liked:
			like_btn.text = " " + str(current_likes)
			like_btn.icon = load("res://assets/ic_heart.svg")
			var l_norm = ThemeConfig.create_button_style(Color("#FFB5C5"), 4)
			var l_press = ThemeConfig.create_pressed_style(Color("#FFB5C5"))
			ThemeConfig.apply_button_theme(like_btn, l_norm, l_press)
			like_btn.disabled = true
		else:
			like_btn.text = " " + str(current_likes)
			like_btn.icon = load("res://assets/ic_heart_empty.svg")
			var l_norm = ThemeConfig.create_button_style(Color("#FF5C8D"), 6)
			var l_press = ThemeConfig.create_pressed_style(Color("#FF5C8D"))
			ThemeConfig.apply_button_theme(like_btn, l_norm, l_press)
			ThemeConfig.setup_button_animations(like_btn)
			like_btn.pressed.connect(func():
				like_btn.disabled = true
				like_btn.icon = load("res://assets/ic_heart.svg")
				like_btn.text = " " + str(current_likes + 1)
				GameSave.add_like_record(level["code"])
				FirebaseManager.increment_like(level["code"])
			)
			
		like_vbox.add_child(like_btn)
		btn_container.add_child(like_vbox)
		
		var play_btn = Button.new()
		play_btn.mouse_filter = Control.MOUSE_FILTER_PASS
		play_btn.text = " 遊ぶ"
		play_btn.icon = load("res://assets/ic_star.svg")
		play_btn.add_theme_constant_override("icon_max_width", 24)
		play_btn.custom_minimum_size = Vector2(140, 64 if is_narrow else 56)
		if is_narrow: play_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		play_btn.add_theme_font_size_override("font_size", 26 if is_narrow else 24)
		var play_normal = ThemeConfig.create_button_style(Color("#FF7043"), 6, ThemeConfig.RADIUS_PILL)
		var play_pressed = ThemeConfig.create_pressed_style(Color("#FF7043"), ThemeConfig.RADIUS_PILL)
		ThemeConfig.apply_button_theme(play_btn, play_normal, play_pressed)
		ThemeConfig.setup_button_animations(play_btn)
		play_btn.pressed.connect(func(): _play_level(level["code"], play_btn))
		
		var play_vbox = VBoxContainer.new()
		if is_narrow: play_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		play_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		play_vbox.add_child(play_btn)
		btn_container.add_child(play_vbox)
		
		list_vbox.add_child(panel)
		
	if levels.size() == 0:
		loading_label.text = "お題が見つかりませんでした"
		loading_label.show()

func _on_fetch_failed(err: String) -> void:
	loading_label.text = "エラー: " + err
	loading_label.show()

func _play_level(code: String, btn: Button) -> void:
	if SoundManager: SoundManager.play_se("button_tap")
	btn.text = "読込中"
	btn.disabled = true
	FirebaseManager.increment_play_count(code)
	FirebaseManager.load_level(code)

func _on_level_loaded(target_sequence: Array, layout_id: int, title: String, active_rules: Dictionary = {}, optimal_moves: int = -1) -> void:
	if SoundManager: SoundManager.play_se("transition")
	FirebaseManager.set_meta("ugc_target", target_sequence)
	FirebaseManager.set_meta("ugc_layout_id", layout_id)
	FirebaseManager.set_meta("ugc_title", title)
	FirebaseManager.set_meta("ugc_active_rules", active_rules)
	if optimal_moves > 0:
		FirebaseManager.set_meta("ugc_optimal_moves", optimal_moves)
	elif FirebaseManager.has_meta("ugc_optimal_moves"):
		FirebaseManager.remove_meta("ugc_optimal_moves")
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_load_failed(err: String) -> void:
	print("Load Failed: ", err)
	loading_label.text = "エラー: " + err
	loading_label.show()
	await get_tree().create_timer(1.5).timeout
	_fetch_data()

func _on_back_pressed() -> void:
	if SoundManager:
		SoundManager.play_se("button_tap")
		SoundManager.play_se("transition")
	get_tree().change_scene_to_file("res://scenes/Title.tscn")

func _on_create_pressed() -> void:
	if SoundManager:
		SoundManager.play_se("button_tap")
		SoundManager.play_se("transition")
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
