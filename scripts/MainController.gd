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

var _is_calculating_hint: bool = false
var _hint_calc_string: Array[int] = []
var _is_ugc_level: bool = false

var _current_optimal_moves: int = 0
var _current_stars: int = 0
var _current_level_name: String = ""

var motif_drawer: MotifDrawer
var tutorial_manager: TutorialManager

# === Phase 3: レイアウト定数 ===
const HEADER_HEIGHT := 80.0
const FOOTER_HEIGHT := 100.0

func _ready() -> void:
	var bg_rect = get_node_or_null("Background")
	if not bg_rect:
		bg_rect = self
	
	# === ロード画面の表示 ===
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
	
	var ui_node = get_node_or_null("../UIManager")
	if ui_node:
		ui_node.add_child(loading_rect)
	else:
		add_child(loading_rect)
		
	await get_tree().process_frame
	await get_tree().process_frame
	# ======================
	
	guide_drawer = TextureRect.new()
	guide_drawer.modulate.a = 0.2
	guide_drawer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	guide_drawer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	guide_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	guide_lines = TargetDrawer.new()
	guide_lines.modulate.a = 0.3
	guide_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	add_child(guide_drawer)
	add_child(guide_lines)
	var hand_bg = get_node_or_null("HandBackground")
	if hand_bg:
		move_child(guide_drawer, hand_bg.get_index() + 1)
		move_child(guide_lines, hand_bg.get_index() + 2)

	
	if GameSave:
		GameSave.customization_changed.connect(_on_customization_changed)
	_update_bg_color()

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
			if string_drawer:
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
			if FirebaseManager.has_meta("daily_name"):
				ld.level_name = FirebaseManager.get_meta("daily_name")
			elif FirebaseManager.has_meta("ugc_title"):
				ld.level_name = FirebaseManager.get_meta("ugc_title")
			else:
				ld.level_name = "ユーザー作成ステージ"
			var typed_seq: Array[int] = []
			for s in seq:
				typed_seq.append(int(s))
			ld.target_sequence = typed_seq
			var typed_init: Array[int]
			if layout_id == 3:
				typed_init = [33, 36, 66, 63]
			else:
				typed_init = [0, 4, 5, 9]
			ld.initial_sequence = typed_init
			ld.layout_id = layout_id
			if string_manager:
				string_manager.layout_id = layout_id
			ld.optimal_moves = -1
			if FirebaseManager.has_meta("ugc_optimal_moves"):
				ld.optimal_moves = int(FirebaseManager.get_meta("ugc_optimal_moves"))
			if ld.optimal_moves <= 0 and string_manager and string_manager.has_method("calculate_optimal_moves_count"):
				ld.optimal_moves = string_manager.calculate_optimal_moves_count(typed_init, typed_seq)
			if FirebaseManager.has_meta("ugc_active_rules"):
				ld.active_rules = FirebaseManager.get_meta("ugc_active_rules")
			_on_level_changed(-1, ld)
		else:
			if FirebaseManager.has_meta("selected_official_level"):
				level_manager.load_level(FirebaseManager.get_meta("selected_official_level"))
			else:
				level_manager.load_level(0)
	else:
		# 簡易フォールバック
		if string_manager:
			var init_arr: Array[int] = [0, 4, 5, 9]
			string_manager.reset_to_initial(init_arr)
		if string_drawer:
			string_drawer.update_line()
		
	if string_manager:
		string_manager.string_changed.connect(_update_moves_ui)
		
	if ui_manager:
		ui_manager.next_level_requested.connect(_on_next_level_requested)
		ui_manager.guide_toggled.connect(_on_guide_toggled)
		ui_manager.hint_requested.connect(_show_hint)
		
	# ロード画面を非表示
	if is_instance_valid(loading_rect):
		var tw = create_tween()
		tw.tween_property(loading_rect, "modulate:a", 0.0, 0.3)
		tw.tween_callback(loading_rect.queue_free)

