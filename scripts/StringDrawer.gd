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

# ドラッグ結果シグナル（線分を引っ張って指にドロップした時に発火）
signal segment_dropped_on_finger(segment_index: int, finger_id: int)

const HIT_RADIUS := 25.0        # 線分のヒット判定半径(px)
const FINGER_DROP_RADIUS := 50.0 # 指ドロップ判定半径(px)

func _ready() -> void:
	if string_manager:
		string_manager.string_changed.connect(update_line)
	
	if not line:
		line = $Line2D # フォールバック

func _process(_delta: float) -> void:
	if is_dragging:
		current_mouse_pos = get_global_mouse_position()
		update_line()

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

# StringManagerの状態に従ってLine2Dのポイントを更新
func update_line() -> void:
	if not line or not string_manager:
		return
		
	line.clear_points()
	var arr = string_manager.current_string
	
	if arr.is_empty():
		return
		
	for i in range(arr.size()):
		var f_id = arr[i]
		if finger_positions.has(f_id):
			line.add_point(finger_positions[f_id])
			
			# ドラッグ中の線分であれば、中間にマウス位置を挿入
			if is_dragging and i == dragging_segment_index:
				line.add_point(current_mouse_pos)
	
	# ループさせるために最初の点を最後にもう一度追加
	var first_f_id = arr[0]
	if finger_positions.has(first_f_id):
		line.add_point(finger_positions[first_f_id])

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
	
	for i in range(arr.size()):
		if not finger_positions.has(arr[i]):
			continue
		var next_idx = (i + 1) % arr.size()
		if not finger_positions.has(arr[next_idx]):
			continue
		
		var p1 = finger_positions[arr[i]]
		var p2 = finger_positions[arr[next_idx]]
		
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

# ドラッグ終了時の処理
func _end_drag(mouse_pos: Vector2) -> void:
	if not is_dragging:
		return
	
	# ドロップ先の指を検出
	var dropped_finger_id := _find_finger_at(mouse_pos)
	
	if dropped_finger_id >= 0:
		# すでにその指に糸が掛かっていない場合のみフック
		if not string_manager.current_string.has(dropped_finger_id):
			segment_dropped_on_finger.emit(dragging_segment_index, dropped_finger_id)
	
	# ドラッグ状態をリセット（何もない場所でドロップした場合は元に戻る）
	is_dragging = false
	dragging_segment_index = -1
	update_line()
