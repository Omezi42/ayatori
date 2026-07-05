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
		
		# Titleに戻るボタン
		var back_btn = Button.new()
		back_btn.text = "タイトルへ"
		back_btn.add_theme_font_size_override("font_size", 24)
		ui_manager.get_node("Control/HBoxContainer").add_child(back_btn)
		back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Title.tscn"))
		
		# タイトル入力フィールド
		var title_input = LineEdit.new()
		title_input.name = "TitleInput"
		title_input.placeholder_text = "お題のタイトルを入力"
		title_input.add_theme_font_size_override("font_size", 24)
		title_input.custom_minimum_size = Vector2(300, 50)
		ui_manager.get_node("Control/HBoxContainer").add_child(title_input)
		
		# レイアウト選択用OptionButton
		var layout_option = OptionButton.new()
		layout_option.name = "LayoutOption"
		layout_option.add_theme_font_size_override("font_size", 24)
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
	var title_input = ui_manager.get_node_or_null("Control/HBoxContainer/TitleInput") as LineEdit
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