func _on_next_level_requested() -> void:
	if level_manager:
		level_manager.next_level()

func _on_guide_toggled(is_visible: bool) -> void:
	if guide_drawer:
		guide_drawer.visible = is_visible
	if guide_lines:
		guide_lines.visible = is_visible

func _on_level_changed(level_idx: int, level_data: LevelData) -> void:
	if SoundManager:
		SoundManager.play_bgm("bgm_gameplay")
	_is_calculating_hint = false
	_is_waiting_for_hint = false
	if ui_manager and ui_manager.has_method("set_hint_thinking"):
		ui_manager.set_hint_thinking(false)
		
	_is_ugc_level = (level_idx < 0)
	if ui_manager and ui_manager.has_method("set_hint_enabled"):
		if _is_ugc_level:
			ui_manager.set_hint_enabled(false, "このステージでは使えません")
		else:
			ui_manager.set_hint_enabled(true)
		
	if not level_data:
		push_warning("MainController: _on_level_changed received null level_data")
		return
	
	# レイアウトの適用
	var layout_id = level_data.layout_id
	var bg_rect = get_node_or_null("HandBackground")
	if bg_rect:
		bg_rect.set("layout_id", layout_id)
		if bg_rect.has_method("queue_redraw"):
			bg_rect.queue_redraw()
			
	if guide_lines and guide_lines.has_method("set_layout"):
		guide_lines.set_layout(layout_id)
		
	if string_manager:
		string_manager.set("layout_id", layout_id)
			
	var positions = PinLayout.get_positions(layout_id)
	
	# === Phase 3: 被り防止（プレイエリアとUIの完全分割計算） ===
	var screen_size = get_viewport().get_visible_rect().size
	var play_area_y = HEADER_HEIGHT
	var play_area_h = screen_size.y - HEADER_HEIGHT - FOOTER_HEIGHT
	var play_area_center_y = play_area_y + play_area_h / 2.0
	
	# ピン領域のバウンディングボックスを計算
	var min_pin = Vector2(9999, 9999)
	var max_pin = Vector2(-9999, -9999)
	for p in positions:
		min_pin.x = min(min_pin.x, p.x)
		min_pin.y = min(min_pin.y, p.y)
		max_pin.x = max(max_pin.x, p.x)
		max_pin.y = max(max_pin.y, p.y)
	
	var pin_size = max_pin - min_pin
	var pin_center = (min_pin + max_pin) / 2.0
	
	# プレイエリア内に収まるようスケールを計算（余白40px確保）
	var margin = 40.0
	var available_w = screen_size.x - margin * 2
	var available_h = play_area_h - margin * 2
	var scale_x = available_w / max(pin_size.x, 1.0)
	var scale_y = available_h / max(pin_size.y, 1.0)
	var pin_scale = min(scale_x, scale_y, 1.0)  # 1.0以上にはスケールしない
	
	var scaled_positions: Array[Vector2] = []
	for p in positions:
		var sp = Vector2(
			(p.x - pin_center.x) * pin_scale + (screen_size.x / 2.0),
			(p.y - pin_center.y) * pin_scale + play_area_center_y
		)
		scaled_positions.append(sp)
	
	# 背景もそれに合わせて縮小・移動
	if bg_rect and bg_rect is Node2D:
		bg_rect.scale = Vector2(pin_scale, pin_scale)
		bg_rect.position = Vector2(
			screen_size.x / 2.0 - pin_center.x * pin_scale,
			play_area_center_y - pin_center.y * pin_scale
		)
		
	if guide_lines:
		guide_lines.scale = Vector2(pin_scale, pin_scale)
		guide_lines.position = Vector2(
			screen_size.x / 2.0 - pin_center.x * pin_scale,
			play_area_center_y - pin_center.y * pin_scale
		)
		
	# ガイドドローワーの配置
	if guide_drawer:
		var guide_size = min(available_w, available_h) * 0.8
		guide_drawer.size = Vector2(guide_size, guide_size)
		guide_drawer.position = Vector2(
			screen_size.x / 2.0 - guide_size / 2.0,
			play_area_center_y - guide_size / 2.0
		)
		
	if string_drawer:
		string_drawer.finger_positions.clear()
		
	var current_fingers = get_tree().get_nodes_in_group("fingers")
	if current_fingers.size() > 0:
		var fingers_parent = current_fingers[0].get_parent()
		if scaled_positions.size() > current_fingers.size():
			for i in range(current_fingers.size(), scaled_positions.size()):
				var area = Area2D.new()
				area.name = "Finger" + str(i)
				area.set_script(load("res://scripts/FingerNode.gd"))
				var shape = CollisionShape2D.new()
				var circle = CircleShape2D.new()
				circle.radius = 40.0
				shape.shape = circle
				area.add_child(shape)
				area.add_to_group("fingers")
				area.set("finger_id", i)
				fingers_parent.add_child(area)
				area.finger_clicked.connect(_on_finger_clicked)

	var target_base_scale = Vector2(0.25, 0.25) if layout_id == 3 else Vector2(1.0, 1.0)
	for node in get_tree().get_nodes_in_group("fingers"):
		if node is FingerNode:
			if node.has_method("set_base_scale"):
				node.set_base_scale(target_base_scale)
			var id = node.finger_id
			if id >= 0 and id < scaled_positions.size():
				node.show()
				node.global_position = scaled_positions[id]
				if string_drawer:
					string_drawer.register_finger(id, scaled_positions[id])
			else:
				node.hide()
				node.global_position = Vector2(-9999, -9999)
	if GameSave:
		GameSave.is_playing_advanced_level = true
		GameSave.playing_active_rules = level_data.active_rules.duplicate()

	# 初期状態を保持
	_current_initial_state = level_data.initial_sequence.duplicate()
	
	# StringManagerにターゲットと初期状態を設定
	if string_manager:
		string_manager.target_string = level_data.target_sequence.duplicate()
		string_manager.reset_to_initial(_current_initial_state.duplicate())
	_current_level_name = level_data.level_name
	
	# 最短手数を取得
	if level_data.optimal_moves <= 0 and string_manager and string_manager.has_method("calculate_optimal_moves_count"):
		level_data.optimal_moves = string_manager.calculate_optimal_moves_count(_current_initial_state, level_data.target_sequence)
		
	if level_data.optimal_moves <= 0:
		_current_optimal_moves = max(1, level_data.target_sequence.size() - 2)
	else:
		_current_optimal_moves = level_data.optimal_moves
		
	# UIへ手数の初期化を通知する
	if ui_manager and ui_manager.has_method("update_moves_display"):
		ui_manager.update_moves_display(0, _current_optimal_moves)
	
	if string_drawer:
		string_drawer.is_dragging = false
		string_drawer.dragging_segment_index = -1
		string_drawer.is_input_locked = false
	current_state = GameState.PLAYING
	
	if string_drawer:
		string_drawer.update_line()
	
	if motif_drawer:
		motif_drawer.modulate.a = 0.0
		
	if ui_manager:
		ui_manager.update_level_text(level_idx + 1, level_data.level_name)
		if ui_manager.has_method("set_goal_layout"):
			ui_manager.set_goal_layout(layout_id)
		if ui_manager.has_method("set_goal_sequence"):
			ui_manager.set_goal_sequence(level_data.target_sequence, layout_id)
		if ui_manager.has_method("set_goal_texture"):
			ui_manager.set_goal_texture(level_data.target_image if level_data.target_image else null)
		ui_manager.set_initial_state(_current_initial_state)
		ui_manager.show_message(level_data.level_name)
		if ui_manager.share_button:
			ui_manager.share_button.hide()
		
	if guide_drawer:
		guide_drawer.texture = level_data.target_image if level_data.target_image else null
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
			
