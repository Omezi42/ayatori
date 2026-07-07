class_name StringManager extends Node

var current_string: Array[int] = []
var target_string: Array[int] = []
var history: Array[Array] = []
var history_hook_times: Array[Array] = []
var hook_times: Array[int] = []
var current_time_counter: int = 0
var optimal_moves_cache: int = -1
var _hint_cache: Dictionary = {}
var _hint_cache_mutex: Mutex = Mutex.new()
var layout_id: int = 0

signal string_changed

func _ready() -> void:
	pass

# 現在の手数を取得する（historyのサイズ＝操作回数）
func get_move_count() -> int:
	return history.size()

# 履歴を保存する
func save_history() -> void:
	history.append(current_string.duplicate())
	history_hook_times.append(hook_times.duplicate())

# 糸を指定の指に掛ける（線分を引っ張って掛ける操作）
func hook_finger(segment_index: int, finger_id: int) -> void:
	save_history()
	current_time_counter += 1
	# segment_index と segment_index+1 の間に finger_id を挿入
	current_string.insert(segment_index + 1, finger_id)
	hook_times.insert(segment_index + 1, current_time_counter)
	string_changed.emit()

# 指定の指から糸を外す
func unhook_finger(index: int) -> void:
	# 糸が3本未満になる場合は外せないようにする（三角形が最小構成）
	if current_string.size() <= 3:
		return
	
	save_history()
	current_string.remove_at(index)
	hook_times.remove_at(index)
	string_changed.emit()

# 1手戻る
func undo() -> void:
	if history.size() > 0:
		current_string = history.pop_back()
		hook_times = history_hook_times.pop_back()
		string_changed.emit()

# リセット
func reset_to_initial(initial_state: Array[int]) -> void:
	history.clear()
	history_hook_times.clear()
	current_string = initial_state.duplicate()
	hook_times.clear()
	current_time_counter = 0
	for i in range(current_string.size()):
		hook_times.append(0)
	string_changed.emit()

# 特定の指に対して一番最後に掛けられた要素のインデックスを返す
func get_latest_index_of_finger(finger_id: int) -> int:
	var latest_idx = -1
	var max_time = -1
	for i in range(current_string.size()):
		if current_string[i] == finger_id:
			if hook_times.size() > i and hook_times[i] > max_time:
				max_time = hook_times[i]
				latest_idx = i
	return latest_idx

# 現在の配列が正解配列と一致するか判定する（シフト、逆順対応）
func check_clear() -> bool:
	return is_state_matching_target(current_string, target_string)

func get_edge_set(seq: Array[int]) -> Array:
	if seq.is_empty(): return []
	var norm = _normalize_sequence(seq)
	if norm.is_empty(): return []
	var edges = {}
	var positions = PinLayout.get_positions(layout_id)
	
	for i in range(norm.size()):
		var u = norm[i]
		var v = norm[(i + 1) % norm.size()]
		if u != v: # 無視（同じ点への自己ループは描画されない）
			var sub_edges = _get_sub_edges(u, v, positions)
			for edge_key in sub_edges:
				edges[edge_key] = true
	var keys = edges.keys()
	keys.sort()
	return keys

func _get_sub_edges(u: int, v: int, positions: Array[Vector2]) -> Array[String]:
	if positions.is_empty() or u < 0 or v < 0 or u >= positions.size() or v >= positions.size():
		return [str(min(u, v)) + "-" + str(max(u, v))]
		
	var pu = positions[u]
	var pv = positions[v]
	
	var points_on_line = []
	for w in range(positions.size()):
		var pw = positions[w]
		if w == u or w == v:
			points_on_line.append(w)
			continue
			
		# Bounding box check
		if min(pu.x, pv.x) <= pw.x and pw.x <= max(pu.x, pv.x) and \
		   min(pu.y, pv.y) <= pw.y and pw.y <= max(pu.y, pv.y):
			# Cross product check for collinearity
			var cross = (pw.x - pu.x) * (pv.y - pu.y) - (pw.y - pu.y) * (pv.x - pu.x)
			if abs(cross) < 0.1:
				points_on_line.append(w)
				
	# Sort points_on_line by distance to pu
	points_on_line.sort_custom(func(a, b): return pu.distance_squared_to(positions[a]) < pu.distance_squared_to(positions[b]))
	
	var sub_edges: Array[String] = []
	for k in range(points_on_line.size() - 1):
		var n1 = points_on_line[k]
		var n2 = points_on_line[k+1]
		if n1 != n2:
			sub_edges.append(str(min(n1, n2)) + "-" + str(max(n1, n2)))
			
	return sub_edges

