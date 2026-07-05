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

# BFSで最短手数を計算する
func calculate_optimal_moves(initial_state: Array[int], target_state: Array[int]) -> int:
	if is_state_matching_target(initial_state, target_state):
		return 0
		
	var queue: Array = []
	var visited: Dictionary = {}
	
	var start_norm = _normalize_sequence(initial_state)
	var start_hash = _hash_state(start_norm)
	
	queue.append({"state": start_norm, "depth": 0})
	visited[start_hash] = true
	
	# 最大深さ（あまり深く探索しすぎないためのフェイルセーフ）
	var MAX_DEPTH = 10
	
	while not queue.is_empty():
		var current = queue.pop_front()
		var state: Array[int] = current["state"]
		var depth: int = current["depth"]
		
		if depth >= MAX_DEPTH:
			continue
			
		var next_depth = depth + 1
		var next_states = _generate_next_states(state)
		
		for next_state in next_states:
			var norm = _normalize_sequence(next_state)
			if is_state_matching_target(norm, target_state):
				return next_depth
				
			var h = _hash_state(norm)
			if not visited.has(h):
				visited[h] = true
				queue.append({"state": norm, "depth": next_depth})
				
	return MAX_DEPTH # 見つからなかった場合のフォールバック

# ヒント用：次の一手（状態）を返す
func get_next_hint(initial_state: Array[int], target_state: Array[int]) -> Array[int]:
	if is_state_matching_target(initial_state, target_state):
		return []
		
	var queue: Array = []
	var visited: Dictionary = {}
	var parent_map: Dictionary = {}
	
	var start_norm = _normalize_sequence(initial_state)
	var start_hash = _hash_state(start_norm)
	
	queue.append({"state": start_norm, "depth": 0})
	visited[start_hash] = true
	
	var MAX_DEPTH = 10
	var found_target_hash = ""
	
	while not queue.is_empty():
		var current = queue.pop_front()
		var state: Array[int] = current["state"]
		var depth: int = current["depth"]
		var curr_hash = _hash_state(state)
		
		if is_state_matching_target(state, target_state):
			found_target_hash = curr_hash
			break
			
		if depth >= MAX_DEPTH:
			continue
			
		var next_states = _generate_next_states(state)
		for next_state in next_states:
			var norm = _normalize_sequence(next_state)
			var h = _hash_state(norm)
			if not visited.has(h):
				visited[h] = true
				parent_map[h] = {"parent_hash": curr_hash, "state": norm.duplicate()}
				queue.append({"state": norm, "depth": depth + 1})
				
	if found_target_hash == "":
		return []
		
	var curr = found_target_hash
	var result_state = []
	# 逆算してstart_hashの1つ次の状態を見つける
	while parent_map.has(curr):
		var p_hash = parent_map[curr]["parent_hash"]
		if p_hash == start_hash:
			result_state = parent_map[curr]["state"]
			break
		curr = p_hash
		
	return result_state

func _hash_state(state: Array[int]) -> String:
	# 順序に依存しない表現か、単純な文字列化
	# ※シフトや逆順で同じとみなせる場合は同じハッシュにするのが理想だが、
	# 簡単のため文字列化（BFSの枝刈りは少し弱くなる）
	return str(state)

func _generate_next_states(state: Array[int]) -> Array[Array]:
	var results: Array[Array] = []
	var available_fingers = []
	for i in range(10):
		if not state.has(i):
			available_fingers.append(i)
			
	# hook_finger: 任意の2つの要素の間に、まだ使っていない指を挿入
	for finger in available_fingers:
		for i in range(state.size()):
			var next_state = state.duplicate()
			next_state.insert(i + 1, finger)
			results.append(next_state)
			
	# unhook_finger: 要素数が3より大きい場合、任意の要素を削除
	if state.size() > 3:
		for i in range(state.size()):
			var next_state = state.duplicate()
			next_state.remove_at(i)
			results.append(next_state)
			
	return results
