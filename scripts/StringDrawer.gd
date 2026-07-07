class_name StringDrawer extends Node2D

@export var line: Line2D
@export var string_manager: StringManager

# 指IDをキーとして、その指のグローバル座標(Vector2)を保持する辞書
var finger_positions: Dictionary = {}

# ドラッグ状態管理
var is_dragging: bool = false
var dragging_segment_index: int = -1
var current_mouse_pos: Vector2 = Vector2.ZERO

# 入力ロック（クリア演出中など）
var is_input_locked: bool = false

var current_highlighted_finger_id: int = -1

# ドラッグ結果シグナル（線分を引っ張って指にドロップした時に発火）
signal segment_dropped_on_finger(segment_index: int, finger_id: int)

const HIT_RADIUS := 25.0        # 線分のヒット判定半径(px)
const FINGER_DROP_RADIUS := 50.0 # 指ドロップ判定半径(px)
const MULTI_LOOP_OFFSET_RADIUS := 12.0 # 多重ループ時のオフセット半径(px)

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

func _process(_delta: float) -> void:
	if is_dragging:
		current_mouse_pos = get_global_mouse_position()
		update_line()
		
		# ハイライトの更新処理
		var hover_id = _find_finger_at(current_mouse_pos)
		if hover_id >= 0 and string_manager.current_string.has(hover_id):
			hover_id = -1
			
		if hover_id != current_highlighted_finger_id:
			if current_highlighted_finger_id >= 0:
				_set_finger_highlight(current_highlighted_finger_id, false)
			current_highlighted_finger_id = hover_id
			if current_highlighted_finger_id >= 0:
				_set_finger_highlight(current_highlighted_finger_id, true)

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
func _find_finger_at(pos: Vector2) -> int:
	var closest_id := -1
	var closest_dist := FINGER_DROP_RADIUS
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
		if GameSave.is_advanced_mode:
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

# ドラッグ開始の試行（線分をクリックしたか判定）
# 【アプローチB】数学的な線分距離判定を使用
func _try_start_drag(mouse_pos: Vector2) -> void:
	if string_manager.current_string.size() < 2:
		return
	
	# 指の上をクリックした場合はドラッグを開始しない（指のタップ操作を優先）
	if _find_finger_at(mouse_pos) >= 0:
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
		_set_tension(true)

# ドラッグ終了時の処理
func _end_drag(mouse_pos: Vector2) -> void:
	if not is_dragging:
		return
	
	# ドロップ先の指を検出
	var dropped_finger_id := _find_finger_at(mouse_pos)
	
	if dropped_finger_id >= 0:
		# すでにその指に糸が掛かっていない場合のみフック
		if not string_manager.current_string.has(dropped_finger_id) or GameSave.is_advanced_mode:
			segment_dropped_on_finger.emit(dragging_segment_index, dropped_finger_id)
	
	# ドラッグ状態をリセット（何もない場所でドロップした場合は元に戻る）
	is_dragging = false
	dragging_segment_index = -1
	
	if current_highlighted_finger_id >= 0:
		_set_finger_highlight(current_highlighted_finger_id, false)
		current_highlighted_finger_id = -1
		
	_set_tension(false)
	update_line()

func apply_theme_colors() -> void:
	_update_string_color()
	update_line()

func _set_tension(is_tense: bool) -> void:
	if not line or not line.material: return
	var target_width = dragging_width if is_tense else default_width
	var target_color: Color
	if GameSave:
		target_color = GameSave.get_current_string_tense_color() if is_tense else GameSave.get_current_string_color()
	else:
		target_color = ThemeConfig.string_tense if is_tense else ThemeConfig.string_normal
	
	var tween = create_tween().set_parallel(true)
	if is_tense:
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(line, "width", target_width, 0.15)
	else:
		tween.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
		tween.tween_property(line, "width", target_width, 0.4)

	
	var current_color: Color = target_color
	if line.material is ShaderMaterial:
		var current_param = (line.material as ShaderMaterial).get_shader_parameter("base_color")
		if current_param != null and current_param is Color:
			current_color = current_param
		
		tween.tween_method(func(col: Color):
			if line and line.material and line.material is ShaderMaterial:
				(line.material as ShaderMaterial).set_shader_parameter("base_color", col)
		, current_color, target_color, 0.15)
