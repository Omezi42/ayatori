extends Control

@onready var grid_container = $VBoxContainer/ScrollContainer/GridContainer
@onready var back_button = $VBoxContainer/Footer/BackButton

func _ready() -> void:
	if GameSave:
		GameSave.customization_changed.connect(apply_theme_colors)
	
	# 全体テーマ設定
	var ui_theme = Theme.new()
	ui_theme.set_color("font_outline_color", "Label", Color(1, 1, 1, 0.9))
	ui_theme.set_constant("outline_size", "Label", 4)
	self.theme = ui_theme

	var header = $VBoxContainer/Header
	
	# スペーサー
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	# ルール設定ボタンをヘッダーに追加
	var rules_btn = Button.new()
	rules_btn.name = "RulesButton"
	rules_btn.text = "ルール設定"
	var sec_style = ThemeConfig.create_button_style(ThemeConfig.PRIMARY_LIGHT, 6, ThemeConfig.RADIUS_PILL)
	sec_style.content_margin_left = 20
	sec_style.content_margin_right = 20
	sec_style.content_margin_top = 10
	sec_style.content_margin_bottom = 10
	var sec_pressed = ThemeConfig.create_pressed_style(ThemeConfig.PRIMARY_LIGHT, ThemeConfig.RADIUS_PILL)
	ThemeConfig.apply_button_theme(rules_btn, sec_style, sec_pressed)
	rules_btn.custom_minimum_size = Vector2(140, 56)
	rules_btn.add_theme_font_size_override("font_size", 24)
	ThemeConfig.setup_button_animations(rules_btn)
	rules_btn.pressed.connect(_on_rules_btn_pressed)
	header.add_child(rules_btn)
	
	if SoundManager:
		SoundManager.play_bgm("bgm_levelselect")
	_reload_levels_with_loading()
	
	back_button.pressed.connect(_on_back_pressed)
	apply_theme_colors()
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

func _on_viewport_size_changed() -> void:
	if not is_inside_tree() or not is_instance_valid(grid_container):
		return
	var screen_size = get_viewport_rect().size
	var available_w = screen_size.x - (16.0 if screen_size.x < 850.0 else 48.0)
	
	var card_w = 260.0 if screen_size.x >= 900.0 else 240.0
	var sep_w = 24.0 if screen_size.x >= 900.0 else 16.0
	var cols = max(1, int((available_w + sep_w) / (card_w + sep_w)))
	if grid_container.columns != cols:
		grid_container.columns = cols
		
	# スマホ画面は画面横幅いっぱい（余白極小）の大画面エルゴノミクスバナー
	var target_card_w = max(240.0, (available_w - ((cols - 1) * sep_w)) / float(cols)) if cols > 1 else available_w
	for card in grid_container.get_children():
		if card is PanelContainer:
			card.custom_minimum_size = Vector2(target_card_w, 136 if cols == 1 else 230)

func _reload_levels_with_loading() -> void:
	var loading_rect = ColorRect.new()
	loading_rect.name = "LoadingScreen"
	loading_rect.color = Color(0.1, 0.1, 0.1, 1.0)
	loading_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_rect.z_index = 100
	var loading_label = Label.new()
	loading_label.text = "Now Loading..."
	loading_label.add_theme_font_size_override("font_size", 32)
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loading_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_rect.add_child(loading_label)
	add_child(loading_rect)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	_load_levels()
	
	if loading_rect and is_instance_valid(loading_rect):
		var tw = create_tween()
		tw.tween_property(loading_rect, "modulate:a", 0.0, 0.3)
		tw.tween_callback(loading_rect.queue_free)

func _load_levels() -> void:
	# 既存のカードを削除
	for child in grid_container.get_children():
		child.queue_free()
		
	# レベルデータの読み込み
	var level_manager = LevelManager.new()
	level_manager.create_default_levels()
	var levels = level_manager.level_data_list
	
	# ON時は高度なステージだけ抽出する等のロジックを入れる（ここでは暫定的にすべて表示するか、拡張モード専用ステージを用意する）
	# （実装例：Advancedなステージフラグがあればそれでフィルタリング）
	
	for i in range(levels.size()):
		# TODO: 拡張モードのON/OFFに応じて表示するステージを分ける
		var card = _create_stage_card(i, levels[i])
		grid_container.add_child(card)
	
	apply_theme_colors()

