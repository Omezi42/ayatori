class_name LevelEditor extends Node

@export var string_manager: StringManager
@export var string_drawer: StringDrawer
@export var level_manager: LevelManager
@export var ui_manager: UIManager

func _ready() -> void:
	for node in get_tree().get_nodes_in_group("fingers"):
		if node is FingerNode:
			node.finger_clicked.connect(_on_finger_clicked)
			string_drawer.register_finger(node.finger_id, node.global_position)
	
	if string_drawer:
		string_drawer.segment_dropped_on_finger.connect(_on_segment_dropped_on_finger)
	
	string_manager.reset_to_initial([0, 4, 5, 9])
	string_drawer.update_line()
	
	if ui_manager:
		ui_manager.update_level_text(-1, "フリーモード")
		ui_manager.share_button.text = " お題として投稿する "
		ui_manager.share_button.show()
		
		# UIManager内で接続されているシグナルを解除して上書き
		if ui_manager.share_button.is_connected("pressed", Callable(ui_manager, "_on_share_pressed")):
			ui_manager.share_button.pressed.disconnect(Callable(ui_manager, "_on_share_pressed"))
			
		ui_manager.share_button.pressed.connect(_on_save_pressed)
		
		# スタイルの準備
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
		
		var apply_style = func(btn):
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_stylebox_override("hover", btn_hover)
			btn.add_theme_stylebox_override("pressed", btn_style)
			btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.add_theme_constant_override("outline_size", 4)
			btn.add_theme_color_override("font_outline_color", Color(0.7, 0.4, 0.5, 0.8))
			btn.add_theme_color_override("font_hover_color", Color.WHITE)

		# Titleに戻るボタン
		var back_btn = Button.new()
		back_btn.text = "タイトルへ"
		back_btn.add_theme_font_size_override("font_size", 24)
		apply_style.call(back_btn)
		ui_manager.get_node("Control/HBoxContainer").add_child(back_btn)
		back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Title.tscn"))
		
		# Xに投稿ボタン (シェアする)
		var free_share_btn = Button.new()
		free_share_btn.text = "シェアする"
		free_share_btn.add_theme_font_size_override("font_size", 24)
		apply_style.call(free_share_btn)
		ui_manager.get_node("Control/HBoxContainer").add_child(free_share_btn)
		free_share_btn.pressed.connect(Callable(ui_manager, "_on_share_pressed"))
		
		# タイトル入力ダイアログ
		var dialog = ConfirmationDialog.new()
		dialog.name = "TitleDialog"
		dialog.title = "タイトルを入力"
		
		var dialog_vbox = VBoxContainer.new()
		var label = Label.new()
		label.text = "お題のタイトルを入力してください："
		dialog_vbox.add_child(label)
		
		var title_input = LineEdit.new()
		title_input.name = "TitleInput"
		title_input.placeholder_text = "お題のタイトルを入力"
		title_input.custom_minimum_size = Vector2(300, 40)
		dialog_vbox.add_child(title_input)
		
		dialog.add_child(dialog_vbox)
		dialog.confirmed.connect(_on_dialog_confirmed)
		add_child(dialog)
		
		# レイアウト選択用OptionButton
		var layout_option = OptionButton.new()
		layout_option.name = "LayoutOption"
		layout_option.add_theme_font_size_override("font_size", 24)
		apply_style.call(layout_option)
		layout_option.add_item("手 (ステージ1)", 0)
		layout_option.add_item("ボード (ステージ2)", 1)
		layout_option.add_item("ピラミッド (ステージ3)", 2)
		ui_manager.get_node("Control/HBoxContainer").add_child(layout_option)
		layout_option.item_selected.connect(_on_layout_selected)
		
		# 目標画像表示パネルを非表示
		ui_manager.get_node("Control/GoalPanel").hide()
		ui_manager.moves_label.hide()
		
	FirebaseManager.save_completed.connect(_on_save_completed)
	FirebaseManager.save_failed.connect(_on_save_failed)

func _on_finger_clicked(finger_id: int) -> void:
	if string_drawer.is_input_locked: return
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
	string_drawer.finger_positions.clear()
	for node in get_tree().get_nodes_in_group("fingers"):
		if node is FingerNode:
			var id = node.finger_id
			if id >= 0 and id < positions.size():
				node.global_position = positions[id]
				string_drawer.register_finger(id, positions[id])
	
	string_manager.reset_to_initial([0, 4, 5, 9])
	string_drawer.update_line()

func _on_segment_dropped_on_finger(segment_index: int, finger_id: int) -> void:
	if string_drawer.is_input_locked: return
	string_manager.hook_finger(segment_index, finger_id)

func _on_save_pressed() -> void:
	var dialog = get_node_or_null("TitleDialog") as ConfirmationDialog
	if dialog:
		var title_input = dialog.get_node("VBoxContainer/TitleInput") as LineEdit
		if title_input:
			title_input.text = ""
		dialog.popup_centered(Vector2(400, 150))

func _on_dialog_confirmed() -> void:
	var dialog = get_node("TitleDialog")
	var title_input = dialog.get_node("VBoxContainer/TitleInput") as LineEdit
	var layout_option = ui_manager.get_node_or_null("Control/HBoxContainer/LayoutOption") as OptionButton
	var title = "無題"
	if title_input and title_input.text.strip_edges() != "":
		title = title_input.text.strip_edges()
		
	var layout_id = 0
	if layout_option:
		layout_id = layout_option.selected
		
	ui_manager.share_button.text = " 発行中... "
	ui_manager.share_button.disabled = true
	FirebaseManager.save_level(title, string_manager.current_string, layout_id)

func _on_save_completed(code: String) -> void:
	ui_manager.share_button.text = " コード: " + code
	ui_manager.share_button.disabled = false
	DisplayServer.clipboard_set(code)
	ui_manager.show_message("コピーしました!")

func _on_save_failed(err: String) -> void:
	ui_manager.share_button.text = " 失敗 "
	ui_manager.share_button.disabled = false
	print("Save Failed: ", err)
