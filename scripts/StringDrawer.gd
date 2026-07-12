class_name StringDrawer extends Node2D

@export var line: Line2D
@export var string_manager: StringManager

# 指IDをキーとして、その指のグローバル座標(Vector2)を保持する辞書
var finger_positions: Dictionary = {}

# ドラッグ状態管理
var is_dragging: bool = false
var dragging_segment_index: int = -1
var current_mouse_pos: Vector2 = Vector2.ZERO
var is_hovering_line: bool = false
var hovered_segment_index: int = -1
var line_tween: Tween
var hover_line: Line2D

# 入力ロック（クリア演出中など）
var is_input_locked: bool = false

var current_highlighted_finger_id: int = -1

# ドラッグ結果シグナル（線分を引っ張って指にドロップした時に発火）
signal segment_dropped_on_finger(segment_index: int, finger_id: int)

const HIT_RADIUS := 44.0        # 線分のヒット判定半径(px) [タッチ画面・マウス両対応のエルゴノミクス判定]
const FINGER_DROP_RADIUS := 56.0 # 指ドロップ判定半径(px) [ドロップしやすさと糸の掴みやすさのバランス]
const MULTI_LOOP_OFFSET_RADIUS := 14.0 # 多重ループ時のオフセット半径(px)

var default_width: float = 16.0
var dragging_width: float = 8.0

func _ready() -> void:
	if string_manager:
		string_manager.string_changed.connect(update_line)
	
	if not line:
		line = $Line2D # フォールバック

	line.width = default_width
	line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	
	var shader = load("res://resources/string_shader.gdshader")
	if shader:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		line.material = mat
		
	hover_line = Line2D.new()
	hover_line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	hover_line.joint_mode = Line2D.LINE_JOINT_ROUND
	hover_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	hover_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	if shader:
		hover_line.material = line.material.duplicate()
	add_child(hover_line)
	
	_update_string_color()
	if GameSave:
		GameSave.customization_changed.connect(_on_customization_changed)

func _on_customization_changed() -> void:
	_update_string_color()
	update_line()

func _update_string_color() -> void:
	if line:
		var col = GameSave.get_current_string_color()
		line.default_color = col
		if line.material and line.material is ShaderMaterial:
			line.material.set_shader_parameter("base_color", col)
	if hover_line:
		var col = GameSave.get_current_string_color()
		hover_line.default_color = col
		if hover_line.material and hover_line.material is ShaderMaterial:
			hover_line.material.set_shader_parameter("base_color", col)

func _process(_delta: float) -> void:
	if is_input_locked:
		return
		
	var mouse_pos = get_global_mouse_position()
	
	if is_dragging:
		current_mouse_pos = mouse_pos
		update_line()
		
		# ハイライトの更新処理
		var hover_id = _find_finger_at(current_mouse_pos)
		if hover_id >= 0 and string_manager.current_string.has(hover_id):
			if not (GameSave and GameSave.has_method("has_rule") and GameSave.has_rule("multi_loop")):
				hover_id = -1
			
		if hover_id != current_highlighted_finger_id:
			if current_highlighted_finger_id >= 0:
				_set_finger_highlight(current_highlighted_finger_id, false)
			current_highlighted_finger_id = hover_id
			if current_highlighted_finger_id >= 0:
				_set_finger_highlight(current_highlighted_finger_id, true)
	else:
		var best_index = -1
		var pin_tap_r = 22.0 if (string_manager and string_manager.get("layout_id") == 3) else 30.0
		if _find_finger_at(mouse_pos, pin_tap_r) < 0:
			var arr = string_manager.current_string
			if arr.size() >= 2:
				var best_dist := HIT_RADIUS
				var actual_points = _get_actual_points(arr)
				for i in range(arr.size()):
					if not finger_positions.has(arr[i]): continue
					var next_idx = (i + 1) % arr.size()
					if not finger_positions.has(arr[next_idx]): continue
					
					var p1 = actual_points[i]
					var p2 = actual_points[next_idx]
					var closest = Geometry2D.get_closest_point_to_segment(mouse_pos, p1, p2)
					var dist = mouse_pos.distance_to(closest)
					if dist < best_dist:
						best_dist = dist
						best_index = i
						
		if best_index != hovered_segment_index:
			hovered_segment_index = best_index
			is_hovering_line = (hovered_segment_index >= 0)
			_update_hover_line_points()
			_update_line_appearance()

