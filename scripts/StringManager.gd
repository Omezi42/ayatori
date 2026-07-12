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
var _sub_edges_cache: Dictionary = {}
var _pair_mask_cache: Dictionary = {}
var _cached_target_string: Array[int] = []
var _cached_target_edges: Array = []
var _cached_target_mask: int = -1

signal string_changed

func _ready() -> void:
	pass

func _get_sound_manager() -> Node:
	if Engine.has_singleton("SoundManager"):
		return Engine.get_singleton("SoundManager")
	var loop = Engine.get_main_loop()
	if loop is SceneTree and loop.root and loop.root.has_node("SoundManager"):
		return loop.root.get_node("SoundManager")
	return null

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
	current_string.insert(segment_index + 1, finger_id)
	hook_times.insert(segment_index + 1, current_time_counter)
	var sm = _get_sound_manager()
	if sm:
		sm.play_se("string_hook")
	string_changed.emit()

# 指定の指から糸を外す
func unhook_finger(index: int) -> void:
	if current_string.size() <= 3:
		return
	save_history()
	current_string.remove_at(index)
	hook_times.remove_at(index)
	var sm = _get_sound_manager()
	if sm:
		sm.play_se("string_unhook")
	string_changed.emit()

# 1手戻る
func undo() -> void:
	if history.size() > 0:
		current_string = history.pop_back()
		hook_times = history_hook_times.pop_back()
		var sm = _get_sound_manager()
		if sm:
			sm.play_se("undo")
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
	var sm = _get_sound_manager()
	if sm:
		sm.play_se("reset")
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

# 現在の配列が正解配列と一致するか判定する
func check_clear() -> bool:
	return is_state_matching_target(current_string, target_string)

# 高速ビットマスクインデクシング (45通りのペアを 64bit int の各ビットに割り当て)
func _get_bit_index(a: int, b: int) -> int:
	if a > b:
		var tmp = a
		a = b
		b = tmp
	return a * 10 - (a * (a + 1)) / 2 + (b - a - 1)

func _get_pair_mask(u: int, v: int) -> int:
	var cache_key = layout_id * 100 + u * 10 + v
	if _pair_mask_cache.has(cache_key):
		return _pair_mask_cache[cache_key]
	
	var positions = PinLayout.get_positions(layout_id)
	var sub_edges = _get_sub_edges(u, v, positions)
	var mask: int = 0
	for s in sub_edges:
		var parts = s.split("-")
		var a = int(parts[0])
		var b = int(parts[1])
		var bit_idx = _get_bit_index(a, b)
		mask |= (1 << bit_idx)
	_pair_mask_cache[cache_key] = mask
	return mask

func get_edge_mask(seq: Array) -> int:
	if seq.is_empty(): return 0
	var norm = _normalize_sequence(seq)
	if norm.is_empty(): return 0
	var mask: int = 0
	for i in range(norm.size()):
		var u = norm[i]
		var v = norm[(i + 1) % norm.size()]
		if u != v:
			mask |= _get_pair_mask(u, v)
	return mask

func get_edge_set(seq: Array) -> Array:
	if seq.is_empty(): return []
	var norm = _normalize_sequence(seq)
	if norm.is_empty(): return []
	var edges = {}
	var positions = PinLayout.get_positions(layout_id)
	
	for i in range(norm.size()):
		var u = norm[i]
		var v = norm[(i + 1) % norm.size()]
		if u != v:
			var sub_edges = _get_sub_edges(u, v, positions)
			for edge_key in sub_edges:
				edges[edge_key] = true
	var keys = edges.keys()
	keys.sort()
	return keys

