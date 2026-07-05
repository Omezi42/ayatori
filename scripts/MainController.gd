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
var guide_lines: TargetDrawer

var _current_optimal_moves: int = 0
var _current_stars: int = 0

var motif_drawer: MotifDrawer
var tutorial_manager: TutorialManager


func _ready() -> void:
	var bg_rect = get_node_or_null("Background")
	if not bg_rect:
		bg_rect = self
	
	guide_drawer = TextureRect.new()
	guide_drawer.modulate.a = 0.2
	guide_drawer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	guide_drawer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# 画面中央付近に配置・サイズ調整
	guide_drawer.size = Vector2(500, 500)
	guide_drawer.position = Vector2(640 - 250, 360 - 250)
	guide_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	guide_lines = TargetDrawer.new()
	guide_lines.modulate.a = 0.3
	
	if bg_rect == self:
		add_child(guide_drawer)
		add_child(guide_lines)
	else:
		bg_rect.add_child(guide_drawer)
		bg_rect.add_child(guide_lines)

	motif_drawer = load("res://scripts/MotifDrawer.gd").new()
	add_child(motif_drawer)
	if string_drawer:
		move_child(motif_drawer, string_drawer.get_index())
		
	tutorial_manager = load("res://scripts/TutorialManager.gd").new()
	add_child(tutorial_manager)
	tutorial_manager.main_controller = self

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
		
		if FirebaseManager.has_meta("ugc_target"):
			var seq = FirebaseManager.get_meta("ugc_target")
			var layout_id = 0
			if FirebaseManager.has_meta("ugc_layout_id"):
				layout_id = FirebaseManager.get_meta("ugc_layout_id")
			var ld = LevelData.new()
			ld.level_name = "ユーザー作成ステージ"
			var typed_seq: Array[int] = []
			for s in seq:
				typed_seq.append(int(s))
			ld.target_sequence = typed_seq
			ld.initial_sequence = [0, 4, 5, 9]
			ld.optimal_moves = -1
			ld.layout_id = layout_id
			_on_level_changed(-1, ld)
		else:
			level_manager.load_level(0)
	else:
		# 簡易フォールバック
		string_manager.reset_to_initial([0, 4, 5, 9])
		string_drawer.update_line()
		
	if string_manager:
		string_manager.string_changed.connect(_update_moves_ui)
		
	if ui_manager:
		ui_manager.next_level_requested.connect(_on_next_level_requested)
		ui_manager.guide_toggled.connect(_on_guide_toggled)
		ui_manager.hint_requested.connect(_show_hint)

func _on_next_level_requested() -> void:
	if level_manager:
		level_manager.next_level()

func _on_guide_toggled(is_visible: bool) -> void:
	if guide_drawer:
		guide_drawer.visible = is_visible
	if guide_lines:
		guide_lines.visible = is_visible