func apply_theme_colors() -> void:
	var bg_rect = get_node_or_null("Background")
	if bg_rect and bg_rect is ColorRect:
		bg_rect.color = GameSave.get_current_bg_color()
	var hand_bg = get_node_or_null("HandBackground")
	if hand_bg and hand_bg.has_method("queue_redraw"):
		hand_bg.queue_redraw()
	
	# 戻るボタンのスタイル (横画面・スマホ両対応の大判エルゴノミクス仕様)
	var back_normal = ThemeConfig.create_button_style(ThemeConfig.PRIMARY_LIGHT, 6, ThemeConfig.RADIUS_PILL)
	back_normal.content_margin_left = 24
	back_normal.content_margin_right = 24
	back_normal.content_margin_top = 12
	back_normal.content_margin_bottom = 12
	var back_pressed = ThemeConfig.create_pressed_style(ThemeConfig.PRIMARY_LIGHT, ThemeConfig.RADIUS_PILL)
	ThemeConfig.apply_button_theme(back_button, back_normal, back_pressed)
	back_button.custom_minimum_size = Vector2(130, 56)
	back_button.add_theme_font_size_override("font_size", 24)
	ThemeConfig.setup_button_animations(back_button)
		
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
	panel.custom_minimum_size = Vector2(250, 240)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var stars_count = 0
	if GameSave:
		stars_count = GameSave.get_level_stars(level_data.level_name)
		
	var card_style = ThemeConfig.create_mobile_card_style(
		ThemeConfig.BG_WHITE if stars_count > 0 else Color("#FAFBFD"),
		ThemeConfig.RADIUS_XL
	)
	if stars_count > 0:
		card_style.border_color = ThemeConfig.STAR_GOLD
		card_style.border_width_top = 4
		card_style.border_width_bottom = 6
	else:
		card_style.border_color = ThemeConfig.PRIMARY_LIGHT
		card_style.border_width_top = 2
		card_style.border_width_bottom = 4
		
	panel.add_theme_stylebox_override("panel", card_style)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", ThemeConfig.SPACING_SM)
	panel.add_child(vbox)
	
	# ステージ番号バッジ (カプセルチップ)
	var badge_panel = PanelContainer.new()
	var badge_style = StyleBoxFlat.new()
	badge_style.bg_color = ThemeConfig.PRIMARY if stars_count > 0 else Color("#9E9FB8")
	badge_style.corner_radius_top_left = ThemeConfig.RADIUS_PILL
	badge_style.corner_radius_top_right = ThemeConfig.RADIUS_PILL
	badge_style.corner_radius_bottom_left = ThemeConfig.RADIUS_PILL
	badge_style.corner_radius_bottom_right = ThemeConfig.RADIUS_PILL
	badge_style.content_margin_left = 14
	badge_style.content_margin_right = 14
	badge_style.content_margin_top = 2
	badge_style.content_margin_bottom = 2
	badge_panel.add_theme_stylebox_override("panel", badge_style)
	badge_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var num_label = Label.new()
	num_label.text = "STAGE %d" % [index + 1]
	num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_label.add_theme_font_size_override("font_size", 18)
	num_label.add_theme_color_override("font_color", Color.WHITE)
	badge_panel.add_child(num_label)
	vbox.add_child(badge_panel)
	
	# サムネイル
	var thumb_control = Control.new()
	thumb_control.custom_minimum_size = Vector2(200, 115)
	vbox.add_child(thumb_control)
	if level_data.target_sequence.size() > 0:
		_create_thumbnail(level_data.target_sequence, level_data.layout_id, thumb_control)
	
	# ステージ名
	var title_label = Label.new()
	title_label.text = level_data.level_name
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
	vbox.add_child(title_label)
	
	# 星表示または「未クリア」チップ
	if stars_count > 0:
		var stars_text = ""
		for j in range(stars_count):
			stars_text += "★"
		for j in range(3 - stars_count):
			stars_text += "☆"
		var stars_label = Label.new()
		stars_label.text = stars_text
		stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stars_label.add_theme_font_size_override("font_size", 30)
		stars_label.add_theme_color_override("font_color", ThemeConfig.STAR_GOLD)
		stars_label.add_theme_constant_override("outline_size", 4)
		stars_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.8))
		vbox.add_child(stars_label)
	else:
		var chal_hbox = HBoxContainer.new()
		chal_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		var chal_icon = TextureRect.new()
		chal_icon.texture = load("res://assets/ic_sparkle.svg")
		chal_icon.custom_minimum_size = Vector2(20, 20)
		chal_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		chal_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		chal_icon.modulate = Color("#FF849E")
		chal_hbox.add_child(chal_icon)
		
		var chal_label = Label.new()
		chal_label.text = "チャレンジ！"
		chal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chal_label.add_theme_font_size_override("font_size", 20)
		chal_label.add_theme_color_override("font_color", Color("#FF849E"))
		chal_hbox.add_child(chal_label)
		vbox.add_child(chal_hbox)
	
	# 透明なクリッカブルボタン（カード全体をタッチ＆タップ感触）
	var btn = Button.new()
	btn.mouse_filter = Control.MOUSE_FILTER_PASS
	var empty_style = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_style)
	btn.add_theme_stylebox_override("hover", empty_style)
	btn.add_theme_stylebox_override("pressed", empty_style)
	btn.add_theme_stylebox_override("focus", empty_style)
	btn.pressed.connect(func(): _on_level_selected(index))
	panel.add_child(btn)
	
	# 商用スマホアプリ級・気持ちいいバネ感タッチアニメーション
	panel.pivot_offset = panel.custom_minimum_size / 2.0
	panel.resized.connect(func(): if is_instance_valid(panel): panel.pivot_offset = panel.size / 2.0)
	btn.mouse_entered.connect(func():
		if is_instance_valid(panel):
			var tw = panel.create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
			tw.tween_property(panel, "scale", Vector2(1.04, 1.04), 0.28)
	)
	btn.mouse_exited.connect(func():
		if is_instance_valid(panel):
			var tw = panel.create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
			tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.28)
	)
	btn.button_down.connect(func():
		if is_instance_valid(panel):
			var tw = panel.create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
			tw.tween_property(panel, "scale", Vector2(0.93, 0.93), 0.12)
	)
	btn.button_up.connect(func():
		if is_instance_valid(panel):
			var tw = panel.create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
			tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.28)
	)
	
	return panel