func _get_sub_edges(u: int, v: int, positions: Array[Vector2]) -> Array[String]:
	var cache_key = str(layout_id) + "_" + str(min(u, v)) + "-" + str(max(u, v))
	if _sub_edges_cache.has(cache_key):
		return _sub_edges_cache[cache_key]

	if positions.is_empty() or u < 0 or v < 0 or u >= positions.size() or v >= positions.size():
		var res: Array[String] = [str(min(u, v)) + "-" + str(max(u, v))]
		_sub_edges_cache[cache_key] = res
		return res
		
	var pu = positions[u]
	var pv = positions[v]
	
	var points_on_line = []
	for w in range(positions.size()):
		var pw = positions[w]
		if w == u or w == v:
			points_on_line.append(w)
			continue
			
		if min(pu.x, pv.x) <= pw.x and pw.x <= max(pu.x, pv.x) and \
		   min(pu.y, pv.y) <= pw.y and pw.y <= max(pu.y, pv.y):
			var cross = (pw.x - pu.x) * (pv.y - pu.y) - (pw.y - pu.y) * (pv.x - pu.x)
			if abs(cross) < 0.1:
				points_on_line.append(w)
				
	points_on_line.sort_custom(func(a, b): return pu.distance_squared_to(positions[a]) < pu.distance_squared_to(positions[b]))
	
	var sub_edges: Array[String] = []
	for k in range(points_on_line.size() - 1):
		var n1 = points_on_line[k]
		var n2 = points_on_line[k+1]
		if n1 != n2:
			sub_edges.append(str(min(n1, n2)) + "-" + str(max(n1, n2)))
			
	_sub_edges_cache[cache_key] = sub_edges
	return sub_edges

func _get_state_key(state: Array[int], is_advanced: bool) -> int:
	var mask = get_edge_mask(state)
	if is_advanced:
		return mask
	var pin_bits = 0
	for p in state:
		pin_bits |= (1 << p)
	return (mask << 10) | pin_bits

func is_state_matching_target(state: Array[int], target: Array[int]) -> bool:
	if target.is_empty() or state.is_empty():
		return false
	
	if layout_id >= 3:
		var set_s = get_edge_set(state)
		var set_t: Array = []
		if target == _cached_target_string and not _cached_target_edges.is_empty():
			set_t = _cached_target_edges
		else:
			set_t = get_edge_set(target)
			_cached_target_string = target.duplicate()
			_cached_target_edges = set_t.duplicate()
		return set_s == set_t and not set_s.is_empty()
	else:
		var mask_s = get_edge_mask(state)
		var mask_t: int = 0
		if target == _cached_target_string and _cached_target_mask != -1:
			mask_t = _cached_target_mask
		else:
			mask_t = get_edge_mask(target)
			_cached_target_string = target.duplicate()
			_cached_target_mask = mask_t
		
		return mask_s == mask_t and mask_s != 0

func _normalize_sequence(seq: Array) -> Array[int]:
	var res: Array[int] = []
	for x in seq:
		res.append(int(x))
	if res.size() > 1 and res[0] == res[res.size() - 1]:
		res.pop_back()
	return res

func _get_canonical_key(seq: Array) -> String:
	var norm = _normalize_sequence(seq)
	if norm.is_empty():
		return "[]"
	var n = norm.size()
	var best_key = str(norm)
	for i in range(n):
		var shifted: Array[int] = []
		for j in range(n):
			shifted.append(norm[(i + j) % n])
		var shifted_str = str(shifted)
		if shifted_str < best_key:
			best_key = shifted_str
		var reversed_shifted = shifted.duplicate()
		reversed_shifted.reverse()
		var reversed_str = str(reversed_shifted)
		if reversed_str < best_key:
			best_key = reversed_str
	return best_key

# ============================================================
# ヒント用：高速ビットマスク双方向BFS＋キャッシュ
# ============================================================
func get_quick_hint(current: Array[int], target: Array[int]) -> Dictionary:
	if current.is_empty() or target.is_empty() or is_state_matching_target(current, target):
		return {}
		
	var current_mask = get_edge_mask(current)
	var target_mask = get_edge_mask(target)
	if current_mask == target_mask:
		return {}
		
	var cache_key = str(layout_id) + ":" + str(current_mask) + "->" + str(target_mask)
	
	_hint_cache_mutex.lock()
	var has_cached = _hint_cache.has(cache_key)
	var cached_val = _hint_cache[cache_key] if has_cached else {}
	_hint_cache_mutex.unlock()
	if has_cached:
		return cached_val
		
	return {"_need_deep_search": true}

