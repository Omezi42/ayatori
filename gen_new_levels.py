import sys
import random
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
        
    q_f = deque([(start_norm, initial_state, 0)])
    q_b = deque([(target_norm, target_state, 0)])
    
    visited_f = {start_norm: 0}
    visited_b = {target_norm: 0}
    
    for current_depth in range(max_depth):
        if not q_f or not q_b:
            break
            
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

def generate_random_valid_target():
    size = random.randint(4, 10)
    indices = list(range(10))
    random.shuffle(indices)
    return indices[:size]

initial = [0, 4, 5, 9]

stages = {
    1: [], # Stage 2 (layout 1)
    2: []  # Stage 3 (layout 2)
}

print("Generating levels...")

for layout in [1, 2]:
    generated = set()
    attempts = 0
    while len(stages[layout]) < 30 and attempts < 1000:
        attempts += 1
        tgt = generate_random_valid_target()
        norm = normalize_sequence(tgt)
        if norm in generated:
            continue
            
        om = calculate_optimal_moves_bidirectional(initial, tgt, max_depth=9)
        if 4 <= om <= 9:
            stages[layout].append({
                "target": tgt,
                "optimal_moves": om
            })
            generated.add(norm)
            print(f"Layout {layout}: Found {len(stages[layout])}/30 (om={om})")

with open("c:\\Users\\omezi\\Documents\\ayatori\\new_stages.txt", "w", encoding="utf-8") as f:
    for layout in [1, 2]:
        stages[layout].sort(key=lambda x: (x["optimal_moves"], len(x["target"])))
        for i, conf in enumerate(stages[layout]):
            f.write(f'{{"name": "Stage {layout+1}-{i+1}", "target": {conf["target"]}, "optimal_moves": {conf["optimal_moves"]}, "layout_id": {layout}}},\n')

print("Done. Saved to new_stages.txt")
