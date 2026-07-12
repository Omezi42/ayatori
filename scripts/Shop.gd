extends Control

signal closed

var current_tab: int = 0 # 0: ピン, 1: 背景, 2: 糸
@onready var grid_container: GridContainer = $CenterContainer/PanelContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var stars_panel: PanelContainer = $CenterContainer/PanelContainer/VBoxContainer/Footer/StarsPanel
@onready var stars_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Footer/StarsPanel/StarsBox/StarsLabel
@onready var tab_buttons: Array = [
	$CenterContainer/PanelContainer/VBoxContainer/TabBar/Tab0,
	$CenterContainer/PanelContainer/VBoxContainer/TabBar/Tab1,
	$CenterContainer/PanelContainer/VBoxContainer/TabBar/Tab2
]

func _ready() -> void:
	var panel = $CenterContainer/PanelContainer
	if panel:
		var p_style = ThemeConfig.create_settings_panel_style().duplicate()
		p_style.border_width_top = 6
		p_style.border_width_bottom = 6
		p_style.border_width_left = 6
		p_style.border_width_right = 6
		p_style.corner_radius_top_left = ThemeConfig.RADIUS_XL
		p_style.corner_radius_top_right = ThemeConfig.RADIUS_XL
		p_style.corner_radius_bottom_left = ThemeConfig.RADIUS_XL
		p_style.corner_radius_bottom_right = ThemeConfig.RADIUS_XL
		p_style.shadow_size = 12
		p_style.shadow_offset = Vector2(0, 6)
		panel.add_theme_stylebox_override("panel", p_style)
		
	if stars_panel:
		var badge_style = StyleBoxFlat.new()
		badge_style.bg_color = Color("#FFF9E6") # 明るく優しいサンシャインクリーム
		badge_style.border_width_top = 4
		badge_style.border_width_bottom = 4
		badge_style.border_width_left = 4
		badge_style.border_width_right = 4
		badge_style.border_color = ThemeConfig.STAR_GOLD
		badge_style.corner_radius_top_left = ThemeConfig.RADIUS_PILL
		badge_style.corner_radius_top_right = ThemeConfig.RADIUS_PILL
		badge_style.corner_radius_bottom_left = ThemeConfig.RADIUS_PILL
		badge_style.corner_radius_bottom_right = ThemeConfig.RADIUS_PILL
		badge_style.content_margin_left = 28
		badge_style.content_margin_right = 28
		badge_style.content_margin_top = 8
		badge_style.content_margin_bottom = 8
		badge_style.shadow_color = Color(0, 0, 0, 0.08)
		badge_style.shadow_size = 4
		badge_style.shadow_offset = Vector2(0, 2)
		stars_panel.add_theme_stylebox_override("panel", badge_style)
	
	# モーダル背景のクリックで閉じる
	$DimBackground.gui_input.connect(_on_dim_input)
	
	# 閉じるボタン (横画面・スマホ両対応の大判3Dカプセル仕様)
	var close_btn = $CenterContainer/PanelContainer/VBoxContainer/Header/CloseButton
	var close_normal = ThemeConfig.create_button_style(ThemeConfig.PRIMARY_LIGHT, 6, ThemeConfig.RADIUS_PILL)
	close_normal.content_margin_left = 20
	close_normal.content_margin_right = 20
	close_normal.content_margin_top = 10
	close_normal.content_margin_bottom = 10
	var close_pressed = ThemeConfig.create_pressed_style(ThemeConfig.PRIMARY_LIGHT, ThemeConfig.RADIUS_PILL)
	ThemeConfig.apply_button_theme(close_btn, close_normal, close_pressed)
	close_btn.custom_minimum_size = Vector2(110, 52)
	close_btn.add_theme_font_size_override("font_size", 22)
	close_btn.icon = load("res://assets/ic_close.svg")
	close_btn.add_theme_constant_override("icon_max_width", 22)
	ThemeConfig.setup_button_animations(close_btn)
	close_btn.pressed.connect(func():
		if SoundManager: SoundManager.play_se("panel_close")
		hide()
		closed.emit()
	)
	
	# タブボタンのセットアップ
	for i in range(tab_buttons.size()):
		var btn = tab_buttons[i] as Button
		btn.pressed.connect(func():
			if SoundManager: SoundManager.play_se("button_tap")
			_select_tab(i)
		)
		ThemeConfig.setup_button_animations(btn)
	
	if GameSave:
		GameSave.customization_changed.connect(_refresh_ui)
	
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	_select_tab(0)
	call_deferred("_on_viewport_size_changed")