func get_heuristic_hint_async(current: Array[int], target: Array[int]) -> Dictionary:
	if current.is_empty() or target.is_empty() or is_state_matching_target(current, target):
		return {}
		
	var current_mask = get_edge_mask(current)
	var target_mask = get_edge_mask(target)
	if current_mask == target_mask:
		return {}
		
	var cache_key = str(layout_id) + ":" + str(current_mask) + "->" + str(target_mask)
	
	_hint_cache_mutex.lock()
	var has_cached = _hint_cache.has(cache_key)
	var cached_val = _hint_cache[cache_key] if has_cached else {}
	_hint_cache_mutex.unlock()
	if has_cached:
		return cached_val
		
	# 1. 1手先読みチェック
	var next_moves = _generate_next_moves(current)
	for move_data in next_moves:
		if get_edge_mask(move_data["next_state"]) == target_mask:
			_hint_cache_mutex.lock()
			_hint_cache[cache_key] = move_data["move"]
			_hint_cache_mutex.unlock()
			return move_data["move"]
			
	# 2. 高速ビットマスク双方向BFSによる最短手の1手目を探索
	var best_move = await _search_hint_bfs_bidirectional_async(current, target)
	if not best_move.is_empty():
		_hint_cache_mutex.lock()
		_hint_cache[cache_key] = best_move
		_hint_cache_mutex.unlock()
		return best_move
		
	# 3. BFS上限を超えた場合のスマートフォールバック
	var fallback_move = _fallback_greedy_hint(current, target)
	_hint_cache_mutex.lock()
	_hint_cache[cache_key] = fallback_move
	_hint_cache_mutex.unlock()
	return fallback_move

func _count_bits(n: int) -> int:
	var count = 0
	while n != 0:
		n &= n - 1
		count += 1
	return count

func _heuristic_distance_mask(mask1: int, mask2: int) -> int:
	var missing = _count_bits(mask2 & ~mask1)
	var extra = _count_bits(mask1 & ~mask2)
	return max(missing, extra)

# 双方向BFSによる超高速・正確なヒント探索
func _search_hint_bfs_bidirectional_async(start_state: Array[int], target_state: Array[int], override_is_advanced: int = -1) -> Dictionary:
	var max_depth = 16
	var max_nodes = 600000
	var nodes_expanded = 0
	var start_time_msec = Time.get_ticks_msec()
	var max_time_msec = 5000
	var frame_start_msec = Time.get_ticks_msec()
	
	var is_advanced = _get_is_advanced() if override_is_advanced == -1 else (override_is_advanced == 1)
	var start_mask = get_edge_mask(start_state)
	var target_mask = get_edge_mask(target_state)
	if start_mask == target_mask:
		return {}
		
	var start_key = _get_state_key(start_state, is_advanced)
	var visited = {start_key: true}
	var visited_history = {}
	for h in history:
		visited_history[_get_state_key(h, is_advanced)] = true
	visited_history[start_key] = true
	
	var queue_forward: Array[Array] = [[start_state, 0, {}]]
	var head_f = 0
	
	while head_f < queue_forward.size():
		if nodes_expanded >= max_nodes or (Time.get_ticks_msec() - start_time_msec > max_time_msec):
			break
			
		if nodes_expanded % 1000 == 0 and Time.get_ticks_msec() - frame_start_msec > 5:
			if Engine.get_main_loop() and Engine.get_main_loop().has_signal("process_frame"):
				await Engine.get_main_loop().process_frame
			frame_start_msec = Time.get_ticks_msec()
			
		var curr = queue_forward[head_f]
		head_f += 1
		var c_state: Array[int] = curr[0]
		var c_depth: int = curr[1]
		var f_move: Dictionary = curr[2]
		
		if c_depth >= max_depth:
			break
			
		nodes_expanded += 1
		for move_data in _generate_next_moves(c_state, override_is_advanced):
			var nxt_state: Array[int] = move_data["next_state"]
			var nxt_mask = get_edge_mask(nxt_state)
			var nxt_key = _get_state_key(nxt_state, is_advanced)
			if visited_history.has(nxt_key) and nxt_mask != target_mask:
				continue
			var new_depth = c_depth + 1
			var move_to_record = f_move if not f_move.is_empty() else move_data["move"]
			
			if nxt_mask == target_mask:
				return move_to_record
				
			if not visited.has(nxt_key):
				visited[nxt_key] = true
				queue_forward.push_back([nxt_state, new_depth, move_to_record])
				
	return {}

