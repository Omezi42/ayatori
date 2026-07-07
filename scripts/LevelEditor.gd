class_name LevelEditor extends Node

@export var string_manager: StringManager
@export var string_drawer: StringDrawer
@export var level_manager: LevelManager
@export var ui_manager: UIManager

var title_input: LineEdit

func _ready() -> void:
	if GameSave:
		GameSave.customization_changed.connect(_update_bg_color)
	_update_bg_color()
	
	for node in get_tree().get_nodes_in_group("fingers"):
		if node is FingerNode:
			node.finger_clicked.connect(_on_finger_clicked)
			if string_drawer:
				string_drawer.register_finger(node.finger_id, node.global_position)
	
	if string_drawer:
		string_drawer.segment_dropped_on_finger.connect(_on_segment_dropped_on_finger)
	
	if string_manager:
		string_manager.reset_to_initial([0, 4, 5, 9])
	if string_drawer:
		string_drawer.update_line()
	
	if ui_manager:
		ui_manager.update_level_text(-1, "フリーモード")
		if ui_manager.share_button:
			ui_manager.share_button.text = " お題として投稿する "
			ui_manager.share_button.show()
			
			# UIManager内で接続されているシグナルを解除して上書き
			if ui_manager.share_button.is_connected("pressed", Callable(ui_manager, "_on_share_pressed")):
				ui_manager.share_button.pressed.disconnect(Callable(ui_manager, "_on_share_pressed"))
				
			ui_manager.share_button.pressed.connect(_on_save_pressed)
		
		# スタイルの準備 (ThemeConfig統一)
		var btn_style = ThemeConfig.create_button_style(ThemeConfig.PRIMARY, 4, ThemeConfig.RADIUS_XL)
		btn_style.content_margin_left = 20
		btn_style.content_margin_right = 20
		btn_style.content_margin_top = 10
		btn_style.content_margin_bottom = 10
		var btn_pressed = ThemeConfig.create_pressed_style(ThemeConfig.PRIMARY, ThemeConfig.RADIUS_XL)
		btn_pressed.content_margin_left = 20
		btn_pressed.content_margin_right = 20
		
		var sec_style = ThemeConfig.create_button_style(ThemeConfig.PRIMARY_LIGHT, 4, ThemeConfig.RADIUS_XL)
		sec_style.content_margin_left = 20
		sec_style.content_margin_right = 20
		sec_style.content_margin_top = 10
		sec_style.content_margin_bottom = 10
		var sec_pressed = ThemeConfig.create_pressed_style(ThemeConfig.PRIMARY_LIGHT, ThemeConfig.RADIUS_XL)
		sec_pressed.content_margin_left = 20
		sec_pressed.content_margin_right = 20

		var hbox = ui_manager.get_node_or_null("Control/FooterHBox")
		if not hbox:
			hbox = ui_manager.get_node_or_null("Control/HBoxContainer")
			
		if hbox:
			# レイアウト選択用OptionButton
			var layout_option = OptionButton.new()
			layout_option.name = "LayoutOption"
			layout_option.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
			ThemeConfig.apply_option_button_theme(layout_option, btn_style, btn_pressed)
			ThemeConfig.setup_button_animations(layout_option)
			layout_option.add_item("円形 (ステージ1)", 0)
			layout_option.add_item("ボード (ステージ2)", 1)
			layout_option.add_item("ピラミッド (ステージ3)", 2)
			hbox.add_child(layout_option)
			hbox.move_child(layout_option, 2)
			layout_option.item_selected.connect(_on_layout_selected)
			
			# ルール設定ボタンを追加
			var rules_btn = Button.new()
			rules_btn.name = "RulesButton"
			rules_btn.text = "ルール設定"
			ThemeConfig.apply_button_theme(rules_btn, sec_style, sec_pressed)
			ThemeConfig.setup_button_animations(rules_btn)
			rules_btn.pressed.connect(_on_rules_btn_pressed)
			hbox.add_child(rules_btn)
			hbox.move_child(rules_btn, 3)
		
		# タイトル入力ダイアログ
		var dialog = ConfirmationDialog.new()
		dialog.name = "TitleDialog"
		dialog.title = "タイトルを入力"
		
		var dialog_vbox = VBoxContainer.new()
		dialog_vbox.name = "VBoxContainer"
		var label = Label.new()
		label.text = "お題のタイトルを入力してください："
		dialog_vbox.add_child(label)
		
		title_input = LineEdit.new()
		title_input.name = "TitleInput"
		title_input.placeholder_text = "お題のタイトルを入力"
		title_input.custom_minimum_size = Vector2(300, 40)
		dialog_vbox.add_child(title_input)
		
		dialog.add_child(dialog_vbox)
		ThemeConfig.apply_dialog_theme(dialog)
		ThemeConfig.apply_line_edit_theme(title_input)
		dialog.confirmed.connect(_on_dialog_confirmed)
		add_child(dialog)
		
		# 目標画像表示パネルと手数ラベルを非表示
		if ui_manager.goal_panel: ui_manager.goal_panel.hide()
		if ui_manager.moves_label: ui_manager.moves_label.hide()
		
		var header = ui_manager.get_node_or_null("Control/HeaderHBox")
		if header:
			var free_mode_share_btn = Button.new()
			free_mode_share_btn.name = "FreeModeShareBtn"
			free_mode_share_btn.text = ""
			free_mode_share_btn.custom_minimum_size = ThemeConfig.MIN_TAP_SIZE
			free_mode_share_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			var share_tex = load("res://assets/ic_system_share_01_trimmed.svg")
			if share_tex:
				free_mode_share_btn.icon = share_tex
				free_mode_share_btn.add_theme_constant_override("icon_max_width", 28)
			free_mode_share_btn.pressed.connect(func():
				if ui_manager.has_method("toggle_share_menu"):
					ui_manager.toggle_share_menu(free_mode_share_btn)
			)
			header.add_child(free_mode_share_btn)
		
	var loading_overlay = CanvasLayer.new()
	loading_overlay.layer = 100
	var color_rect = ColorRect.new()
	color_rect.color = Color(0, 0, 0, 0.5)
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_overlay.add_child(color_rect)
	var loading_label = Label.new()
	loading_label.text = "通信中..."
	loading_label.add_theme_font_size_override("font_size", 32)
	loading_label.set_anchors_preset(Control.PRESET_CENTER)
	color_rect.add_child(loading_label)
	loading_overlay.hide()
	add_child(loading_overlay)
	
	FirebaseManager.network_request_started.connect(func(): loading_overlay.show())
	FirebaseManager.network_request_completed.connect(func(_success, _err): loading_overlay.hide())
		
	FirebaseManager.save_completed.connect(_on_save_completed)
	FirebaseManager.save_failed.connect(_on_save_failed)