func _on_viewport_size_changed() -> void:
	if not is_inside_tree():
		return
	var screen_size = get_viewport_rect().size
	var panel = $CenterContainer/PanelContainer
	if panel:
		panel.custom_minimum_size = Vector2(min(980.0, screen_size.x - (16.0 if screen_size.x < 850.0 else 32.0)), min(620.0, screen_size.y - (16.0 if screen_size.x < 850.0 else 32.0)))
		
	var tab_bar = get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/TabBar") as HBoxContainer
	if tab_bar:
		var available_w = min(screen_size.x - (24.0 if screen_size.x < 850.0 else 48.0), 920.0)
		var tab_w = max(100.0, (available_w - 24.0) / 3.0)
		for btn in tab_buttons:
			if btn and btn is Button:
				btn.custom_minimum_size = Vector2(tab_w, 64 if screen_size.x < 850.0 else 52)
				btn.add_theme_font_size_override("font_size", min(26, max(18, int(tab_w * 0.18))))
				
	if grid_container and is_instance_valid(grid_container):
		var scroll_c = get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/ScrollContainer")
		var raw_w = scroll_c.size.x if (scroll_c and scroll_c.size.x > 200.0) else min(920.0, screen_size.x - (24.0 if screen_size.x < 850.0 else 48.0))
		var avail_w = raw_w - (16.0 if screen_size.x < 850.0 else 32.0)
		var card_w = 280.0 if screen_size.x >= 900.0 else 260.0
		var sep_w = 24.0 if screen_size.x >= 900.0 else 16.0
		var cols = max(1, int((avail_w + sep_w) / (card_w + sep_w)))
		if grid_container.columns != cols:
			grid_container.columns = cols
		var target_card_w = max(260.0, (avail_w - ((cols - 1) * sep_w)) / float(cols)) if cols > 1 else avail_w
		for card in grid_container.get_children():
			if card is PanelContainer:
				card.custom_minimum_size = Vector2(target_card_w, 140 if cols == 1 else 240)

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if SoundManager: SoundManager.play_se("panel_close")
		hide()
		closed.emit()

func _select_tab(idx: int) -> void:
	current_tab = idx
	var tab_icons = [
		load("res://assets/ic_pin.svg"),
		load("res://assets/ic_bg.svg"),
		load("res://assets/ic_string.svg")
	]
	for i in range(tab_buttons.size()):
		var btn = tab_buttons[i] as Button
		var is_selected = (i == idx)
		var col = ThemeConfig.PRIMARY if is_selected else ThemeConfig.BG_WHITE
		var style_normal = ThemeConfig.create_button_style(col, 4 if is_selected else 2, ThemeConfig.RADIUS_LG)
		style_normal.content_margin_left = 20
		style_normal.content_margin_right = 20
		style_normal.content_margin_top = 10
		style_normal.content_margin_bottom = 10
		if not is_selected:
			style_normal.border_width_top = 2
			style_normal.border_width_bottom = 2
			style_normal.border_width_left = 2
			style_normal.border_width_right = 2
			style_normal.border_color = ThemeConfig.PRIMARY_LIGHT
		var style_pressed = ThemeConfig.create_pressed_style(col, ThemeConfig.RADIUS_LG)
		style_pressed.content_margin_left = 20
		style_pressed.content_margin_right = 20
		
		ThemeConfig.apply_button_theme(btn, style_normal, style_pressed)
		btn.add_theme_color_override("font_color", ThemeConfig.TEXT_LIGHT if is_selected else ThemeConfig.TEXT_DARK)
		btn.add_theme_color_override("font_hover_color", ThemeConfig.TEXT_LIGHT if is_selected else ThemeConfig.PRIMARY)
		btn.add_theme_font_size_override("font_size", 24)
		
		if i < tab_icons.size() and tab_icons[i]:
			btn.icon = tab_icons[i]
			btn.add_theme_constant_override("icon_max_width", 22)
			var icon_col = Color.WHITE if is_selected else ThemeConfig.PRIMARY_DARK
			btn.add_theme_color_override("icon_normal_color", icon_col)
			btn.add_theme_color_override("icon_hover_color", icon_col)
			btn.add_theme_color_override("icon_pressed_color", icon_col)
	
	_refresh_ui()

