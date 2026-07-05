class_name StringManager extends Node

var current_string: Array[int] = []
var target_string: Array[int] = []
var history: Array[Array] = []
var optimal_moves_cache: int = -1

signal string_changed

func _ready() -> void:
	pass

# 現在の手数を取得する（historyのサイズ＝操作回数）
func get_move_count() -> int:
	return history.size()

# 履歴を保存する
func save_history() -> void:
	history.append(current_string.duplicate())

# 糸を指定の指に掛ける（線分を引っ張って掛ける操作）
func hook_finger(segment_index: int, finger_id: int) -> void:
	save_history()
	# segment_index と segment_index+1 の間に finger_id を挿入
	current_string.insert(segment_index + 1, finger_id)
	string_changed.emit()

# 指定の指から糸を外す
func unhook_finger(index: int) -> void:
	# 糸が3本未満になる場合は外せないようにする（三角形が最小構成）
	if current_string.size() <= 3:
		return
	
	save_history()
	current_string.remove_at(index)
	string_changed.emit()

# 1手戻る
func undo() -> void:
	if history.size() > 0:
		current_string = history.pop_back()
		string_changed.emit()

# リセット
func reset_to_initial(initial_state: Array[int]) -> void:
	history.clear()
	current_string = initial_state.duplicate()
	string_changed.emit()

# 現在の配列が正解配列と一致するか判定する（シフト、逆順対応）
func check_clear() -> bool:
	return is_state_matching_target(current_string, target_string)

func is_state_matching_target(state: Array[int], target: Array[int]) -> bool:
	if target.is_empty() or state.is_empty():
		return false
	
	# 1. 配列の正規化（最初と最後が重複している場合は最後の要素を削除）
	var current_norm = _normalize_sequence(state)
	var target_norm = _normalize_sequence(target)
	
	# 正規化後の要素数が異なる場合は不一致
	if current_norm.size() != target_norm.size():
		return false
		
	# 要素数が0の場合はクリア扱いにはしない（あるいは仕様次第）
	if current_norm.size() == 0:
		return false
		
	var length = target_norm.size()
	
	# 2. シフト比較のためのダミー配列を作成 (2周分を連結)
	var dummy: Array[int] = []
	dummy.append_array(current_norm)
	dummy.append_array(current_norm)
	
	# 3. 順方向（右回り等）のシフト一致確認
	if _contains_sub_array(dummy, target_norm):
		return true
		
	# 4. 逆順（リバース・左回り等）のシフト一致確認
	var reversed_target = target_norm.duplicate()
	reversed_target.reverse()
	if _contains_sub_array(dummy, reversed_target):
		return true
		
	return false

# 閉路を表す配列を正規化する（最初と最後が同じなら最後を取り除く）
func _normalize_sequence(seq: Array[int]) -> Array[int]:
	var res = seq.duplicate()
	if res.size() > 1 and res[0] == res[res.size() - 1]:
		res.pop_back()
	return res

# dummy_array の中に target_sub_array が連続して含まれるかチェックするヘルパー
func _contains_sub_array(dummy_array: Array[int], target_sub_array: Array[int]) -> bool:
	var sub_len = target_sub_array.size()
	for i in range(dummy_array.size() - sub_len + 1):
		var match_found = true
		for j in range(sub_len):
			if dummy_array[i + j] != target_sub_array[j]:
				match_found = false
				break
		if match_found:
			return true
	return false

# ヒント用：直感的で軽量なロジック
# 次に行うべきアクションのディクショナリを返す
# 返り値の例:
# 掛ける場合: {"type": "hook", "finger": X}
# 外す場合: {"type": "unhook", "finger": X}
# 一致している場合: {}
func get_heuristic_hint(current: Array[int], target: Array[int]) -> Dictionary:
	if current.is_empty() or target.is_empty() or is_state_matching_target(current, target):
		return {}
		
	var current_set = {}
	for f in current: current_set[f] = true
	var target_set = {}
	for f in target: target_set[f] = true
	
	# 1. 優先度高：現在の形にあり、目標の形にない指があれば、外すヒントを出す
	if current.size() > 3:
		for f in current:
			if not target_set.has(f):
				return {"type": "unhook", "finger": f}
				
	# 2. 優先度中：目標の形にあり、現在の形にない指があれば、掛けるヒントを出す
	for f in target:
		if not current_set.has(f):
			return {"type": "hook", "finger": f}
			
	# 3. 優先度低：使っている指の種類はすべて合っているが、順番が違う場合
	# (この場合は、構成要素のどれか1つを外して再度掛けるよう促すのが一番シンプル)
	if current.size() > 3:
		return {"type": "unhook", "finger": current[0]} # とりあえず最初の要素を外させる
		
	return {}

