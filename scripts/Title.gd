extends Control

var settings_btn: Button
var settings_panel: PanelContainer

func _ready() -> void:
	# 1. 全体テーマ（フォントアウトラインの統一）
	var custom_theme = Theme.new()
	custom_theme.set_color("font_outline_color", "Label", Color(1, 1, 1, 0.9))
	custom_theme.set_color("font_outline_color", "Button", Color(1, 1, 1, 0.6))
	custom_theme.set_constant("outline_size", "Label", 6)
	custom_theme.set_constant("outline_size", "Button", 4)
	self.theme = custom_theme

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
	
	# 3. セカンダリボタン（作成・読込・ショップ）のリッチスタイル (商業スマホアプリ調)
	var create_btn = $ButtonContainer/SubMenu/CreateButton
	var c_norm = ThemeConfig.create_button_style(Color("#2EC4B6"), 6)
	var c_press = ThemeConfig.create_pressed_style(Color("#2EC4B6"))
	ThemeConfig.apply_button_theme(create_btn, c_norm, c_press)
	create_btn.add_theme_font_size_override("font_size", 24)
	create_btn.icon = load("res://assets/ic_edit.svg")
	create_btn.add_theme_constant_override("icon_max_width", 26)
	
	var search_btn = $ButtonContainer/SubMenu/SearchButton
	var s_norm = ThemeConfig.create_button_style(Color("#3A86FF"), 6)
	var s_press = ThemeConfig.create_pressed_style(Color("#3A86FF"))
	ThemeConfig.apply_button_theme(search_btn, s_norm, s_press)
	search_btn.add_theme_font_size_override("font_size", 24)
	search_btn.icon = load("res://assets/ic_search.svg")
	search_btn.add_theme_constant_override("icon_max_width", 26)
	
	var shop_btn = $ButtonContainer/SubMenu/ShopButton
	if shop_btn:
		var sh_norm = ThemeConfig.create_button_style(Color("#FF9F1C"), 6)
		var sh_press = ThemeConfig.create_pressed_style(Color("#FF9F1C"))
		ThemeConfig.apply_button_theme(shop_btn, sh_norm, sh_press)
		shop_btn.add_theme_font_size_override("font_size", 24)
		shop_btn.icon = load("res://assets/ic_shop.svg")
		shop_btn.add_theme_constant_override("icon_max_width", 26)
	
	# 今日のお題ボタン（メインメニュー配置）
	var daily_btn = $ButtonContainer/DailyButton
	var daily_normal = ThemeConfig.create_button_style(Color("#9B5DE5"), 8)
	var daily_pressed = ThemeConfig.create_pressed_style(Color("#9B5DE5"))
	ThemeConfig.apply_button_theme(daily_btn, daily_normal, daily_pressed)
	daily_btn.add_theme_font_size_override("font_size", 32)
	daily_btn.icon = load("res://assets/ic_calendar.svg")
	daily_btn.add_theme_constant_override("icon_max_width", 32)
	daily_btn.pressed.connect(_on_daily_pressed)
	
	# 4. ボタンアニメーション設定
	for btn in [start_btn, daily_btn, create_btn, search_btn, shop_btn]:
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
	
	if SoundManager:
		SoundManager.play_bgm("bgm_title")
	
	# 6. 設定ボタン（右下に控えめに配置）
	_setup_settings_corner()
	
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	
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

