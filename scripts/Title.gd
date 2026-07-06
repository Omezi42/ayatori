extends Control

var settings_btn: Button
var settings_panel: PanelContainer

func _ready() -> void:
	# 1. 全体テーマ（フォントアウトラインの統一）
	var theme = Theme.new()
	theme.set_color("font_outline_color", "Label", ThemeConfig.TEXT_DARK)
	theme.set_color("font_outline_color", "Button", ThemeConfig.TEXT_DARK)
	theme.set_constant("outline_size", "Label", 12)
	theme.set_constant("outline_size", "Button", 8)
	self.theme = theme

	# 2. プライマリボタン（スタート）のスタイル
	var primary_normal = ThemeConfig.create_button_style(ThemeConfig.PRIMARY, 6)
	primary_normal.content_margin_top = 24
	primary_normal.content_margin_bottom = 24
	primary_normal.content_margin_left = 48
	primary_normal.content_margin_right = 48
	var primary_pressed = ThemeConfig.create_pressed_style(ThemeConfig.PRIMARY)
	primary_pressed.content_margin_left = 48
	primary_pressed.content_margin_right = 48
	
	var start_btn = $ButtonContainer/StartButton
	ThemeConfig.apply_button_theme(start_btn, primary_normal, primary_pressed)
	start_btn.add_theme_font_size_override("font_size", ThemeConfig.FONT_BUTTON_PRIMARY)
	start_btn.icon = load("res://assets/ic_sparkle.svg")
	start_btn.add_theme_constant_override("icon_max_width", 36)
	
	# 3. セカンダリボタン（作成・読込・ショップ）のスタイル
	var secondary_normal = ThemeConfig.create_button_style(ThemeConfig.PRIMARY_LIGHT, 4)
	secondary_normal.content_margin_left = 16
	secondary_normal.content_margin_right = 16
	secondary_normal.content_margin_top = 12
	secondary_normal.content_margin_bottom = 12
	var secondary_pressed = ThemeConfig.create_pressed_style(ThemeConfig.PRIMARY_LIGHT)
	secondary_pressed.content_margin_left = 16
	secondary_pressed.content_margin_right = 16
	secondary_pressed.content_margin_top = 16
	secondary_pressed.content_margin_bottom = 8
	
	var create_btn = $ButtonContainer/SubMenu/CreateButton
	ThemeConfig.apply_button_theme(create_btn, secondary_normal, secondary_pressed)
	create_btn.add_theme_font_size_override("font_size", 26)
	create_btn.icon = load("res://assets/ic_edit.svg")
	create_btn.add_theme_constant_override("icon_max_width", 24)
	
	var search_btn = $ButtonContainer/SubMenu/SearchButton
	ThemeConfig.apply_button_theme(search_btn, secondary_normal, secondary_pressed)
	search_btn.add_theme_font_size_override("font_size", 26)
	search_btn.icon = load("res://assets/ic_search.svg")
	search_btn.add_theme_constant_override("icon_max_width", 24)
	
	var shop_btn = $ButtonContainer/SubMenu/ShopButton
	if shop_btn:
		ThemeConfig.apply_button_theme(shop_btn, secondary_normal, secondary_pressed)
		shop_btn.add_theme_font_size_override("font_size", 26)
		shop_btn.icon = load("res://assets/ic_shop.svg")
		shop_btn.add_theme_constant_override("icon_max_width", 24)
	
	# 4. ボタンアニメーション設定
	for btn in [start_btn, create_btn, search_btn, shop_btn]:
		if btn:
			ThemeConfig.setup_button_animations(btn)
	
	# 5. シグナルの接続
	start_btn.pressed.connect(_on_start_pressed)
	create_btn.pressed.connect(_on_create_pressed)
	search_btn.pressed.connect(_on_search_pressed)
	if shop_btn:
		shop_btn.pressed.connect(_on_shop_pressed)
	
	if GameSave:
		GameSave.customization_changed.connect(_update_bg_color)
	_update_bg_color()
	
	# 6. 設定ボタン（右下に控えめに配置）
	_setup_settings_corner()
	
	# 7. ロゴのアニメーション（ふわふわ浮遊させる）
	var logo = $LogoContainer
	logo.pivot_offset = logo.size / 2.0
	var tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(logo, "position:y", logo.position.y - 10, 1.5)
	tween.tween_property(logo, "position:y", logo.position.y + 10, 1.5)
	
	# 8. 累計星表示 (SVGアイコン使用)
	if GameSave and GameSave.total_stars > 0:
		var stars_box = ThemeConfig.create_icon_label("res://assets/ic_star.svg", str(GameSave.total_stars), ThemeConfig.FONT_BODY, 24, ThemeConfig.STAR_GOLD)
		stars_box.name = "StarsBox"
		stars_box.alignment = BoxContainer.ALIGNMENT_CENTER
		var l = stars_box.get_child(1) as Label
		if l:
			l.add_theme_constant_override("outline_size", 6)
			l.add_theme_color_override("font_outline_color", ThemeConfig.STAR_OUTLINE)
		$ButtonContainer.add_child(stars_box)