func _on_game_cleared() -> void:
	if ui_manager:
		ui_manager.show_message("Game Clear!!")

# 指がクリックされた時（糸を外す）
func _on_finger_clicked(finger_id: int) -> void:
	if current_state != GameState.PLAYING:
		return
	if string_drawer and string_drawer.is_input_locked:
		return
	if not string_manager:
		return
	var arr = string_manager.current_string
	var idx = -1
	if GameSave and GameSave.has_rule("multi_loop"):
		idx = string_manager.get_latest_index_of_finger(finger_id)
	else:
		idx = arr.find(finger_id)
		
	if idx != -1:
		string_manager.unhook_finger(idx)
		
		# クリア判定
		if string_manager.check_clear():
			_handle_game_clear()

# ドラッグした糸が指の上でドロップされた時（糸を掛ける）
func _on_segment_dropped_on_finger(segment_index: int, finger_id: int) -> void:
	if current_state != GameState.PLAYING:
		return
	if string_drawer and string_drawer.is_input_locked:
		return
	if not string_manager:
		return
	
	string_manager.hook_finger(segment_index, finger_id)
	
	# クリア判定
	if string_manager.check_clear():
		_handle_game_clear()

func _update_moves_ui() -> void:
	if ui_manager and ui_manager.has_method("update_moves_display") and string_manager:
		ui_manager.update_moves_display(string_manager.get_move_count(), _current_optimal_moves)
	
	if current_state == GameState.PLAYING and string_manager and not string_manager.check_clear():
		_trigger_background_hint_calculation()