func _on_viewport_size_changed() -> void:
	if not is_inside_tree():
		return
	var screen_size = get_viewport_rect().size
	var logo_container = get_node_or_null("LogoContainer")
	var button_container = get_node_or_null("ButtonContainer")
	var sub_menu = get_node_or_null("ButtonContainer/SubMenu")
	
	if logo_container:
		var main_title = logo_container.get_node_or_null("MainTitle") as Label
		var sub_title = logo_container.get_node_or_null("SubTitle") as Label
		if main_title:
			var target_font = min(80, int(screen_size.x * 0.11))
			main_title.add_theme_font_size_override("font_size", max(36, target_font))
		if sub_title:
			var sub_font = min(36, int(screen_size.x * 0.05))
			sub_title.add_theme_font_size_override("font_size", max(18, sub_font))
			
	if sub_menu and sub_menu is HBoxContainer:
		var available_w = min(screen_size.x - (20.0 if screen_size.x < 850.0 else 48.0), 880.0)
		var btn_w = max(110.0, (available_w - 20.0) / 3.0)
		for child in sub_menu.get_children():
			if child is Button:
				child.custom_minimum_size = Vector2(btn_w, 80 if screen_size.x < 850.0 else 76)
				child.add_theme_font_size_override("font_size", max(22, min(26, int(btn_w * 0.22))))
				
	var start_btn = get_node_or_null("ButtonContainer/StartButton") as Button
	if start_btn:
		start_btn.custom_minimum_size = Vector2(min(560.0, screen_size.x - 16.0), 116 if screen_size.x < 850.0 else 104)
		start_btn.add_theme_font_size_override("font_size", 36 if screen_size.x < 850.0 else 32)
	var daily_btn = get_node_or_null("ButtonContainer/DailyButton") as Button
	if daily_btn:
		daily_btn.custom_minimum_size = Vector2(min(560.0, screen_size.x - 16.0), 88 if screen_size.x < 850.0 else 80)
		daily_btn.add_theme_font_size_override("font_size", 28 if screen_size.x < 850.0 else 26)

	var settings_hbox = get_node_or_null("SettingsCornerHBox") as Control
	if settings_hbox:
		settings_hbox.position = Vector2(screen_size.x - 80, screen_size.y - 68)
	if settings_panel:
		settings_panel.position = Vector2(max(16.0, screen_size.x - 320.0), screen_size.y - settings_panel.size.y - 80.0)

func _setup_settings_corner() -> void:
	# 設定ボタン（右下隅に小さく配置）
	var settings_hbox = HBoxContainer.new()
	settings_hbox.name = "SettingsCornerHBox"
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
	settings_panel.grow_horizontal = Control.GROW_DIRECTION_END
	settings_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	settings_panel.position = Vector2(920, 640)
	settings_panel.add_theme_stylebox_override("panel", ThemeConfig.create_settings_panel_style())
	
	var set_vbox = VBoxContainer.new()
	set_vbox.add_theme_constant_override("separation", ThemeConfig.SPACING_SM)
	settings_panel.add_child(set_vbox)
	
	# BGM音量
	var bgm_label = ThemeConfig.create_icon_label("res://assets/ic_volume.svg", "BGM", ThemeConfig.FONT_BODY, 24, ThemeConfig.TEXT_DARK)
	set_vbox.add_child(bgm_label)
	
	var bgm_slider = HSlider.new()
	bgm_slider.value = SoundManager.get_bgm_volume() if SoundManager else 80
	bgm_slider.custom_minimum_size = Vector2(200, 30)
	bgm_slider.value_changed.connect(func(val):
		if SoundManager: SoundManager.set_bgm_volume(val)
	)
	set_vbox.add_child(bgm_slider)
	ThemeConfig.apply_slider_theme(bgm_slider)
	
	# SE音量
	var se_label = ThemeConfig.create_icon_label("res://assets/ic_volume.svg", "SE", ThemeConfig.FONT_BODY, 24, ThemeConfig.TEXT_DARK)
	set_vbox.add_child(se_label)
	
	var se_slider = HSlider.new()
	se_slider.value = SoundManager.get_se_volume() if SoundManager else 80
	se_slider.custom_minimum_size = Vector2(200, 30)
	se_slider.value_changed.connect(func(val):
		if SoundManager: SoundManager.set_se_volume(val)
	)
	set_vbox.add_child(se_slider)
	ThemeConfig.apply_slider_theme(se_slider)
	
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
	
	var sep1 = HSeparator.new()
	set_vbox.add_child(sep1)
	

	
	add_child(settings_panel)
	
	settings_btn.pressed.connect(func(): 
		settings_panel.visible = !settings_panel.visible
		if SoundManager:
			if settings_panel.visible:
				SoundManager.play_se("panel_open")
			else:
				SoundManager.play_se("panel_close")
	)