func _on_finger_clicked(finger_id: int) -> void:
	if string_drawer and string_drawer.is_input_locked: return
	if not string_manager: return
	var arr = string_manager.current_string
	var idx = arr.find(finger_id)
	if idx != -1:
		string_manager.unhook_finger(idx)

func _on_layout_selected(index: int) -> void:
	var bg_rect = get_node_or_null("HandBackground")
	if bg_rect:
		bg_rect.set("layout_id", index)
		if bg_rect.has_method("queue_redraw"):
			bg_rect.queue_redraw()
	
	var positions = PinLayout.get_positions(index)
	if string_drawer:
		string_drawer.finger_positions.clear()
	for node in get_tree().get_nodes_in_group("fingers"):
		if node is FingerNode:
			var id = node.finger_id
			if id >= 0 and id < positions.size():
				node.global_position = positions[id]
				if string_drawer:
					string_drawer.register_finger(id, positions[id])
	
	if string_manager:
		string_manager.reset_to_initial([0, 4, 5, 9])
	if string_drawer:
		string_drawer.update_line()

func _on_segment_dropped_on_finger(segment_index: int, finger_id: int) -> void:
	if string_drawer and string_drawer.is_input_locked: return
	if string_manager:
		string_manager.hook_finger(segment_index, finger_id)

func _on_save_pressed() -> void:
	var dialog = get_node_or_null("TitleDialog") as ConfirmationDialog
	if dialog:
		if not title_input:
			title_input = dialog.find_child("TitleInput", true, false) as LineEdit
		if not title_input:
			title_input = dialog.get_node_or_null("VBoxContainer/TitleInput") as LineEdit
		if title_input:
			title_input.text = ""
		dialog.popup_centered(Vector2(400, 150))

