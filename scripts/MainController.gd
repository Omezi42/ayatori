class_name MainController extends Node

@export var string_manager: StringManager
@export var string_drawer: StringDrawer
@export var level_manager: LevelManager
@export var ui_manager: UIManager

# 現在のレベルの初期状態を保持（リセット用）
var _current_initial_state: Array[int] = [0, 4, 5, 9]

enum GameState { PLAYING, CLEAR_ANIMATION, RESULT }
var current_state: GameState = GameState.PLAYING
var guide_drawer: TextureRect

func _ready() -> void:
	# Add background dynamically
	var bg_layer = CanvasLayer.new()
	bg_layer.layer = -1
	var bg_rect = ColorRect.new()
	bg_rect.color = Color("#fff9f0")
	bg_rect.anchor_right = 1.0
	bg_rect.anchor_bottom = 1.0
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_layer.add_child(bg_rect)
	
	guide_drawer = TextureRect.new()
	guide_drawer.modulate.a = 0.2
	guide_drawer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	guide_drawer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# 画面中央付近に配置・サイズ調整
	guide_drawer.size = Vector2(500, 500)
	guide_drawer.position = Vector2(640 - 250, 360 - 250)
	guide_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_layer.add_child(guide_drawer)
	
	add_child(bg_layer)

	# 子ノード内のすべてのFingerNodeを検索して接続する
	for node in get_tree().get_nodes_in_group("fingers"):
		if node is FingerNode:
			node.finger_clicked.connect(_on_finger_clicked)
			# StringDrawerに位置を登録
			string_drawer.register_finger(node.finger_id, node.global_position)
	
	# StringDrawerのドロップシグナルを接続
	if string_drawer:
		string_drawer.segment_dropped_on_finger.connect(_on_segment_dropped_on_finger)
	
	if level_manager:
		level_manager.level_changed.connect(_on_level_changed)
		level_manager.game_cleared.connect(_on_game_cleared)
		level_manager.load_level(0)
	else:
		# 簡易フォールバック
		string_manager.reset_to_initial([0, 4, 5, 9])
		string_drawer.update_line()
		
	if ui_manager:
		ui_manager.next_level_requested.connect(_on_next_level_requested)
		ui_manager.guide_toggled.connect(_on_guide_toggled)

func _on_next_level_requested() -> void:
	if level_manager:
		level_manager.next_level()

func _on_guide_toggled(is_visible: bool) -> void:
	if guide_drawer:
		guide_drawer.visible = is_visible

func _on_level_changed(level_idx: int, level_data: LevelData) -> void:
	# 初期状態を保持
	_current_initial_state = level_data.initial_sequence.duplicate()
	
	# StringManagerにターゲットと初期状態を設定
	string_manager.target_string = level_data.target_sequence.duplicate()
	string_manager.reset_to_initial(_current_initial_state.duplicate())
	
	string_drawer.is_dragging = false
	string_drawer.dragging_segment_index = -1
	string_drawer.is_input_locked = false
	current_state = GameState.PLAYING
	
	string_drawer.update_line()
	
	if ui_manager:
		ui_manager.update_level_text(level_idx + 1, level_data.level_name)
		if ui_manager.has_method("set_goal_sequence"):
			ui_manager.set_goal_sequence(level_data.target_sequence)
		if ui_manager.has_method("set_goal_texture"):
			ui_manager.set_goal_texture(level_data.target_image)
		ui_manager.set_initial_state(_current_initial_state)
		ui_manager.show_message(level_data.level_name)
		ui_manager.share_button.hide()
		
	if guide_drawer:
		guide_drawer.texture = level_data.target_image
		if ui_manager:
			guide_drawer.visible = ui_manager.guide_enabled
		else:
			guide_drawer.hide()

func _on_game_cleared() -> void:
	if ui_manager:
		ui_manager.show_message("Game Clear!!")

# 指がクリックされた時（糸を外す）
func _on_finger_clicked(finger_id: int) -> void:
	if current_state != GameState.PLAYING or string_drawer.is_input_locked:
		return
	var arr = string_manager.current_string
	var idx = arr.find(finger_id)
	if idx != -1:
		string_manager.unhook_finger(idx)

# ドラッグした糸が指の上でドロップされた時（糸を掛ける）
func _on_segment_dropped_on_finger(segment_index: int, finger_id: int) -> void:
	if current_state != GameState.PLAYING or string_drawer.is_input_locked:
		return
	
	string_manager.hook_finger(segment_index, finger_id)
	
	# クリア判定
	if string_manager.check_clear():
		print("Level Clear!")
		# 糸の操作をロック
		current_state = GameState.CLEAR_ANIMATION
		string_drawer.is_input_locked = true
		
		if ui_manager:
			ui_manager.play_clear_animation()
		
		await get_tree().create_timer(2.0).timeout
		current_state = GameState.RESULT
		if ui_manager:
			ui_manager.show_result_panel()