func _on_back_pressed() -> void:
	if SoundManager:
		SoundManager.play_se("button_tap")
		SoundManager.play_se("transition")
	get_tree().change_scene_to_file("res://scenes/Title.tscn")

func _on_level_selected(idx: int) -> void:
	if SoundManager:
		SoundManager.play_se("button_tap")
		SoundManager.play_se("transition")
	FirebaseManager.set_meta("selected_official_level", idx)
	if FirebaseManager.has_meta("ugc_target"):
		FirebaseManager.remove_meta("ugc_target")
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_rules_btn_pressed() -> void:
	if SoundManager: SoundManager.play_se("button_tap")
	var dialog = get_node_or_null("RulesDialog")
	if not dialog:
		dialog = AcceptDialog.new()
		dialog.name = "RulesDialog"
		dialog.title = "特別ルールの設定"
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 10)
		
		var multi_loop_check = CheckButton.new()
		multi_loop_check.text = "二重掛け（同じピンに何度も紐を掛ける）"
		multi_loop_check.button_pressed = GameSave.active_rules.get("multi_loop", false)
		multi_loop_check.toggled.connect(func(toggled_on):
			GameSave.active_rules["multi_loop"] = toggled_on
			GameSave.save_data()
			_reload_levels_with_loading()
		)
		vbox.add_child(multi_loop_check)
		
		dialog.add_child(vbox)
		ThemeConfig.apply_dialog_theme(dialog)
		add_child(dialog)
		
	ThemeConfig.popup_responsive_dialog(dialog, 450, 200)

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