# 可能で合法な全ての手と次状態を生成する
func _generate_next_moves(state: Array[int], override_is_advanced: int = -1) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var state_set = {}
	for x in state: state_set[x] = true
	var c_mask = get_edge_mask(state)
	
	var is_advanced = _get_is_advanced() if override_is_advanced == -1 else (override_is_advanced == 1)
	
	# 掛ける操作 (hook)
	var total_fingers = PinLayout.get_positions(layout_id).size()
	for f in range(total_fingers):
		if is_advanced or not state_set.has(f):
			for i in range(state.size()):
				if is_advanced:
					var prev_f = state[i]
					var next_f = state[(i + 1) % state.size()]
					if f == prev_f or f == next_f:
						continue
						
				var nxt = state.duplicate()
				nxt.insert(i + 1, f)
				if get_edge_mask(nxt) != c_mask:
					results.append({"move": {"type": "hook", "finger": f, "segment_index": i}, "next_state": nxt})
				
	# 外す操作 (unhook)
	if state.size() > 3:
		for i in range(state.size()):
			var nxt = state.duplicate()
			var removed = nxt[i]
			nxt.remove_at(i)
			if get_edge_mask(nxt) != c_mask:
				results.append({"move": {"type": "unhook", "finger": removed, "index": i}, "next_state": nxt})
			
	return results

func _get_is_advanced() -> bool:
	if Engine.has_singleton("GameSave"):
		var gs = Engine.get_singleton("GameSave")
		if gs and gs.has_method("has_rule"):
			return gs.has_rule("multi_loop")
	if Engine.get_main_loop() and Engine.get_main_loop() is SceneTree and Engine.get_main_loop().root and Engine.get_main_loop().root.is_inside_tree() and Engine.get_main_loop().root.has_node("/root/GameSave"):
		var gs = Engine.get_main_loop().root.get_node("/root/GameSave")
		if gs and gs.has_method("has_rule"):
			return gs.has_rule("multi_loop")
	return false

# ビットマスク差分に基づく最適グリーディフォールバック
func _fallback_greedy_hint(current: Array[int], target: Array[int]) -> Dictionary:
	var is_advanced = _get_is_advanced()
	var current_mask = get_edge_mask(current)
	var target_mask = get_edge_mask(target)
	var visited_history = {}
	for h in history:
		visited_history[_get_state_key(h, is_advanced)] = true
	visited_history[_get_state_key(current, is_advanced)] = true
	
	var best_move: Dictionary = {}
	var best_dist = 999999
	
	for move_data in _generate_next_moves(current):
		var nxt_state: Array[int] = move_data["next_state"]
		var nxt_mask = get_edge_mask(nxt_state)
		var nxt_key = _get_state_key(nxt_state, is_advanced)
		if visited_history.has(nxt_key) and nxt_mask != target_mask:
			continue
		var dist = _heuristic_distance_mask(nxt_mask, target_mask)
		if dist < best_dist:
			best_dist = dist
			best_move = move_data["move"]
			
	if not best_move.is_empty():
		return best_move
		
	for move_data in _generate_next_moves(current):
		return move_data["move"]
		
	if current.size() > 3:
		return {"type": "unhook", "finger": current[0], "index": 0}
	return {}

# ============================================================
# 最短手数計算（高速インライン合流探索 BFS）
# ============================================================
func calculate_optimal_moves(start_state: Array[int], target_state: Array[int], override_is_advanced: int = -1, max_time_msec: int = 2500) -> int:
	return calculate_optimal_moves_count(start_state, target_state, override_is_advanced, max_time_msec)