func is_state_matching_target(state: Array[int], target: Array[int]) -> bool:
	if target.is_empty() or state.is_empty():
		return false
	
	var edges_s = get_edge_set(state)
	var edges_t = get_edge_set(target)
	
	if edges_s.size() == 0 or edges_t.size() == 0:
		return false
		
	if edges_s.size() != edges_t.size():
		return false
		
	for i in range(edges_s.size()):
		if edges_s[i] != edges_t[i]:
			return false
			
	return true

# 閉路を表す配列を正規化する（最初と最後が同じなら最後を取り除く）
func _normalize_sequence(seq: Array[int]) -> Array[int]:
	var res = seq.duplicate()
	if res.size() > 1 and res[0] == res[res.size() - 1]:
		res.pop_back()
	return res



# ヒント用：両方向BFS＋ヒューリスティック枝刈り＋正規化キャッシュによる高速かつ完全な最短ルート探索
# 次に行うべき最適アクションのディクショナリを返す
# 返り値の例:
# 掛ける場合: {"type": "hook", "finger": X, "segment_index": Y}
# 外す場合: {"type": "unhook", "finger": X, "index": Y}
# 一致している場合: {}
# 高速ヒント判定：キャッシュまたは1手先読みで求まる場合は即座に返し、重いBFS探索が必要な場合は {"_need_deep_search": true} を返す
func get_quick_hint(current: Array[int], target: Array[int]) -> Dictionary:
	if current.is_empty() or target.is_empty() or is_state_matching_target(current, target):
		return {}
		
	var current_norm = _normalize_sequence(current)
	var target_norm = _normalize_sequence(target)
	if current_norm.size() == 0 or target_norm.size() == 0:
		return {}
		
	var current_key = _get_canonical_key(current_norm)
	var target_key = _get_canonical_key(target_norm)
	if current_key == target_key:
		return {}
		
	var cache_key = current_key + "->" + target_key
	
	_hint_cache_mutex.lock()
	var has_cached = _hint_cache.has(cache_key)
	var cached_val = _hint_cache[cache_key] if has_cached else {}
	_hint_cache_mutex.unlock()
	if has_cached:
		return cached_val
		
	# 1手先読みチェック (1手でクリアできるなら即座に返す)
	var next_moves = _generate_next_moves(current_norm)
	for move_data in next_moves:
		if _get_canonical_key(move_data["next_state"]) == target_key:
			_hint_cache_mutex.lock()
			_hint_cache[cache_key] = move_data["move"]
			_hint_cache_mutex.unlock()
			return move_data["move"]
			
	return {"_need_deep_search": true}