func _on_dialog_confirmed() -> void:
	var dialog = get_node_or_null("TitleDialog")
	if not dialog: return
	if not title_input:
		title_input = dialog.find_child("TitleInput", true, false) as LineEdit
	if not title_input:
		title_input = dialog.get_node_or_null("VBoxContainer/TitleInput") as LineEdit
	var layout_option = null
	if ui_manager:
		layout_option = ui_manager.get_node_or_null("Control/FooterHBox/LayoutOption") as OptionButton
		if not layout_option:
			layout_option = ui_manager.get_node_or_null("Control/HBoxContainer/LayoutOption") as OptionButton
			
	var title = ""
	if title_input and title_input.text.strip_edges() != "":
		title = title_input.text.strip_edges()
		
	if title == "":
		if ui_manager: ui_manager.show_message("なまえを いれてね！")
		return
		
	if string_manager and string_manager.current_string == [0, 4, 5, 9]:
		if ui_manager: ui_manager.show_message("かたちを つくってから とうこうしてね！")
		return
		
	var layout_id = 0
	if layout_option:
		layout_id = layout_option.selected
		
	if ui_manager and ui_manager.share_button:
		ui_manager.share_button.text = " 発行中... "
		ui_manager.share_button.disabled = true
	FirebaseManager.save_level(title, string_manager.current_string if string_manager else [], layout_id)

func _on_save_completed(code: String) -> void:
	if ui_manager and ui_manager.share_button:
		ui_manager.share_button.text = " コード: " + code
		ui_manager.share_button.disabled = false
	DisplayServer.clipboard_set(code)
	if OS.has_feature("web"):
		var js_code = """
			if (navigator.clipboard) {
				navigator.clipboard.writeText('%s').then(function() {
					console.log('Copied to clipboard');
				});
			}
		""" % code
		JavaScriptBridge.eval(js_code)
	if ui_manager:
		ui_manager.show_message("コピーしました!")

func _on_save_failed(err: String) -> void:
	if ui_manager and ui_manager.share_button:
		ui_manager.share_button.text = " 失敗 "
		ui_manager.share_button.disabled = false
	print("Save Failed: ", err)

func _on_rules_btn_pressed() -> void:
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
		)
		vbox.add_child(multi_loop_check)
		
		dialog.add_child(vbox)
		ThemeConfig.apply_dialog_theme(dialog)
		add_child(dialog)
		
	dialog.popup_centered(Vector2(450, 200))

func apply_theme_colors() -> void:
	_update_bg_color()
	if ui_manager:
		var layout_option = ui_manager.get_node_or_null("Control/FooterHBox/LayoutOption") as OptionButton
		if not layout_option:
			layout_option = ui_manager.get_node_or_null("Control/HBoxContainer/LayoutOption") as OptionButton
		if layout_option:
			var btn_style = ThemeConfig.create_button_style(ThemeConfig.PRIMARY, 4, ThemeConfig.RADIUS_XL)
			btn_style.content_margin_left = 20
			btn_style.content_margin_right = 20
			btn_style.content_margin_top = 10
			btn_style.content_margin_bottom = 10
			var btn_pressed = ThemeConfig.create_pressed_style(ThemeConfig.PRIMARY, ThemeConfig.RADIUS_XL)
			btn_pressed.content_margin_left = 20
			btn_pressed.content_margin_right = 20
			ThemeConfig.apply_option_button_theme(layout_option, btn_style, btn_pressed)
	var dialog = get_node_or_null("TitleDialog") as ConfirmationDialog
	if dialog:
		ThemeConfig.apply_dialog_theme(dialog)
	if title_input:
		ThemeConfig.apply_line_edit_theme(title_input)

func _update_bg_color() -> void:
	var bg_rect = get_node_or_null("Background")
	if bg_rect and bg_rect is ColorRect:
		bg_rect.color = GameSave.get_current_bg_color()
	var hand_bg = get_node_or_null("HandBackground")
	if hand_bg and hand_bg.has_method("queue_redraw"):
		hand_bg.queue_redraw()