func _set_finger_highlight(finger_id: int, is_highlighted: bool) -> void:
	for node in get_tree().get_nodes_in_group("fingers"):
		if node is FingerNode and node.finger_id == finger_id:
			node.set_highlight(is_highlighted)

func _input(event: InputEvent) -> void:
	if is_input_locked:
		return
	
	# 線分のドラッグ判定用 (クリック)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_try_start_drag(event.position)
		else:
			_end_drag(event.position)

# 全ての指ノードを登録する
func register_finger(finger_id: int, pos: Vector2) -> void:
	finger_positions[finger_id] = pos

# 指定座標に最も近い指IDを返す（範囲内にない場合は -1）
func _find_finger_at(pos: Vector2, custom_radius: float = -1.0) -> int:
	var closest_id := -1
	var check_radius: float = custom_radius if custom_radius > 0.0 else (34.0 if (string_manager and string_manager.get("layout_id") == 3) else FINGER_DROP_RADIUS)
	var closest_dist: float = check_radius
	for f_id in finger_positions:
		var dist = pos.distance_to(finger_positions[f_id])
		if dist < closest_dist:
			closest_dist = dist
			closest_id = f_id
	return closest_id

# 配列の各要素に対応する実際の描画用座標（オフセット加味）を計算
func _get_actual_points(arr: Array[int]) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var usage_counts = {}
	
	for i in range(arr.size()):
		var f_id = arr[i]
		if not finger_positions.has(f_id):
			points.append(Vector2.ZERO)
			continue
			
		var pos = finger_positions[f_id]
		var is_advanced = false
		if GameSave:
			is_advanced = GameSave.has_method("has_rule") and GameSave.has_rule("multi_loop")
		if is_advanced:
			if not usage_counts.has(f_id):
				usage_counts[f_id] = 0
			var count = usage_counts[f_id]
			if count > 0:
				var angle = count * (PI / 4.0)
				var offset = Vector2(cos(angle), sin(angle)) * MULTI_LOOP_OFFSET_RADIUS
				pos += offset
			usage_counts[f_id] += 1
			
		points.append(pos)
		
	return points

# StringManagerの状態に従ってLine2Dのポイントを更新
func update_line() -> void:
	if not line or not string_manager:
		return
		
	line.clear_points()
	var arr = string_manager.current_string
	
	if arr.is_empty():
		for node in get_tree().get_nodes_in_group("fingers"):
			if node is FingerNode:
				node.set_loop_count(0)
		return
		
	var actual_points = _get_actual_points(arr)
	
	var finger_counts = {}
	for f_id in arr:
		finger_counts[f_id] = finger_counts.get(f_id, 0) + 1
		
	for node in get_tree().get_nodes_in_group("fingers"):
		if node is FingerNode:
			node.set_loop_count(finger_counts.get(node.finger_id, 0))
		
	for i in range(arr.size()):
		var f_id = arr[i]
		if finger_positions.has(f_id):
			line.add_point(actual_points[i])
			
			# ドラッグ中の線分であれば、中間にマウス位置を挿入
			if is_dragging and i == dragging_segment_index:
				line.add_point(current_mouse_pos)
	
	# ループさせるために最初の点を最後にもう一度追加
	var first_f_id = arr[0]
	if finger_positions.has(first_f_id):
		line.add_point(actual_points[0])
		
	_update_hover_line_points()

func _update_hover_line_points() -> void:
	if not hover_line or not string_manager:
		return
	hover_line.clear_points()
	if hovered_segment_index >= 0 and not is_dragging:
		var arr = string_manager.current_string
		if hovered_segment_index < arr.size():
			var actual_points = _get_actual_points(arr)
			var next_idx = (hovered_segment_index + 1) % arr.size()
			if finger_positions.has(arr[hovered_segment_index]) and finger_positions.has(arr[next_idx]):
				hover_line.add_point(actual_points[hovered_segment_index])
				hover_line.add_point(actual_points[next_idx])

