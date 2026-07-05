class_name StringDrawer extends Node2D

@export var line: Line2D
@export var string_manager: StringManager

# 指IDをキーとして、その指のローカル座標(Vector2)を保持する辞書
var finger_positions: Dictionary = {}

# ドラッグ状態管理
var is_dragging: bool = false
var dragging_segment_index: int = -1
var current_mouse_pos: Vector2 = Vector2.ZERO

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
	# 線分のドラッグ判定用 (クリック)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_try_start_drag(event.position)
		else:
			_end_drag(event.position)

# 全ての指ノードを登録する
func register_finger(finger_id: int, pos: Vector2) -> void:
	finger_positions[finger_id] = pos

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
func _try_start_drag(mouse_pos: Vector2) -> void:
	if string_manager.current_string.size() < 2:
		return
		
	# 簡易的に、線分からの距離を計算して判定
	var arr = string_manager.current_string
	for i in range(arr.size()):
		var p1 = finger_positions[arr[i]]
		var next_idx = (i + 1) % arr.size()
		var p2 = finger_positions[arr[next_idx]]
		
		# 線分とマウス位置の距離計算 (Geometry2D.segment_intersects_circle等を使うか数学で算出)
		var closest = Geometry2D.get_closest_point_to_segment(mouse_pos, p1, p2)
		var dist = mouse_pos.distance_to(closest)
		
		if dist < 20.0: # ヒット半径
			is_dragging = true
			dragging_segment_index = i
			current_mouse_pos = mouse_pos
			break

func _end_drag(_mouse_pos: Vector2) -> void:
	if is_dragging:
		is_dragging = false
		dragging_segment_index = -1
		update_line()