func _handle_game_clear() -> void:
	print("Level Clear!")
	current_state = GameState.CLEAR_ANIMATION
	if string_drawer:
		string_drawer.is_input_locked = true
	
	# 星の評価
	var moves = string_manager.get_move_count() if string_manager else 0
	if _current_optimal_moves <= 0:
		_current_stars = 3
	elif moves <= _current_optimal_moves:
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
		if _current_level_name != "" and _current_level_name != "ユーザー作成ステージ":
			GameSave.save_level_stars(_current_level_name, _current_stars)
		if FirebaseManager.has_meta("is_daily") and FirebaseManager.get_meta("is_daily") == true:
			var date_str = FirebaseManager.get_meta("daily_date")
			if typeof(date_str) == TYPE_STRING and date_str != "":
				GameSave.mark_daily_cleared(date_str)
		
	if motif_drawer and string_drawer and string_manager:
		motif_drawer.setup(string_drawer.finger_positions, string_manager.target_string)
	
	await get_tree().create_timer(2.0).timeout
	current_state = GameState.RESULT
	if SoundManager:
		SoundManager.play_se("star_get")
	if ui_manager:
		ui_manager.show_result_panel()

var _is_waiting_for_hint: bool = false

func _trigger_background_hint_calculation() -> void:
	if _is_ugc_level: return
	if _is_calculating_hint: return
	if not string_manager or string_manager.current_string.is_empty() or string_manager.target_string.is_empty(): return
	
	var quick_hint = string_manager.get_quick_hint(string_manager.current_string, string_manager.target_string)
	if not quick_hint.has("_need_deep_search"): return
	
	_is_calculating_hint = true
	_hint_calc_string = string_manager.current_string.duplicate()
	_calculate_hint_async_coroutine(string_manager.current_string.duplicate(), string_manager.target_string.duplicate())