func _on_level_changed(level_idx: int, level_data: LevelData) -> void:
	# レイアウトの適用
	var layout_id = level_data.layout_id
	var bg_rect = get_node_or_null("HandBackground")
	if bg_rect and bg_rect.has_method("set_layout_id"):
		# Wait, I didn't add set_layout_id, it's just a property.
		bg_rect.layout_id = layout_id
		bg_rect.queue_redraw()
	elif bg_rect:
		bg_rect.set("layout_id", layout_id)
		if bg_rect.has_method("queue_redraw"):
			bg_rect.queue_redraw()
			
	if guide_lines:
		if guide_lines.has_method("set_layout"):
			guide_lines.set_layout(layout_id)
			
	var positions = PinLayout.get_positions(layout_id)
	string_drawer.finger_positions.clear()
	for node in get_tree().get_nodes_in_group("fingers"):
		if node is FingerNode:
			var id = node.finger_id
			if id >= 0 and id < positions.size():
				node.global_position = positions[id]
				string_drawer.register_finger(id, positions[id])

	# 初期状態を保持
	_current_initial_state = level_data.initial_sequence.duplicate()
	
	# StringManagerにターゲットと初期状態を設定
	string_manager.target_string = level_data.target_sequence.duplicate()
	string_manager.reset_to_initial(_current_initial_state.duplicate())
	
	# 最短手数を取得
	if level_data.optimal_moves < 0:
		_current_optimal_moves = max(1, level_data.target_sequence.size() - 2) # 未設定時の簡易フォールバック
	else:
		_current_optimal_moves = level_data.optimal_moves
		
	# UIへ手数の初期化を通知する（後で追加）
	if ui_manager and ui_manager.has_method("update_moves_display"):
		ui_manager.update_moves_display(0, _current_optimal_moves)
	
	string_drawer.is_dragging = false
	string_drawer.dragging_segment_index = -1
	string_drawer.is_input_locked = false
	current_state = GameState.PLAYING
	
	string_drawer.update_line()
	
	if motif_drawer:
		motif_drawer.modulate.a = 0.0
		
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
			guide_drawer.visible = ui_manager.guide_enabled and (level_data.target_image != null)
		else:
			guide_drawer.hide()
			
	if guide_lines:
		guide_lines.set_target(level_data.target_sequence)
		if ui_manager:
			# 画像がない場合は線でガイドを描画
			guide_lines.visible = ui_manager.guide_enabled and (level_data.target_image == null)
		else:
			guide_lines.hide()
			
	if level_idx == 0:
		get_tree().create_timer(1.0).timeout.connect(_show_hint)

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
		
		# クリア判定
		if string_manager.check_clear():
			_handle_game_clear()

# ドラッグした糸が指の上でドロップされた時（糸を掛ける）
func _on_segment_dropped_on_finger(segment_index: int, finger_id: int) -> void:
	if current_state != GameState.PLAYING or string_drawer.is_input_locked:
		return
	
	string_manager.hook_finger(segment_index, finger_id)
	
	# クリア判定
	if string_manager.check_clear():
		_handle_game_clear()

func _update_moves_ui() -> void:
	if ui_manager and ui_manager.has_method("update_moves_display"):
		ui_manager.update_moves_display(string_manager.get_move_count(), _current_optimal_moves)

func _handle_game_clear() -> void:
	print("Level Clear!")
	current_state = GameState.CLEAR_ANIMATION
	string_drawer.is_input_locked = true
	
	# 星の評価
	var moves = string_manager.get_move_count()
	if moves <= _current_optimal_moves:
		_current_stars = 3
	elif moves <= _current_optimal_moves + 2:
		_current_stars = 2
	else:
		_current_stars = 1
		
	if ui_manager:
		if ui_manager.has_method("set_result_stars"):
			ui_manager.set_result_stars(_current_stars)
		ui_manager.play_clear_animation()
		
	if GameSave:
		GameSave.add_stars(_current_stars)
		
	if motif_drawer:
		motif_drawer.setup(string_drawer.finger_positions, string_manager.target_string)
	
	await get_tree().create_timer(2.0).timeout
	current_state = GameState.RESULT
	if ui_manager:
		ui_manager.show_result_panel()

func _show_hint() -> void:
	if current_state != GameState.PLAYING: return
	var hint = string_manager.get_heuristic_hint(string_manager.current_string, string_manager.target_string)
	if hint.is_empty(): return
	
	if hint["type"] == "hook":
		var added_finger = hint["finger"]
		var arr = string_manager.current_string
		var from_pos = Vector2(640, 360)
		if arr.size() > 1:
			# 適当に最初の2つの指の中間から引っ張るように見せる
			from_pos = (string_drawer.finger_positions[arr[0]] + string_drawer.finger_positions[arr[1]]) / 2.0
			
		if string_drawer.finger_positions.has(added_finger):
			tutorial_manager.show_hint(from_pos, string_drawer.finger_positions[added_finger])
			
	elif hint["type"] == "unhook":
		var removed_finger = hint["finger"]
		if string_drawer.finger_positions.has(removed_finger):
			if tutorial_manager.has_method("show_unhook_hint"):
				tutorial_manager.show_unhook_hint(string_drawer.finger_positions[removed_finger])