func _setup_settings_corner() -> void:
	# 設定ボタン（右下隅に小さく配置）
	var settings_hbox = HBoxContainer.new()
	settings_hbox.position = Vector2(1180, 660)
	settings_hbox.add_theme_constant_override("separation", ThemeConfig.SPACING_SM)
	
	settings_btn = Button.new()
	settings_btn.text = ""
	settings_btn.custom_minimum_size = ThemeConfig.MIN_TAP_SIZE
	var gear_tex = load("res://resources/gear_icon.svg")
	if gear_tex:
		settings_btn.icon = gear_tex
		settings_btn.add_theme_constant_override("icon_max_width", 28)
	
	var btn_normal = ThemeConfig.create_button_style(ThemeConfig.PRIMARY, 4, ThemeConfig.RADIUS_XL)
	btn_normal.content_margin_left = 12
	btn_normal.content_margin_right = 12
	btn_normal.content_margin_top = 8
	btn_normal.content_margin_bottom = 8
	var btn_pressed = btn_normal.duplicate()
	btn_pressed.content_margin_top += 4
	btn_pressed.content_margin_bottom -= 4
	ThemeConfig.apply_icon_button_theme(settings_btn, btn_normal, btn_pressed)
	ThemeConfig.setup_button_animations(settings_btn)
	
	settings_hbox.add_child(settings_btn)
	add_child(settings_hbox)
	
	# 設定パネル（設定ボタンの上にポップアップ）
	settings_panel = PanelContainer.new()
	settings_panel.visible = false
	settings_panel.custom_minimum_size = Vector2(300, 0)
	settings_panel.position = Vector2(900, 380)
	settings_panel.add_theme_stylebox_override("panel", ThemeConfig.create_settings_panel_style())
	
	var set_vbox = VBoxContainer.new()
	set_vbox.add_theme_constant_override("separation", ThemeConfig.SPACING_SM)
	settings_panel.add_child(set_vbox)
	
	# 音量 (SVGアイコン使用)
	var vol_label = ThemeConfig.create_icon_label("res://assets/ic_volume.svg", "おんりょう", ThemeConfig.FONT_BODY, 24, ThemeConfig.TEXT_DARK)
	set_vbox.add_child(vol_label)
	
	var vol_slider = HSlider.new()
	var master_bus = AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		vol_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus)) * 100.0
	else:
		vol_slider.value = 50
	vol_slider.value_changed.connect(func(val):
		var bus_idx = AudioServer.get_bus_index("Master")
		if bus_idx >= 0:
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val / 100.0))
	)
	set_vbox.add_child(vol_slider)
	ThemeConfig.apply_slider_theme(vol_slider)
	
	# テーマ (SVGアイコン使用)
	var theme_label = ThemeConfig.create_icon_label("res://assets/ic_palette.svg", "テーマ", ThemeConfig.FONT_BODY, 24, ThemeConfig.TEXT_DARK)
	set_vbox.add_child(theme_label)
	
	var cur_t = GameSave.current_theme if GameSave else 0
	var theme_btns = ThemeConfig.create_theme_select_buttons(cur_t, func(idx):
		if GameSave:
			GameSave.current_theme = idx
			GameSave.apply_theme()
			GameSave.save_data()
	)
	set_vbox.add_child(theme_btns)
	
	var sep = HSeparator.new()
	set_vbox.add_child(sep)
	
	# 今日のお題（設定内に統合・SVGアイコン使用）
	var daily_btn = Button.new()
	daily_btn.text = " 今日のお題"
	daily_btn.icon = load("res://assets/ic_calendar.svg")
	daily_btn.add_theme_constant_override("icon_max_width", 24)
	daily_btn.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	daily_btn.custom_minimum_size = ThemeConfig.MIN_TAP_SIZE
	var daily_normal = ThemeConfig.create_button_style(ThemeConfig.ACCENT, 4)
	daily_normal.content_margin_left = 16
	daily_normal.content_margin_right = 16
	daily_normal.content_margin_top = 8
	daily_normal.content_margin_bottom = 8
	var daily_pressed = daily_normal.duplicate()
	daily_pressed.content_margin_top += 4
	daily_pressed.content_margin_bottom -= 4
	ThemeConfig.apply_button_theme(daily_btn, daily_normal, daily_pressed)
	daily_btn.add_theme_color_override("font_outline_color", Color(0.3, 0.6, 0.7, 0.8))
	daily_btn.pressed.connect(_on_daily_pressed)
	ThemeConfig.setup_button_animations(daily_btn)
	set_vbox.add_child(daily_btn)
	

	
	add_child(settings_panel)
	
	settings_btn.pressed.connect(func(): 
		settings_panel.visible = !settings_panel.visible
	)



