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

# 現在の配列が正解配列と一致するか判定する（シフト、リバース対応）
func check_match() -> bool:
	if target_string.is_empty() or current_string.size() != target_string.size():
		return false
	
	var length = target_string.size()
	# ダミー配列を作成 (2周分)
	var dummy: Array[int] = []
	dummy.append_array(current_string)
	dummy.append_array(current_string)
	
	# 順方向の一致確認
	if _contains_sub_array(dummy, target_string):
		return true
		
	# 逆方向の一致確認
	var reversed_target = target_string.duplicate()
	reversed_target.reverse()
	if _contains_sub_array(dummy, reversed_target):
		return true
		
	return false

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