func apply_theme_colors() -> void:
	var panel = $CenterContainer/PanelContainer
	if panel:
		var p_style = ThemeConfig.create_settings_panel_style().duplicate()
		p_style.border_width_top = 6
		p_style.border_width_bottom = 6
		p_style.border_width_left = 6
		p_style.border_width_right = 6
		p_style.corner_radius_top_left = ThemeConfig.RADIUS_XL
		p_style.corner_radius_top_right = ThemeConfig.RADIUS_XL
		p_style.corner_radius_bottom_left = ThemeConfig.RADIUS_XL
		p_style.corner_radius_bottom_right = ThemeConfig.RADIUS_XL
		p_style.shadow_size = 12
		p_style.shadow_offset = Vector2(0, 6)
		panel.add_theme_stylebox_override("panel", p_style)
		
	var close_btn = $CenterContainer/PanelContainer/VBoxContainer/Header/CloseButton
	if close_btn:
		var close_normal = ThemeConfig.create_button_style(ThemeConfig.PRIMARY_LIGHT, 4, ThemeConfig.RADIUS_MD)
		close_normal.content_margin_left = 16
		close_normal.content_margin_right = 16
		close_normal.content_margin_top = 8
		close_normal.content_margin_bottom = 8
		var close_pressed = ThemeConfig.create_pressed_style(ThemeConfig.PRIMARY_LIGHT, ThemeConfig.RADIUS_MD)
		close_pressed.content_margin_left = 16
		close_pressed.content_margin_right = 16
		ThemeConfig.apply_button_theme(close_btn, close_normal, close_pressed)
		
	_select_tab(current_tab)

func _refresh_ui() -> void:
	if not is_inside_tree():
		return
		
	# 所持スターの表示更新
	if GameSave and stars_label:
		stars_label.text = "所持スター: " + str(GameSave.total_stars)
		stars_label.add_theme_color_override("font_color", Color(0.85, 0.55, 0, 1))
		stars_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.6))
		stars_label.add_theme_constant_override("outline_size", 6)
		var star_icon = stars_panel.get_node_or_null("StarsBox/StarIcon")
		if star_icon:
			star_icon.modulate = ThemeConfig.STAR_GOLD
	
	# 既存カードのクリア
	for child in grid_container.get_children():
		child.queue_free()
	
	var items = []
	var category = ""
	if current_tab == 0:
		items = GameSave.PIN_ITEMS
		category = "pin"
	elif current_tab == 1:
		items = GameSave.BG_ITEMS
		category = "bg"
	elif current_tab == 2:
		items = GameSave.STRING_ITEMS
		category = "string"
	
	for item in items:
		_create_item_card(item, category)
	_on_viewport_size_changed()

