class_name LevelEditor extends Node

@export var string_manager: StringManager
@export var string_drawer: StringDrawer
@export var level_manager: LevelManager
@export var ui_manager: UIManager

var title_input: LineEdit

func _ready() -> void:
	if SoundManager:
		SoundManager.play_bgm("bgm_gameplay")
	if GameSave:
		GameSave.is_playing_advanced_level = false
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
		var init_arr: Array[int] = [0, 4, 5, 9]
		string_manager.reset_to_initial(init_arr)
		if ui_manager and ui_manager.has_method("set_initial_state"):
			ui_manager.set_initial_state(init_arr)
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
		# スタイルの準備 (ThemeConfig統一 - 大判3Dカプセル仕様)
		var btn_style = ThemeConfig.create_button_style(ThemeConfig.PRIMARY, 6, ThemeConfig.RADIUS_PILL)
		btn_style.content_margin_left = 24
		btn_style.content_margin_right = 24
		btn_style.content_margin_top = 12
		btn_style.content_margin_bottom = 12
		var btn_pressed = ThemeConfig.create_pressed_style(ThemeConfig.PRIMARY, ThemeConfig.RADIUS_PILL)
		
		var sec_style = ThemeConfig.create_button_style(ThemeConfig.PRIMARY_LIGHT, 6, ThemeConfig.RADIUS_PILL)
		sec_style.content_margin_left = 24
		sec_style.content_margin_right = 24
		sec_style.content_margin_top = 12
		sec_style.content_margin_bottom = 12
		var sec_pressed = ThemeConfig.create_pressed_style(ThemeConfig.PRIMARY_LIGHT, ThemeConfig.RADIUS_PILL)

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
			layout_option.add_item("10x10 ボード (フリー限定)", 3)

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
		title_input.custom_minimum_size = Vector2(320, 60)
		dialog_vbox.add_child(title_input)
		
		# スマホ時に確実に文字を入力できる専用入力ボタンを追加
		if ThemeConfig.is_mobile_device():
			var dialog_prompt_btn = Button.new()
			dialog_prompt_btn.name = "DialogPromptBtn"
			dialog_prompt_btn.text = " スマホで文字を入力"
			dialog_prompt_btn.icon = load("res://assets/ic_edit.svg")
			dialog_prompt_btn.add_theme_constant_override("icon_max_width", 22)
			dialog_prompt_btn.custom_minimum_size = Vector2(320, 56)
			dialog_prompt_btn.add_theme_font_size_override("font_size", 22)
			ThemeConfig.apply_button_theme(dialog_prompt_btn, ThemeConfig.create_button_style(ThemeConfig.PRIMARY_LIGHT, 6, ThemeConfig.RADIUS_PILL))
			ThemeConfig.setup_button_animations(dialog_prompt_btn)
			dialog_prompt_btn.pressed.connect(func():
				if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
					var res = JavaScriptBridge.eval("window.prompt('お題のタイトルを入力してください', '" + title_input.text.replace("'", "\\'") + "')")
					if res != null and str(res) != "null":
						title_input.text = str(res)
				else:
					title_input.grab_focus()
					if DisplayServer.has_method("virtual_keyboard_show"):
						DisplayServer.virtual_keyboard_show(title_input.text)
			)
			dialog_vbox.add_child(dialog_prompt_btn)
		
		dialog.add_child(dialog_vbox)
		ThemeConfig.apply_dialog_theme(dialog)
		ThemeConfig.apply_line_edit_theme(title_input)
		dialog.confirmed.connect(_on_dialog_confirmed)
		title_input.text_submitted.connect(func(_t): dialog.hide(); _on_dialog_confirmed())
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
			
			# スタイル適用
			var share_btn_normal = ThemeConfig.create_button_style(ThemeConfig.PRIMARY, 4.0, ThemeConfig.RADIUS_XL)
			share_btn_normal.content_margin_left = 16
			share_btn_normal.content_margin_right = 16
			share_btn_normal.content_margin_top = 8
			share_btn_normal.content_margin_bottom = 8
			var share_btn_pressed = share_btn_normal.duplicate()
			share_btn_pressed.content_margin_top += 4
			share_btn_pressed.content_margin_bottom -= 4
			ThemeConfig.apply_icon_button_theme(free_mode_share_btn, share_btn_normal, share_btn_pressed)
			
			var share_btn_hover = share_btn_normal.duplicate()
			share_btn_hover.bg_color = ThemeConfig.PRIMARY_LIGHT
			free_mode_share_btn.add_theme_stylebox_override("hover", share_btn_hover)
			ThemeConfig.setup_button_animations(free_mode_share_btn)
			
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
	
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