func _on_start_pressed() -> void:
	if FirebaseManager.has_meta("ugc_target"):
		FirebaseManager.remove_meta("ugc_target")
	_transition_to_scene("res://scenes/LevelSelect.tscn")

func _on_create_pressed() -> void:
	_transition_to_scene("res://scenes/LevelEditor.tscn")

func _transition_to_scene(path: String) -> void:
	var tr = get_node_or_null("TransitionRect")
	if tr:
		tr.show()
		tr.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(tr, "modulate:a", 1.0, 0.4)
		tw.tween_callback(func(): get_tree().change_scene_to_file(path))
	else:
		get_tree().change_scene_to_file(path)

func _on_search_pressed() -> void:
	_transition_to_scene("res://scenes/LevelBrowser.tscn")

func _on_shop_pressed() -> void:
	var shop_scene = load("res://scenes/Shop.tscn")
	if shop_scene:
		var shop_instance = shop_scene.instantiate()
		add_child(shop_instance)

func apply_theme_colors() -> void:
	_update_bg_color()
	
	if theme:
		theme.set_color("font_outline_color", "Label", ThemeConfig.TEXT_DARK)
		theme.set_color("font_outline_color", "Button", ThemeConfig.TEXT_DARK)
	
	var primary_normal = ThemeConfig.create_button_style(ThemeConfig.PRIMARY, 6)
	primary_normal.content_margin_top = 24
	primary_normal.content_margin_bottom = 24
	primary_normal.content_margin_left = 48
	primary_normal.content_margin_right = 48
	var primary_pressed = ThemeConfig.create_pressed_style(ThemeConfig.PRIMARY)
	primary_pressed.content_margin_left = 48
	primary_pressed.content_margin_right = 48
	
	var start_btn = $ButtonContainer/StartButton
	if start_btn:
		ThemeConfig.apply_button_theme(start_btn, primary_normal, primary_pressed)
		
	var secondary_normal = ThemeConfig.create_button_style(ThemeConfig.PRIMARY_LIGHT, 4)
	secondary_normal.content_margin_left = 16
	secondary_normal.content_margin_right = 16
	secondary_normal.content_margin_top = 12
	secondary_normal.content_margin_bottom = 12
	var secondary_pressed = ThemeConfig.create_pressed_style(ThemeConfig.PRIMARY_LIGHT)
	secondary_pressed.content_margin_left = 16
	secondary_pressed.content_margin_right = 16
	secondary_pressed.content_margin_top = 16
	secondary_pressed.content_margin_bottom = 8
	
	for btn_name in ["CreateButton", "SearchButton", "ShopButton"]:
		var btn = $ButtonContainer/SubMenu.get_node_or_null(btn_name) as Button
		if btn:
			ThemeConfig.apply_button_theme(btn, secondary_normal, secondary_pressed)
			
	if settings_btn:
		var btn_normal = ThemeConfig.create_button_style(ThemeConfig.PRIMARY, 4, ThemeConfig.RADIUS_XL)
		btn_normal.content_margin_left = 12
		btn_normal.content_margin_right = 12
		btn_normal.content_margin_top = 8
		btn_normal.content_margin_bottom = 8
		var btn_pressed = btn_normal.duplicate()
		btn_pressed.content_margin_top += 4
		btn_pressed.content_margin_bottom -= 4
		ThemeConfig.apply_icon_button_theme(settings_btn, btn_normal, btn_pressed)
		
	if settings_panel:
		ThemeConfig.update_settings_panel_colors(settings_panel, GameSave.current_theme if GameSave else 0)
		
	var stars_box = $ButtonContainer.get_node_or_null("StarsBox")
	if stars_box:
		var l = stars_box.get_child(1) as Label
		if l:
			l.add_theme_color_override("font_outline_color", ThemeConfig.STAR_OUTLINE)