func get_heuristic_hint(current: Array[int], target: Array[int]) -> Dictionary:
	if current.is_empty() or target.is_empty() or is_state_matching_target(current, target):
		return {}
		
	var current_norm = _normalize_sequence(current)
	var target_norm = _normalize_sequence(target)
	if current_norm.size() == 0 or target_norm.size() == 0:
		return {}
		
	var current_key = _get_canonical_key(current_norm)
	var target_key = _get_canonical_key(target_norm)
	if current_key == target_key:
		return {}
		
	var cache_key = current_key + "->" + target_key
	
	_hint_cache_mutex.lock()
	var has_cached = _hint_cache.has(cache_key)
	var cached_val = _hint_cache[cache_key] if has_cached else {}
	_hint_cache_mutex.unlock()
	if has_cached:
		return cached_val
		
	# 1. 1手先読みチェック (0次探索: 1手でクリアできるなら即座に返す)
	var next_moves = _generate_next_moves(current_norm)
	for move_data in next_moves:
		if _get_canonical_key(move_data["next_state"]) == target_key:
			_hint_cache_mutex.lock()
			_hint_cache[cache_key] = move_data["move"]
			_hint_cache_mutex.unlock()
			return move_data["move"]
			
	# 2. 両方向BFS (Bidirectional BFS) による最短手順の探索
	# フロンティア最小展開 + ヒューリスティック下界枝刈りで計算量を極限まで削減
	var best_move = _search_bidirectional_bfs(current_norm, target_norm, target_key)
	if not best_move.is_empty():
		_hint_cache_mutex.lock()
		_hint_cache[cache_key] = best_move
		_hint_cache_mutex.unlock()
		return best_move
		
	# 3. 万が一BFSの探索上限を超えた場合のフォールバック（スマートグリーディ）
	var fallback_move = _fallback_greedy_hint(current_norm, target_norm)
	_hint_cache_mutex.lock()
	_hint_cache[cache_key] = fallback_move
	_hint_cache_mutex.unlock()
	return fallback_move

# 状態の正規化キー（エッジセットに基づく最小表現）を取得
func _get_canonical_key(state: Array[int]) -> String:
	var edges = get_edge_set(state)
	return ",".join(edges)

# 両方向BFS探索による最短手生成
func _search_bidirectional_bfs(start_state: Array[int], target_state: Array[int], target_key: String) -> Dictionary:
	var max_depth_per_side = 6 # 最大計12手読み（全ステージ対応）
	var start_key = _get_canonical_key(start_state)
	
	var queue_forward: Array[Dictionary] = []
	var queue_backward: Array[Dictionary] = []
	
	# visited_forward: key -> {"depth": int, "first_move": Dictionary}
	var visited_forward = {}
	# visited_backward: key -> depth (int)
	var visited_backward = {}
	
	visited_forward[start_key] = {"depth": 0, "first_move": {}}
	queue_forward.push_back({"state": start_state, "depth": 0, "first_move": {}})
	
	visited_backward[target_key] = 0
	queue_backward.push_back({"state": target_state, "depth": 0})
	
	while queue_forward.size() > 0 and queue_backward.size() > 0:
		var size_f = queue_forward.size()
		var size_b = queue_backward.size()
		
		var best_total_depth = 999999
		var best_found_move = {}
		
		if size_f <= size_b:
			for _i in range(size_f):
				var curr = queue_forward.pop_front()
				var c_state: Array[int] = curr["state"]
				var c_depth: int = curr["depth"]
				var f_move: Dictionary = curr["first_move"]
				
				if c_depth >= max_depth_per_side:
					continue
				if c_depth + _heuristic_distance(c_state, target_state) > max_depth_per_side * 2:
					continue
					
				var next_moves = _generate_next_moves(c_state)
				for move_data in next_moves:
					var nxt_state: Array[int] = move_data["next_state"]
					var nxt_key = _get_canonical_key(nxt_state)
					var move_to_record = f_move if not f_move.is_empty() else move_data["move"]
					
					if visited_backward.has(nxt_key):
						var total_d = c_depth + 1 + visited_backward[nxt_key]
						if total_d < best_total_depth:
							best_total_depth = total_d
							best_found_move = move_to_record
					else:
						if not visited_forward.has(nxt_key):
							visited_forward[nxt_key] = {"depth": c_depth + 1, "first_move": move_to_record}
							queue_forward.push_back({"state": nxt_state, "depth": c_depth + 1, "first_move": move_to_record})
		else:
			for _i in range(size_b):
				var curr = queue_backward.pop_front()
				var c_state: Array[int] = curr["state"]
				var c_depth: int = curr["depth"]
				
				if c_depth >= max_depth_per_side:
					continue
				if c_depth + _heuristic_distance(c_state, start_state) > max_depth_per_side * 2:
					continue
					
				var next_moves = _generate_next_moves(c_state)
				for move_data in next_moves:
					var nxt_state: Array[int] = move_data["next_state"]
					var nxt_key = _get_canonical_key(nxt_state)
					
					if visited_forward.has(nxt_key):
						var total_d = c_depth + 1 + visited_forward[nxt_key]["depth"]
						if total_d < best_total_depth:
							best_total_depth = total_d
							best_found_move = visited_forward[nxt_key]["first_move"]
					else:
						if not visited_backward.has(nxt_key):
							visited_backward[nxt_key] = c_depth + 1
							queue_backward.push_back({"state": nxt_state, "depth": c_depth + 1})
							
		if not best_found_move.is_empty():
			return best_found_move
			
	return {}

