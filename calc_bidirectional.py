import sys
from collections import deque

def normalize_sequence(state):
    if not state: return ()
    n = len(state)
    best = tuple(state)
    for i in range(n):
        shifted = tuple(state[i:] + state[:i])
        if shifted < best:
            best = shifted
        reversed_shifted = shifted[::-1]
        if reversed_shifted < best:
            best = reversed_shifted
    return best

def generate_next_states(state):
    results = []
    state_set = set(state)
    available_fingers = [i for i in range(10) if i not in state_set]
    
    # hook_finger
    for finger in available_fingers:
        for i in range(len(state)):
            nxt = list(state)
            nxt.insert(i + 1, finger)
            results.append(nxt)
            
    # unhook_finger
    if len(state) > 3:
        for i in range(len(state)):
            nxt = list(state)
            nxt.pop(i)
            results.append(nxt)
            
    return results

def calculate_optimal_moves_bidirectional(initial_state, target_state, max_depth=10):
    start_norm = normalize_sequence(initial_state)
    target_norm = normalize_sequence(target_state)
    
    if start_norm == target_norm:
        return 0
        
    # q contains (state_norm, original_state, depth)
    q_f = deque([(start_norm, initial_state, 0)])
    q_b = deque([(target_norm, target_state, 0)])
    
    visited_f = {start_norm: 0}
    visited_b = {target_norm: 0}
    
    for current_depth in range(max_depth):
        # We expand level by level to ensure shortest path.
        # It's better to expand the smaller frontier.
        if not q_f or not q_b:
            break
            
        # Expand forward queue for current depth
        size_f = len(q_f)
        for _ in range(size_f):
            s_norm, s_orig, d = q_f.popleft()
            if d > current_depth:
                q_f.appendleft((s_norm, s_orig, d))
                break
                
            for nxt in generate_next_states(s_orig):
                n_norm = normalize_sequence(nxt)
                if n_norm in visited_b:
                    return d + 1 + visited_b[n_norm]
                if n_norm not in visited_f:
                    visited_f[n_norm] = d + 1
                    q_f.append((n_norm, nxt, d + 1))
                    
        # Expand backward queue for current depth
        size_b = len(q_b)
        for _ in range(size_b):
            s_norm, s_orig, d = q_b.popleft()
            if d > current_depth:
                q_b.appendleft((s_norm, s_orig, d))
                break
                
            for nxt in generate_next_states(s_orig):
                n_norm = normalize_sequence(nxt)
                if n_norm in visited_f:
                    return d + 1 + visited_f[n_norm]
                if n_norm not in visited_b:
                    visited_b[n_norm] = d + 1
                    q_b.append((n_norm, nxt, d + 1))
                    
    return max_depth

configs = [
    {"name": "さんかく", "target": [1, 5, 8]},
    {"name": "しかく", "target": [1, 3, 7, 9]},
    {"name": "リボン", "target": [0, 4, 6, 2]},
    {"name": "クロス", "target": [1, 7, 9, 3]},
    {"name": "テント", "target": [0, 4, 5, 6, 2]},
    {"name": "おうち", "target": [0, 2, 3, 7, 8]},
    {"name": "ほし", "target": [0, 6, 2, 8, 4]},
    {"name": "ちょうちょ", "target": [1, 5, 9, 2, 8]},
    {"name": "ひしがた", "target": [0, 3, 5, 7]},
    {"name": "さかな", "target": [2, 7, 5, 3, 8]},
    {"name": "ロケット", "target": [0, 3, 6, 8]},
    {"name": "かざぐるま", "target": [1, 6, 9, 4]},
    {"name": "ダイヤ", "target": [0, 2, 5, 8]},
    {"name": "めがね", "target": [8, 9, 7, 6, 5, 4, 3, 2]},
    {"name": "キャンディ", "target": [1, 3, 2, 8, 7, 9]},
    {"name": "ギザギザ", "target": [0, 2, 4, 6, 8, 9, 7, 5, 3, 1]},
    {"name": "クラウン", "target": [0, 4, 2, 6, 8]},
    {"name": "クリスタル", "target": [0, 2, 4, 5, 6, 8]},
    {"name": "いなずま", "target": [1, 7, 3, 5]},
    {"name": "スパイダー", "target": [0, 4, 7, 2, 6, 9]},
    {"name": "ふたごぼし", "target": [0, 3, 8, 1, 6, 2]},
    {"name": "マジックサークル", "target": [0, 3, 5, 7, 9, 2, 4, 6, 8, 1]},
    {"name": "インフィニティ", "target": [2, 6, 9, 7, 3, 0]},
    {"name": "メイズ", "target": [0, 4, 8, 3, 7, 1, 5, 9, 2, 6]},
    {"name": "フラワー", "target": [1, 4, 6, 9, 2, 7, 5, 8, 3, 0]},
    {"name": "スーパーノヴァ", "target": [0, 5, 2, 7, 4, 9, 1, 6, 3, 8]},
    {"name": "ブラックホール", "target": [9, 3, 6, 1, 8, 4, 7, 2, 5, 0]},
    {"name": "ギャラクシー", "target": [0, 6, 3, 9, 5, 1, 8, 4, 7, 2]},
    {"name": "コスモス", "target": [2, 7, 4, 9, 5, 0, 6, 1, 8, 3]},
    {"name": "マスター", "target": [0, 4, 8, 1, 5, 9, 2, 6, 3, 7]}
]

initial = [0, 4, 5, 9]

print("calculated_moves = [")
for conf in configs:
    m = calculate_optimal_moves_bidirectional(initial, conf["target"])
    print(f'    {m},  # {conf["name"]}')
print("]")