func _update_bg_color() -> void:
	var bg = get_node_or_null("Background")
	if bg and bg is TextureRect and bg.texture is GradientTexture2D:
		var grad = bg.texture.gradient
		if grad:
			var col = GameSave.get_current_bg_color()
			grad.set_color(0, col)
			grad.set_color(1, col.darkened(0.08))
	elif bg and bg is ColorRect:
		bg.color = GameSave.get_current_bg_color()

func _on_daily_pressed() -> void:
	var date_str = Time.get_date_string_from_system()
	var string_mgr = preload("res://scripts/StringManager.gd").new()
	
	# 既存の通常ステージ全33種の正規化キーを収集して禁止セットを作成
	var forbidden_keys = {}
	var level_mgr = LevelManager.new()
	level_mgr.create_default_levels()
	for ld in level_mgr.level_data_list:
		forbidden_keys[string_mgr._get_canonical_key(ld.target_sequence)] = true
		
	# 日付ハッシュをシードにして、完全ランダムかつ既存にない問題・適切な難易度を生成
	var rng = RandomNumberGenerator.new()
	rng.seed = date_str.hash()
	
	var target: Array[int] = []
	var optimal_moves = -1
	var layout_id = rng.randi_range(0, 2)
	var initial_seq: Array[int] = [0, 4, 5, 9]
	
	var attempts = 0
	while attempts < 500:
		attempts += 1
		var size = rng.randi_range(4, 7)
		var fingers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
		# シャッフル
		for i in range(fingers.size() - 1, 0, -1):
			var j = rng.randi_range(0, i)
			var tmp = fingers[i]
			fingers[i] = fingers[j]
			fingers[j] = tmp
			
		var candidate: Array[int] = []
		for i in range(size):
			candidate.append(fingers[i])
			
		var norm_key = string_mgr._get_canonical_key(candidate)
		if forbidden_keys.has(norm_key):
			continue
			
		var moves = string_mgr.calculate_optimal_moves_count(initial_seq, candidate)
		if moves >= 4 and moves <= 8:
			target = candidate
			optimal_moves = moves
			break
			
	# もし万が一見つからなければフォールバック生成
	if target.is_empty():
		target = [0, 2, 5, 7, 8]
		optimal_moves = 5
	
	FirebaseManager.set_meta("ugc_target", target)
	FirebaseManager.set_meta("ugc_layout_id", layout_id)
	FirebaseManager.set_meta("ugc_optimal_moves", optimal_moves)
	FirebaseManager.set_meta("is_daily", true)
	FirebaseManager.set_meta("daily_date", date_str)
	FirebaseManager.set_meta("daily_name", "今日のお題")
	
	_transition_to_scene("res://scenes/Main.tscn")