# ドラッグ開始の試行（線分をクリックしたか判定）
# 【アプローチB】数学的な線分距離判定を使用
func _try_start_drag(mouse_pos: Vector2) -> void:
	if string_manager.current_string.size() < 2:
		return
	
	# 指の上をクリックした場合はドラッグを開始しない（指のタップ操作を優先）
	var pin_tap_r = 22.0 if (string_manager and string_manager.get("layout_id") == 3) else 30.0
	if _find_finger_at(mouse_pos, pin_tap_r) >= 0:
		return
		
	# 各線分（ループ含む）との距離を計算して最も近いものを選択
	var arr = string_manager.current_string
	var best_index := -1
	var best_dist := HIT_RADIUS
	var actual_points = _get_actual_points(arr)
	
	for i in range(arr.size()):
		if not finger_positions.has(arr[i]):
			continue
		var next_idx = (i + 1) % arr.size()
		if not finger_positions.has(arr[next_idx]):
			continue
		
		var p1 = actual_points[i]
		var p2 = actual_points[next_idx]
		
		# Geometry2D を使って線分上の最近接点を算出
		var closest = Geometry2D.get_closest_point_to_segment(mouse_pos, p1, p2)
		var dist = mouse_pos.distance_to(closest)
		
		if dist < best_dist:
			best_dist = dist
			best_index = i
	
	if best_index >= 0:
		is_dragging = true
		dragging_segment_index = best_index
		current_mouse_pos = mouse_pos
		_update_line_appearance()

# ドラッグ終了時の処理
func _end_drag(mouse_pos: Vector2) -> void:
	if not is_dragging:
		return
	
	# ドロップ先の指を検出
	var dropped_finger_id := _find_finger_at(mouse_pos)
	
	if dropped_finger_id >= 0:
		# すでにその指に糸が掛かっていない場合のみフック
		var is_advanced = false
		if GameSave:
			is_advanced = GameSave.has_method("has_rule") and GameSave.has_rule("multi_loop")
		if not string_manager.current_string.has(dropped_finger_id) or is_advanced:
			segment_dropped_on_finger.emit(dragging_segment_index, dropped_finger_id)
	
	# ドラッグ状態をリセット（何もない場所でドロップした場合は元に戻る）
	is_dragging = false
	dragging_segment_index = -1
	
	if current_highlighted_finger_id >= 0:
		_set_finger_highlight(current_highlighted_finger_id, false)
		current_highlighted_finger_id = -1
		
	# マウス位置での再判定のため
	hovered_segment_index = -1
	is_hovering_line = false
	_update_hover_line_points()
	_update_line_appearance()
	update_line()

func apply_theme_colors() -> void:
	_update_string_color()
	update_line()

func _update_line_appearance() -> void:
	if not line or not line.material: return
	
	var target_width: float
	var target_color: Color
	
	if is_dragging:
		target_width = dragging_width
		target_color = GameSave.get_current_string_tense_color() if GameSave else ThemeConfig.string_tense
	else:
		target_width = default_width
		target_color = GameSave.get_current_string_color() if GameSave else ThemeConfig.string_normal
	
	if line_tween:
		line_tween.kill()
	line_tween = create_tween().set_parallel(true)
	
	if is_dragging:
		line_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		line_tween.tween_property(line, "width", target_width, 0.15)
	else:
		line_tween.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
		line_tween.tween_property(line, "width", target_width, 0.4)
		
	if hover_line:
		if is_hovering_line and not is_dragging:
			line_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			line_tween.tween_property(hover_line, "width", default_width * 1.5, 0.15)
		else:
			hover_line.width = 0.0 # 非表示またはリセット

	var current_color: Color = target_color
	if line.material is ShaderMaterial:
		var current_param = (line.material as ShaderMaterial).get_shader_parameter("base_color")
		if current_param != null and current_param is Color:
			current_color = current_param
		
		line_tween.tween_method(func(col: Color):
			if line and line.material and line.material is ShaderMaterial:
				(line.material as ShaderMaterial).set_shader_parameter("base_color", col)
			if hover_line and hover_line.material and hover_line.material is ShaderMaterial:
				(hover_line.material as ShaderMaterial).set_shader_parameter("base_color", col)
		, current_color, target_color, 0.15)