func _on_start_pressed() -> void:
	if SoundManager: SoundManager.play_se("button_tap")
	if FirebaseManager.has_meta("ugc_target"):
		FirebaseManager.remove_meta("ugc_target")
	_transition_to_scene("res://scenes/LevelSelect.tscn")

func _on_create_pressed() -> void:
	if SoundManager: SoundManager.play_se("button_tap")
	_transition_to_scene("res://scenes/LevelEditor.tscn")

func _transition_to_scene(path: String) -> void:
	var t_rect = get_node_or_null("TransitionRect")
	if t_rect:
		t_rect.show()
		t_rect.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(t_rect, "modulate:a", 1.0, 0.4)
		tw.tween_callback(func(): get_tree().change_scene_to_file(path))
	else:
		get_tree().change_scene_to_file(path)

func _on_search_pressed() -> void:
	if SoundManager: SoundManager.play_se("button_tap")
	_transition_to_scene("res://scenes/LevelBrowser.tscn")

func _on_shop_pressed() -> void:
	if SoundManager: SoundManager.play_se("button_tap")
	var shop_scene = load("res://scenes/Shop.tscn")
	if shop_scene:
		var shop_instance = shop_scene.instantiate()
		add_child(shop_instance)

func apply_theme_colors() -> void:
	_update_bg_color()
	
	if theme:
		theme.set_color("font_outline_color", "Label", Color(1, 1, 1, 0.9))
		theme.set_color("font_outline_color", "Button", Color(1, 1, 1, 0.6))
	
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
			
	var daily_btn = $ButtonContainer.get_node_or_null("DailyButton") as Button
	if daily_btn:
		var daily_normal = ThemeConfig.create_button_style(ThemeConfig.ACCENT, 6)
		daily_normal.content_margin_top = 16
		daily_normal.content_margin_bottom = 16
		daily_normal.content_margin_left = 32
		daily_normal.content_margin_right = 32
		var daily_pressed = ThemeConfig.create_pressed_style(ThemeConfig.ACCENT)
		daily_pressed.content_margin_left = 32
		daily_pressed.content_margin_right = 32
		ThemeConfig.apply_button_theme(daily_btn, daily_normal, daily_pressed)
		daily_btn.add_theme_color_override("font_outline_color", Color(0.3, 0.6, 0.7, 0.8))
			
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
	if SoundManager: SoundManager.play_se("button_tap")
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
	string_mgr.layout_id = layout_id
	var initial_seq: Array[int] = [0, 4, 5, 9]
	
	var attempts = 0
	while attempts < 500:
		attempts += 1
		var rand_size = rng.randi_range(4, 7)
		var fingers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
		# シャッフル
		for i in range(fingers.size() - 1, 0, -1):
			var j = rng.randi_range(0, i)
			var tmp = fingers[i]
			fingers[i] = fingers[j]
			fingers[j] = tmp
			
		var candidate: Array[int] = []
		for i in range(rand_size):
			candidate.append(fingers[i])
			
		# 二重掛け（同じピンへの複数回掛け）をある確率で追加
		if rng.randf() < 0.6:
			var double_count = rng.randi_range(1, 2)
			for d in range(double_count):
				if candidate.size() >= 8:
					break
				var dup_val = candidate[rng.randi_range(0, candidate.size() - 1)]
				var insert_idx = rng.randi_range(0, candidate.size())
				var prev_idx = (insert_idx - 1 + candidate.size()) % candidate.size()
				var next_idx = insert_idx % candidate.size()
				if candidate[prev_idx] != dup_val and candidate[next_idx] != dup_val:
					candidate.insert(insert_idx, dup_val)
			
		var norm_key = string_mgr._get_canonical_key(candidate)
		if forbidden_keys.has(norm_key):
			continue
			
		var moves = string_mgr.calculate_optimal_moves_count(initial_seq, candidate)
		if moves >= 3 and moves <= 8:
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