# ヒューリスティック距離（エッジ集合差分による下界推定）
func _heuristic_distance(state1: Array[int], state2: Array[int]) -> int:
	var set1 = {}
	for e in get_edge_set(state1): set1[e] = true
	var set2 = {}
	for e in get_edge_set(state2): set2[e] = true
	
	var diff1 = 0
	for e in get_edge_set(state1):
		if not set2.has(e): diff1 += 1
	var diff2 = 0
	for e in get_edge_set(state2):
		if not set1.has(e): diff2 += 1
	return diff1 + diff2

# 可能で合法な全ての手と次状態を生成する
func _generate_next_moves(state: Array[int]) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var state_set = {}
	for x in state: state_set[x] = true
	
	var is_advanced = false
	if Engine.has_singleton("GameSave"):
		var gs = Engine.get_singleton("GameSave")
		if gs and gs.has_method("has_rule"):
			is_advanced = gs.has_rule("multi_loop")
	elif is_inside_tree() and has_node("/root/GameSave"):
		var gs = get_node("/root/GameSave")
		if gs and gs.has_method("has_rule"):
			is_advanced = gs.has_rule("multi_loop")
	# Fallback if GameSave is autoloaded
	elif typeof(GameSave) == TYPE_OBJECT:
		if GameSave.has_method("has_rule"):
			is_advanced = GameSave.has_rule("multi_loop")
	
	# 掛ける操作 (hook)
	for f in range(10):
		if is_advanced or not state_set.has(f):
			for i in range(state.size()):
				# 拡張モード時は、隣接する同じ指に掛けるような無意味な操作を枝刈り
				if is_advanced:
					var prev_f = state[i]
					var next_f = state[(i + 1) % state.size()]
					if f == prev_f or f == next_f:
						continue
						
				var nxt = state.duplicate()
				nxt.insert(i + 1, f)
				results.append({"move": {"type": "hook", "finger": f, "segment_index": i}, "next_state": nxt})
				
	# 外す操作 (unhook)
	if state.size() > 3:
		for i in range(state.size()):
			var nxt = state.duplicate()
			var removed = nxt[i]
			nxt.remove_at(i)
			results.append({"move": {"type": "unhook", "finger": removed, "index": i}, "next_state": nxt})
			
	return results