func _on_viewport_size_changed() -> void:
	if not is_inside_tree() or not string_manager:
		return
	var layout_id = string_manager.layout_id
	var positions = PinLayout.get_positions(layout_id)
	var screen_size = get_viewport().get_visible_rect().size
	var play_area_y = 80.0
	var play_area_h = screen_size.y - 80.0 - 100.0
	var play_area_center_y = play_area_y + play_area_h / 2.0
	
	var min_pin = Vector2(9999, 9999)
	var max_pin = Vector2(-9999, -9999)
	for p in positions:
		min_pin.x = min(min_pin.x, p.x)
		min_pin.y = min(min_pin.y, p.y)
		max_pin.x = max(max_pin.x, p.x)
		max_pin.y = max(max_pin.y, p.y)
	
	var pin_size = max_pin - min_pin
	var pin_center = (min_pin + max_pin) / 2.0
	
	var margin = 40.0
	var available_w = screen_size.x - margin * 2
	var available_h = play_area_h - margin * 2
	var scale_x = available_w / max(pin_size.x, 1.0)
	var scale_y = available_h / max(pin_size.y, 1.0)
	var pin_scale = min(scale_x, scale_y, 1.0)
	
	var scaled_positions: Array[Vector2] = []
	for p in positions:
		var sp = Vector2(
			(p.x - pin_center.x) * pin_scale + (screen_size.x / 2.0),
			(p.y - pin_center.y) * pin_scale + play_area_center_y
		)
		scaled_positions.append(sp)
		
	var bg_rect = get_node_or_null("HandBackground")
	if bg_rect and bg_rect is Node2D:
		bg_rect.scale = Vector2(pin_scale, pin_scale)
		bg_rect.position = Vector2(
			screen_size.x / 2.0 - pin_center.x * pin_scale,
			play_area_center_y - pin_center.y * pin_scale
		)
		
	for node in get_tree().get_nodes_in_group("fingers"):
		if node is FingerNode:
			var id = node.finger_id
			if id >= 0 and id < scaled_positions.size():
				node.global_position = scaled_positions[id]
				if string_drawer:
					string_drawer.register_finger(id, scaled_positions[id])
	if string_drawer:
		string_drawer.update_line()

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
		
	var fingers_parent = get_node_or_null("Fingers")
	if fingers_parent:
		var current_fingers = get_tree().get_nodes_in_group("fingers")
		if positions.size() > current_fingers.size():
			for i in range(current_fingers.size(), positions.size()):
				var area = Area2D.new()
				area.name = "Finger" + str(i)
				area.set_script(load("res://scripts/FingerNode.gd"))
				var shape = CollisionShape2D.new()
				var circle = CircleShape2D.new()
				circle.radius = 28.0 # ピンのタッチ判定（糸を掴みやすくするために小さめ）
				shape.shape = circle
				area.add_child(shape)
				area.add_to_group("fingers")
				area.set("finger_id", i)
				fingers_parent.add_child(area)
				area.finger_clicked.connect(_on_finger_clicked)
				if string_drawer:
					string_drawer.register_finger(i, Vector2.ZERO)

	var target_base_scale = Vector2(0.25, 0.25) if index == 3 else Vector2(1.0, 1.0)
	for node in get_tree().get_nodes_in_group("fingers"):
		if node is FingerNode:
			if node.has_method("set_base_scale"):
				node.set_base_scale(target_base_scale)
			var id = node.finger_id
			if id >= 0 and id < positions.size():
				node.show()
				node.global_position = positions[id]
				if string_drawer:
					string_drawer.register_finger(id, positions[id])
			else:
				node.hide()
				node.global_position = Vector2(-9999, -9999)
	
	if string_manager:
		string_manager.layout_id = index
		var init_arr: Array[int]
		if index == 3:
			init_arr = [33, 36, 66, 63]
		else:
			init_arr = [0, 4, 5, 9]
		string_manager.reset_to_initial(init_arr)
		if ui_manager and ui_manager.has_method("set_initial_state"):
			ui_manager.set_initial_state(init_arr)
	_on_viewport_size_changed()
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
		ThemeConfig.popup_responsive_dialog(dialog, 400, 180)

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
		
	var layout_id = 0
	if layout_option:
		layout_id = layout_option.selected
		
	var current_init: Array[int]
	if layout_id == 3:
		current_init = [33, 36, 66, 63]
	else:
		current_init = [0, 4, 5, 9]
	if string_manager and string_manager.current_string == current_init:
		if ui_manager: ui_manager.show_message("かたちを つくってから とうこうしてね！")
		return
		
	if ui_manager and ui_manager.share_button:
		ui_manager.share_button.text = " 発行中... "
		ui_manager.share_button.disabled = true
	var optimal_moves = -1
	if string_manager and string_manager.has_method("calculate_optimal_moves_count"):
		var old_layout = string_manager.layout_id
		string_manager.layout_id = layout_id
		optimal_moves = string_manager.calculate_optimal_moves_count(current_init, string_manager.current_string)
		string_manager.layout_id = old_layout
	FirebaseManager.save_level(title, string_manager.current_string if string_manager else [], layout_id, optimal_moves)

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
			if GameSave.active_rules.get("multi_loop", false) == toggled_on:
				return
				
			var confirm_dialog = ConfirmationDialog.new()
			confirm_dialog.title = "確認"
			confirm_dialog.dialog_text = "ルールを変更すると、現在の盤面がリセットされます。\nよろしいですか？"
			ThemeConfig.apply_dialog_theme(confirm_dialog)
			add_child(confirm_dialog)
			
			confirm_dialog.confirmed.connect(func():
				GameSave.active_rules["multi_loop"] = toggled_on
				GameSave.save_data()
				if string_manager:
					var cur_layout = 0
					var lo = null
					if ui_manager:
						lo = ui_manager.get_node_or_null("Control/FooterHBox/LayoutOption")
						if not lo: lo = ui_manager.get_node_or_null("Control/HBoxContainer/LayoutOption")
					if lo: cur_layout = lo.selected
					var init_arr: Array[int]
					if cur_layout == 3:
						init_arr = [33, 36, 66, 63]
					else:
						init_arr = [0, 4, 5, 9]
					string_manager.reset_to_initial(init_arr)
					if ui_manager and ui_manager.has_method("set_initial_state"):
						ui_manager.set_initial_state(init_arr)
				if string_drawer:
					string_drawer.update_line()
				confirm_dialog.queue_free()
			)
			
			confirm_dialog.canceled.connect(func():
				multi_loop_check.set_pressed_no_signal(not toggled_on)
				confirm_dialog.queue_free()
			)
			
			confirm_dialog.exclusive = false
			confirm_dialog.popup_centered(Vector2(450, 180))
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