func _create_item_card(item: Dictionary, category: String) -> void:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(280, 310)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var is_owned = GameSave.is_unlocked(category, item["id"])
	var is_equipped = false
	if category == "pin" and GameSave.current_pin == item["id"]:
		is_equipped = true
	elif category == "bg" and GameSave.current_bg == item["id"]:
		is_equipped = true
	elif category == "string" and GameSave.current_string == item["id"]:
		is_equipped = true
		
	var card_style = ThemeConfig.create_mobile_card_style(
		Color("#FFF8FA") if is_equipped else (ThemeConfig.BG_WHITE if is_owned else Color("#FAFBFD")),
		ThemeConfig.RADIUS_XL
	)
	if is_equipped:
		card_style.border_width_top = 4
		card_style.border_width_bottom = 6
		card_style.border_color = Color("#FF5C8D")
	elif is_owned:
		card_style.border_width_top = 2
		card_style.border_width_bottom = 4
		card_style.border_color = Color("#4CC9F0")
	else:
		card_style.border_width_top = 2
		card_style.border_width_bottom = 4
		card_style.border_color = Color("#E2E8F0")
		
	card.add_theme_stylebox_override("panel", card_style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", ThemeConfig.SPACING_SM)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)
	
	# 上部ステータスバッジ (カプセルバッジ)
	var badge_panel = PanelContainer.new()
	var badge_style = StyleBoxFlat.new()
	badge_style.corner_radius_top_left = ThemeConfig.RADIUS_PILL
	badge_style.corner_radius_top_right = ThemeConfig.RADIUS_PILL
	badge_style.corner_radius_bottom_left = ThemeConfig.RADIUS_PILL
	badge_style.corner_radius_bottom_right = ThemeConfig.RADIUS_PILL
	badge_style.content_margin_left = 16
	badge_style.content_margin_right = 16
	badge_style.content_margin_top = 4
	badge_style.content_margin_bottom = 4
	badge_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var badge_hbox = HBoxContainer.new()
	badge_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	badge_hbox.add_theme_constant_override("separation", 4)
	var badge_icon = TextureRect.new()
	badge_icon.custom_minimum_size = Vector2(16, 16)
	badge_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge_hbox.add_child(badge_icon)
	
	var badge_lbl = Label.new()
	badge_lbl.add_theme_font_size_override("font_size", 14)
	badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_hbox.add_child(badge_lbl)
	
	if is_equipped:
		badge_style.bg_color = Color("#FF5C8D")
		badge_icon.texture = load("res://assets/ic_star.svg")
		badge_icon.modulate = Color.WHITE
		badge_lbl.text = "そうび中"
		badge_lbl.add_theme_color_override("font_color", Color.WHITE)
	elif is_owned:
		badge_style.bg_color = Color("#E0F2FE")
		badge_icon.texture = load("res://assets/ic_sparkle.svg")
		badge_icon.modulate = Color("#0284C7")
		badge_lbl.text = "所持済み"
		badge_lbl.add_theme_color_override("font_color", Color("#0284C7"))
	else:
		badge_style.bg_color = Color("#FEF3C7")
		badge_icon.texture = load("res://assets/ic_shop.svg")
		badge_icon.modulate = Color("#D97706")
		badge_lbl.text = "ショップ限定"
		badge_lbl.add_theme_color_override("font_color", Color("#D97706"))
		
	badge_panel.add_theme_stylebox_override("panel", badge_style)
	badge_panel.add_child(badge_hbox)
	vbox.add_child(badge_panel)
	
	# プレビュー領域 (Control + カスタム描画)
	var is_single_col = (grid_container and grid_container.columns == 1)
	var preview_area = Control.new()
	preview_area.custom_minimum_size = Vector2(260, 145) if is_single_col else Vector2(240, 130)
	preview_area.draw.connect(func(): _draw_preview(preview_area, item, category))
	vbox.add_child(preview_area)
	
	# アイテム名
	var name_lbl = Label.new()
	name_lbl.text = item["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 26 if is_single_col else 22)
	name_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
	name_lbl.add_theme_constant_override("outline_size", 4)
	name_lbl.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.8))
	vbox.add_child(name_lbl)
	
	# ステータス / アクションボタン
	var btn = Button.new()
	btn.mouse_filter = Control.MOUSE_FILTER_PASS
	btn.custom_minimum_size = Vector2(300, 64) if is_single_col else Vector2(230, 56)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL if is_single_col else Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 24 if is_single_col else 20)
	
	if is_equipped:
		btn.text = " そうび中"
		btn.icon = load("res://assets/ic_sparkle.svg")
		btn.add_theme_constant_override("icon_max_width", 22)
		btn.disabled = true
		var style_dis = ThemeConfig.create_button_style(Color("#CBD5E1"), 0, ThemeConfig.RADIUS_PILL)
		style_dis.content_margin_top = 10
		style_dis.content_margin_bottom = 10
		btn.add_theme_stylebox_override("disabled", style_dis)
		btn.add_theme_color_override("font_disabled_color", Color.WHITE)
		btn.add_theme_color_override("icon_disabled_color", Color.WHITE)
	elif is_owned:
		btn.text = " そうびする"
		btn.icon = load("res://assets/ic_sparkle.svg")
		btn.add_theme_constant_override("icon_max_width", 22)
		var style_norm = ThemeConfig.create_button_style(Color("#4CC9F0"), 6, ThemeConfig.RADIUS_PILL)
		var style_press = ThemeConfig.create_pressed_style(Color("#4CC9F0"), ThemeConfig.RADIUS_PILL)
		ThemeConfig.apply_button_theme(btn, style_norm, style_press)
		ThemeConfig.setup_button_animations(btn)
		btn.pressed.connect(func():
			if SoundManager: SoundManager.play_se("button_tap")
			GameSave.equip_item(category, item["id"])
		)
	else:
		var price = int(item["price"])
		var can_buy = (GameSave.total_stars >= price)
		btn.text = " " + str(price) + " でかいとる"
		btn.icon = load("res://assets/ic_star.svg")
		btn.add_theme_constant_override("icon_max_width", 22)
		if can_buy:
			var style_norm = ThemeConfig.create_button_style(Color("#FF9F1C"), 6, ThemeConfig.RADIUS_PILL)
			var style_press = ThemeConfig.create_pressed_style(Color("#FF9F1C"), ThemeConfig.RADIUS_PILL)
			ThemeConfig.apply_button_theme(btn, style_norm, style_press)
			ThemeConfig.setup_button_animations(btn)
			btn.pressed.connect(func():
				if GameSave.buy_item(category, item["id"], price):
					if SoundManager: SoundManager.play_se("star_get")
					GameSave.equip_item(category, item["id"])
			)
		else:
			btn.disabled = true
			var style_dis = ThemeConfig.create_button_style(Color("#CBD5E1"), 0, ThemeConfig.RADIUS_PILL)
			style_dis.content_margin_top = 10
			style_dis.content_margin_bottom = 10
			btn.add_theme_stylebox_override("disabled", style_dis)
			btn.add_theme_color_override("font_disabled_color", Color("#64748B"))
			btn.add_theme_color_override("icon_disabled_color", Color("#64748B"))
	
	vbox.add_child(btn)
	grid_container.add_child(card)
	
	# カードの浮き上がり＆バネ感タッチアニメーション
	card.pivot_offset = card.custom_minimum_size / 2.0
	card.resized.connect(func(): if is_instance_valid(card): card.pivot_offset = card.size / 2.0)
	card.mouse_entered.connect(func():
		if is_instance_valid(card):
			var tw = card.create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
			tw.tween_property(card, "scale", Vector2(1.04, 1.04), 0.28)
	)
	card.mouse_exited.connect(func():
		if is_instance_valid(card):
			var tw = card.create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
			tw.tween_property(card, "scale", Vector2(1.0, 1.0), 0.28)
	)

