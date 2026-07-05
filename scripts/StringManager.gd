class_name StringManager extends Node

var current_string: Array[int] = []
var target_string: Array[int] = []
var history: Array[Array] = []

signal string_changed

func _ready() -> void:
	pass

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
	if target_string.is_empty() or current_string.is_empty():
		return false
	
	# 1. 配列の正規化（最初と最後が重複している場合は最後の要素を削除）
	var current_norm = _normalize_sequence(current_string)
	var target_norm = _normalize_sequence(target_string)
	
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