# BFS上限を超えた場合のスマートなグリーディフォールバック
func _fallback_greedy_hint(current_norm: Array[int], target_norm: Array[int]) -> Dictionary:
	var current_set = {}
	for f in current_norm: current_set[f] = true
	var target_set = {}
	for f in target_norm: target_set[f] = true
	
	var is_advanced = false
	if typeof(GameSave) == TYPE_OBJECT and GameSave.has_method("has_rule"):
		is_advanced = GameSave.has_rule("multi_loop")
	
	# 1. 目標にない指があれば外す (非拡張時のみ、または拡張時でも不要な指なら)
	if current_norm.size() > 3:
		for i in range(current_norm.size()):
			if not target_set.has(current_norm[i]):
				return {"type": "unhook", "finger": current_norm[i], "index": i}
				
	# 2. 目標にあるが現在ない指があれば、目標配列で隣接する指の間のセグメントに掛ける
	# 拡張モードでは、目標配列にあって現在不足しているエッジを構成する指に掛ける
	for f in target_norm:
		if is_advanced or not current_set.has(f):
			var target_idx = target_norm.find(f)
			var prev_f = target_norm[(target_idx - 1 + target_norm.size()) % target_norm.size()]
			var next_f = target_norm[(target_idx + 1) % target_norm.size()]
			
			var best_seg = 0
			var found_best = false
			for i in range(current_norm.size()):
				if current_norm[i] == prev_f or current_norm[(i + 1) % current_norm.size()] == next_f:
					best_seg = i
					found_best = true
					break
			if found_best and (is_advanced or not current_set.has(f)):
				return {"type": "hook", "finger": f, "segment_index": best_seg}
			elif not is_advanced and not current_set.has(f):
				return {"type": "hook", "finger": f, "segment_index": 0}
			
	# 3. 指の種類は合っているが並びが違う場合、適当な指を外して再構成を促す
	if current_norm.size() > 3:
		return {"type": "unhook", "finger": current_norm[0], "index": 0}
		
	return {}

# 最短手数を計算して返す（双方向BFS）
func calculate_optimal_moves_count(start_state: Array[int], target_state: Array[int]) -> int:
	var max_depth_per_side = 6 # 最大計12手読み
	var start_key = _get_canonical_key(start_state)
	var target_key = _get_canonical_key(target_state)
	if start_key == target_key:
		return 0
		
	var queue_forward: Array[Array] = []
	var queue_backward: Array[Array] = []
	
	var visited_forward = {}
	var visited_backward = {}
	
	visited_forward[start_key] = 0
	queue_forward.push_back([start_state, 0])
	
	visited_backward[target_key] = 0
	queue_backward.push_back([target_state, 0])
	
	while queue_forward.size() > 0 and queue_backward.size() > 0:
		var size_f = queue_forward.size()
		var size_b = queue_backward.size()
		
		if size_f <= size_b:
			for _i in range(size_f):
				var curr = queue_forward.pop_front()
				var c_state: Array[int] = curr[0]
				var c_depth: int = curr[1]
				
				if c_depth >= max_depth_per_side:
					continue
				if c_depth + _heuristic_distance(c_state, target_state) > max_depth_per_side * 2:
					continue
					
				for move_data in _generate_next_moves(c_state):
					var nxt_state: Array[int] = move_data["next_state"]
					var nxt_key = _get_canonical_key(nxt_state)
					
					if visited_backward.has(nxt_key):
						return c_depth + 1 + visited_backward[nxt_key]
					if not visited_forward.has(nxt_key):
						visited_forward[nxt_key] = c_depth + 1
						queue_forward.push_back([nxt_state, c_depth + 1])
		else:
			for _i in range(size_b):
				var curr = queue_backward.pop_front()
				var c_state: Array[int] = curr[0]
				var c_depth: int = curr[1]
				
				if c_depth >= max_depth_per_side:
					continue
				if c_depth + _heuristic_distance(c_state, start_state) > max_depth_per_side * 2:
					continue
					
				for move_data in _generate_next_moves(c_state):
					var nxt_state: Array[int] = move_data["next_state"]
					var nxt_key = _get_canonical_key(nxt_state)
					
					if visited_forward.has(nxt_key):
						return c_depth + 1 + visited_forward[nxt_key]
					if not visited_backward.has(nxt_key):
						visited_backward[nxt_key] = c_depth + 1
						queue_backward.push_back([nxt_state, c_depth + 1])
						
	return -1
