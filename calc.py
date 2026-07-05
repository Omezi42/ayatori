import sys
from collections import deque

def normalize_sequence(state):
    if not state: return ()
    n = len(state)
    best = tuple(state)
    for i in range(n):
        shifted = state[i:] + state[:i]
        best = min(best, tuple(shifted))
        reversed_shifted = shifted[::-1]
        best = min(best, tuple(reversed_shifted))
    return best

def is_matching(state, target_norm):
    return normalize_sequence(state) == target_norm

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

def calculate_optimal_moves(initial_state, target_state):
    target_norm = normalize_sequence(target_state)
    if is_matching(initial_state, target_norm):
        return 0
        
    start_norm = normalize_sequence(initial_state)
    queue = deque([(start_norm, 0)])
    visited = {start_norm}
    
    MAX_DEPTH = 10
    
    while queue:
        state, depth = queue.popleft()
        if depth >= MAX_DEPTH:
            continue
            
        next_depth = depth + 1
        for nxt in generate_next_states(state):
            norm = normalize_sequence(nxt)
            if norm == target_norm:
                return next_depth
            if norm not in visited:
                visited.add(norm)
                queue.append((norm, next_depth))
                
    return MAX_DEPTH

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

print("moves = {")
for conf in configs:
    m = calculate_optimal_moves(initial, conf["target"])
    print(f'    "{conf["name"]}": {m},')
print("}")