func _draw_preview(ctrl: Control, item: Dictionary, category: String) -> void:
	var rect = Rect2(Vector2.ZERO, ctrl.custom_minimum_size)
	# プレビュー枠（グラデーション風の明るい背景と丸みのある枠線）
	ctrl.draw_rect(rect, Color("#F8F9FA"), true)
	ctrl.draw_rect(rect, Color("#E9ECEF"), false, 2.0, 16.0)
	
	var center = rect.size / 2.0
	if category == "pin":
		var r = 36.0
		var col = item["color"]
		var shine = item["shine"]
		# ソフトなスポットライトの背景
		ctrl.draw_circle(center, r * 1.6, col.lightened(0.85).blend(Color(1, 1, 1, 0.4)))
		ctrl.draw_circle(center + Vector2(0, 6), r, Color(0, 0, 0, 0.15))
		ctrl.draw_circle(center, r, col)
		ctrl.draw_circle(center + Vector2(-12, -12), r * 0.3, shine)
		ctrl.draw_circle(center + Vector2(-18, -4), r * 0.1, shine)
	elif category == "bg":
		var bg_col = item["bg_color"]
		var board_col = item["board_color"]
		ctrl.draw_rect(Rect2(Vector2(10, 10), rect.size - Vector2(20, 20)), bg_col, true, 12.0)
		var board_rect = Rect2(Vector2(30, 25), rect.size - Vector2(60, 50))
		ctrl.draw_rect(board_rect, board_col, true, 10.0)
		# ミニチュアボードの演出（4隅の指とピンクの糸）
		var p1 = board_rect.position + Vector2(20, 20)
		var p2 = Vector2(board_rect.position.x + board_rect.size.x - 20, board_rect.position.y + 20)
		var p3 = board_rect.end - Vector2(20, 20)
		var p4 = Vector2(board_rect.position.x + 20, board_rect.end.y - 20)
		var str_col = GameSave.get_current_string_color() if GameSave else Color("#FF849E")
		var pin_col = GameSave.get_current_pin_color() if GameSave else Color("#FFB6C1")
		ctrl.draw_polyline(PackedVector2Array([p1, p2, p3, p4, p1]), str_col, 4.0, true)
		for p in [p1, p2, p3, p4]:
			ctrl.draw_circle(p + Vector2(0, 2), 7.0, Color(0, 0, 0, 0.15))
			ctrl.draw_circle(p, 7.0, pin_col)
			ctrl.draw_circle(p + Vector2(-2, -2), 2.5, Color.WHITE)
	elif category == "string":
		var col = item["color"]
		var p1 = Vector2(30, rect.size.y - 25)
		var p2 = Vector2(rect.size.x / 2.0, 25)
		var p3 = Vector2(rect.size.x - 30, rect.size.y - 25)
		var pts = PackedVector2Array([p1, p2, p3, p1])
		# 糸のドロップシャドウと輝き
		ctrl.draw_polyline(pts, Color(0, 0, 0, 0.15), 12.0, true)
		ctrl.draw_polyline(pts, Color.WHITE, 14.0, true)
		ctrl.draw_polyline(pts, col, 10.0, true)
		for p in [p1, p2, p3]:
			ctrl.draw_circle(p + Vector2(0, 3), 16.0, Color(0, 0, 0, 0.15))
			ctrl.draw_circle(p, 16.0, GameSave.get_current_pin_color())
			ctrl.draw_circle(p + Vector2(-5, -5), 5.0, GameSave.get_current_pin_shine())
