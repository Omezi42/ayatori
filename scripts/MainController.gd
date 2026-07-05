class_name MainController extends Node

@export var string_manager: StringManager
@export var string_drawer: StringDrawer
@export var level_manager: LevelManager
@export var ui_manager: UIManager

func _ready() -> void:
	# 子ノード内のすべてのFingerNodeを検索して接続する
	for node in get_tree().get_nodes_in_group("fingers"):
		if node is FingerNode:
			node.finger_clicked.connect(_on_finger_clicked)
			node.finger_dropped_on.connect(_on_finger_dropped_on)
			# StringDrawerに位置を登録
			string_drawer.register_finger(node.finger_id, node.global_position)
	
	if level_manager:
		level_manager.level_changed.connect(_on_level_changed)
		level_manager.game_cleared.connect(_on_game_cleared)
		level_manager.start_game()
	else:
		# 簡易フォールバック
		string_manager.reset_to_initial([0, 4, 5, 9])
		string_drawer.update_line()

func _on_level_changed(level_idx: int, target_string: Array[int], initial_string: Array[int]) -> void:
	string_manager.target_string = target_string
	string_manager.reset_to_initial(initial_string)
	string_drawer.update_line()
	if ui_manager:
		ui_manager.update_level_text(level_idx + 1)
		ui_manager.show_message("Level " + str(level_idx + 1))

func _on_game_cleared() -> void:
	if ui_manager:
		ui_manager.show_message("Game Clear!!")

# 指がクリックされた時（糸を外す）
func _on_finger_clicked(finger_id: int) -> void:
	var arr = string_manager.current_string
	var idx = arr.find(finger_id)
	if idx != -1:
		string_manager.unhook_finger(idx)

# ドラッグした糸が指の上で離された時（糸を掛ける）
func _on_finger_dropped_on(finger_id: int) -> void:
	if string_drawer.is_dragging:
		var seg_idx = string_drawer.dragging_segment_index
		
		# すでにその指に掛かっているかチェック
		if not string_manager.current_string.has(finger_id):
			string_manager.hook_finger(seg_idx, finger_id)
			
			# 判定ロジックのチェック（Step 4）
			if string_manager.check_match():
				print("Level Clear!")
				if ui_manager:
					ui_manager.show_message("Clear!")
				# 少し待ってから次のレベルへ
				await get_tree().create_timer(1.5).timeout
				if level_manager:
					level_manager.next_level()