func _show_hint() -> void:
	if _is_ugc_level:
		if ui_manager:
			ui_manager.show_message("投稿ステージではヒントを使えません")
		return
	if current_state != GameState.PLAYING: return
	if not string_manager or not string_drawer: return
	if string_manager.current_string.is_empty() or string_manager.target_string.is_empty(): return
	if string_manager.check_clear(): return
	
	var quick_hint = string_manager.get_quick_hint(string_manager.current_string, string_manager.target_string)
	if not quick_hint.has("_need_deep_search"):
		_display_hint_result(quick_hint)
		return
		
	if _is_calculating_hint:
		_is_waiting_for_hint = true
		if ui_manager and ui_manager.has_method("set_hint_thinking"):
			ui_manager.set_hint_thinking(true)
		return
		
	# 計算が走っていない場合（通常はないが念のため）
	_is_calculating_hint = true
	_is_waiting_for_hint = true
	_hint_calc_string = string_manager.current_string.duplicate()
	if ui_manager and ui_manager.has_method("set_hint_thinking"):
		ui_manager.set_hint_thinking(true)
	_calculate_hint_async_coroutine(string_manager.current_string.duplicate(), string_manager.target_string.duplicate())

func _calculate_hint_async_coroutine(current_copy: Array[int], target_copy: Array[int]) -> void:
	var hint = await string_manager.get_heuristic_hint_async(current_copy, target_copy)
	_on_hint_calculated(hint)

func _on_hint_calculated(hint: Dictionary) -> void:
	_is_calculating_hint = false
	
	if current_state != GameState.PLAYING:
		_is_waiting_for_hint = false
		if ui_manager and ui_manager.has_method("set_hint_thinking"):
			ui_manager.set_hint_thinking(false)
		return
		
	if not string_manager or not string_drawer: return
	
	# 計算中にユーザーが糸の状態を変えていた場合、待ち状態なら新しい計算を開始
	if string_manager.current_string != _hint_calc_string:
		if _is_waiting_for_hint:
			_trigger_background_hint_calculation()
		return
		
	var was_waiting = _is_waiting_for_hint
	_is_waiting_for_hint = false
	if ui_manager and ui_manager.has_method("set_hint_thinking"):
		ui_manager.set_hint_thinking(false)
		
	if was_waiting:
		_display_hint_result(hint)

func _display_hint_result(hint: Dictionary) -> void:
	if hint.is_empty(): return
	
	if hint["type"] == "hook":
		var added_finger = hint["finger"]
		var arr = string_manager.current_string
		var from_pos = Vector2(640, 360)
		if hint.has("segment_index") and arr.size() > 0:
			var seg: int = hint["segment_index"]
			if seg >= 0 and seg < arr.size():
				var idx1 = arr[seg]
				var idx2 = arr[(seg + 1) % arr.size()]
				if string_drawer.finger_positions.has(idx1) and string_drawer.finger_positions.has(idx2):
					from_pos = (string_drawer.finger_positions[idx1] + string_drawer.finger_positions[idx2]) / 2.0
		elif arr.size() > 1:
			if string_drawer.finger_positions.has(arr[0]) and string_drawer.finger_positions.has(arr[1]):
				from_pos = (string_drawer.finger_positions[arr[0]] + string_drawer.finger_positions[arr[1]]) / 2.0
				
		if string_drawer.finger_positions.has(added_finger) and tutorial_manager:
			tutorial_manager.show_hint(from_pos, string_drawer.finger_positions[added_finger])
			
	elif hint["type"] == "unhook":
		var removed_finger = hint["finger"]
		if string_drawer.finger_positions.has(removed_finger):
			if tutorial_manager and tutorial_manager.has_method("show_unhook_hint"):
				tutorial_manager.show_unhook_hint(string_drawer.finger_positions[removed_finger])

func apply_theme_colors() -> void:
	_update_bg_color()

func _on_customization_changed() -> void:
	_update_bg_color()

func _update_bg_color() -> void:
	var bg_rect = get_node_or_null("Background")
	if bg_rect and bg_rect is ColorRect:
		bg_rect.color = GameSave.get_current_bg_color()
	var hand_bg = get_node_or_null("HandBackground")
	if hand_bg and hand_bg.has_method("queue_redraw"):
		hand_bg.queue_redraw()

func _exit_tree() -> void:
	if GameSave:
		GameSave.is_playing_advanced_level = false
		GameSave.playing_active_rules.clear()