func calculate_optimal_moves_count(start_state: Array[int], target_state: Array[int], override_is_advanced: int = -1, max_time_msec: int = 2500) -> int:
	var start_mask = get_edge_mask(start_state)
	var target_mask = get_edge_mask(target_state)
	if start_mask == target_mask:
		return 0
	
	var is_advanced = _get_is_advanced() if override_is_advanced == -1 else (override_is_advanced == 1)
	var total_fingers = PinLayout.get_positions(layout_id).size()
	
	var candidate_fingers = []
	if total_fingers <= 10:
		for f in range(total_fingers): candidate_fingers.append(f)
	else:
		var active_pins = {}
		for p in start_state: active_pins[p] = true
		for p in target_state: active_pins[p] = true
		for p in active_pins.keys():
			var px = p % 10
			var py = p / 10
			for dy in range(-3, 4):
				for dx in range(-3, 4):
					var nx = px + dx
					var ny = py + dy
					if nx >= 0 and nx < 10 and ny >= 0 and ny < 10:
						candidate_fingers.append(ny * 10 + nx)
		# 重複削除とソート
		var uniq = {}
		for f in candidate_fingers: uniq[f] = true
		candidate_fingers = uniq.keys()
		candidate_fingers.sort()
	
	var _fast_table = []
	for u in range(total_fingers):
		var row = []
		for v in range(total_fingers):
			row.append(_get_pair_mask(u, v))
		_fast_table.append(row)
		
	var start_key = _get_state_key(start_state, is_advanced)
	var visited = {start_key: 0}
	var queue_forward: Array[Array] = [[start_state, 0, start_mask]]
	var head_f = 0
	var start_time_msec = Time.get_ticks_msec()
	
	var visited_backward = {_get_state_key(target_state, is_advanced): 0}
	var queue_backward: Array[Array] = [[target_state, 0, target_mask]]
	var head_b = 0
	var best_moves = 999
	
	while head_f < queue_forward.size() or head_b < queue_backward.size():
		if (head_f + head_b) % 500 == 0 and Time.get_ticks_msec() - start_time_msec > max_time_msec:
			break
			
		# ---- 順方向1ステップ ----
		if head_f < queue_forward.size():
			var curr = queue_forward[head_f]
			head_f += 1
			var c_state: Array[int] = curr[0]
			var c_depth: int = curr[1]
			var c_mask: int = curr[2]
			
			if c_depth >= best_moves or c_depth >= 16:
				continue
				
			if queue_forward.size() > head_f and queue_forward[head_f][1] >= best_moves:
				return best_moves
				
			var sz = c_state.size()
			var state_set = {}
			if not is_advanced:
				for x in c_state: state_set[x] = true
				
			# 掛ける (hook)
			for f in candidate_fingers:
				if is_advanced or not state_set.has(f):
					for i in range(sz):
						if is_advanced:
							var prev_f = c_state[i]
							var next_f = c_state[(i + 1) % sz]
							if f == prev_f or f == next_f:
								continue
						var nxt = c_state.duplicate()
						nxt.insert(i + 1, f)
						
						var sz_n = nxt.size()
						if sz_n > 1 and nxt[0] == nxt[sz_n - 1]:
							sz_n -= 1
						var nxt_mask: int = 0
						for k in range(sz_n):
							nxt_mask |= _fast_table[nxt[k]][nxt[(k + 1) % sz_n]]
							
						if nxt_mask == c_mask:
							continue
						var new_depth = c_depth + 1
						if nxt_mask == target_mask:
							best_moves = min(best_moves, new_depth)
							continue
							
						var nxt_key: int = nxt_mask
						if not is_advanced:
							var pin_bits: int = 0
							for p in nxt: pin_bits |= (1 << p)
							nxt_key = (nxt_mask << 10) | pin_bits
							
						if visited_backward.has(nxt_key):
							best_moves = min(best_moves, new_depth + visited_backward[nxt_key])
						if not visited.has(nxt_key) or visited[nxt_key] > new_depth:
							visited[nxt_key] = new_depth
							if new_depth < best_moves:
								queue_forward.push_back([nxt, new_depth, nxt_mask])
								
			# 外す (unhook)
			if sz > 3:
				for i in range(sz):
					var nxt = c_state.duplicate()
					nxt.remove_at(i)
					
					var sz_n = nxt.size()
					if sz_n > 1 and nxt[0] == nxt[sz_n - 1]:
						sz_n -= 1
					var nxt_mask: int = 0
					for k in range(sz_n):
						nxt_mask |= _fast_table[nxt[k]][nxt[(k + 1) % sz_n]]
						
					if nxt_mask == c_mask:
						continue
					var new_depth = c_depth + 1
					if nxt_mask == target_mask:
						best_moves = min(best_moves, new_depth)
						continue
						
					var nxt_key: int = nxt_mask
					if not is_advanced:
						var pin_bits: int = 0
						for p in nxt: pin_bits |= (1 << p)
						nxt_key = (nxt_mask << 10) | pin_bits
						
					if visited_backward.has(nxt_key):
						best_moves = min(best_moves, new_depth + visited_backward[nxt_key])
					if not visited.has(nxt_key) or visited[nxt_key] > new_depth:
						visited[nxt_key] = new_depth
						if new_depth < best_moves:
							queue_forward.push_back([nxt, new_depth, nxt_mask])
							
		# ---- 逆方向1ステップ ----
		if head_b < queue_backward.size():
			var curr = queue_backward[head_b]
			head_b += 1
			var c_state: Array[int] = curr[0]
			var c_depth: int = curr[1]
			var c_mask: int = curr[2]
			
			if c_depth >= best_moves or c_depth >= 16:
				continue
				
			var sz = c_state.size()
			var state_set = {}
			if not is_advanced:
				for x in c_state: state_set[x] = true
				
			for f in candidate_fingers:
				if is_advanced or not state_set.has(f):
					for i in range(sz):
						if is_advanced:
							var prev_f = c_state[i]
							var next_f = c_state[(i + 1) % sz]
							if f == prev_f or f == next_f:
								continue
						var nxt = c_state.duplicate()
						nxt.insert(i + 1, f)
						
						var sz_n = nxt.size()
						if sz_n > 1 and nxt[0] == nxt[sz_n - 1]:
							sz_n -= 1
						var nxt_mask: int = 0
						for k in range(sz_n):
							nxt_mask |= _fast_table[nxt[k]][nxt[(k + 1) % sz_n]]
							
						if nxt_mask == c_mask:
							continue
						var new_depth = c_depth + 1
						if nxt_mask == start_mask:
							best_moves = min(best_moves, new_depth)
							continue
							
						var nxt_key: int = nxt_mask
						if not is_advanced:
							var pin_bits: int = 0
							for p in nxt: pin_bits |= (1 << p)
							nxt_key = (nxt_mask << 10) | pin_bits
							
						if visited.has(nxt_key):
							best_moves = min(best_moves, new_depth + visited[nxt_key])
						if not visited_backward.has(nxt_key) or visited_backward[nxt_key] > new_depth:
							visited_backward[nxt_key] = new_depth
							if new_depth < best_moves:
								queue_backward.push_back([nxt, new_depth, nxt_mask])
								
			if sz > 3:
				for i in range(sz):
					var nxt = c_state.duplicate()
					nxt.remove_at(i)
					
					var sz_n = nxt.size()
					if sz_n > 1 and nxt[0] == nxt[sz_n - 1]:
						sz_n -= 1
					var nxt_mask: int = 0
					for k in range(sz_n):
						nxt_mask |= _fast_table[nxt[k]][nxt[(k + 1) % sz_n]]
						
					if nxt_mask == c_mask:
						continue
					var new_depth = c_depth + 1
					if nxt_mask == start_mask:
						best_moves = min(best_moves, new_depth)
						continue
						
					var nxt_key: int = nxt_mask
					if not is_advanced:
						var pin_bits: int = 0
						for p in nxt: pin_bits |= (1 << p)
						nxt_key = (nxt_mask << 10) | pin_bits
						
					if visited.has(nxt_key):
						best_moves = min(best_moves, new_depth + visited[nxt_key])
					if not visited_backward.has(nxt_key) or visited_backward[nxt_key] > new_depth:
						visited_backward[nxt_key] = new_depth
						if new_depth < best_moves:
							queue_backward.push_back([nxt, new_depth, nxt_mask])
							
	return best_moves if best_moves != 999 else -1
