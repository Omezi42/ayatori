import math

positions = [
    (640, 110), # 0
    (786, 158), # 1
    (877, 283), # 2
    (877, 437), # 3
    (786, 562), # 4
    (640, 610), # 5
    (494, 562), # 6
    (403, 437), # 7
    (403, 283), # 8
    (494, 158)  # 9
]

sub_edges_cache = {}

def get_sub_edges(u, v):
    u_min, v_max = min(u, v), max(u, v)
    cache_key = f"{u_min}-{v_max}"
    if cache_key in sub_edges_cache:
        return sub_edges_cache[cache_key]

    pu = positions[u]
    pv = positions[v]

    points_on_line = []
    for w, pw in enumerate(positions):
        if w == u or w == v:
            points_on_line.append(w)
            continue

        if min(pu[0], pv[0]) <= pw[0] <= max(pu[0], pv[0]) and \
           min(pu[1], pv[1]) <= pw[1] <= max(pu[1], pv[1]):
            cross = (pw[0] - pu[0]) * (pv[1] - pu[1]) - (pw[1] - pu[1]) * (pv[0] - pu[0])
            if abs(cross) < 0.1:
                points_on_line.append(w)

    points_on_line.sort(key=lambda x: (positions[x][0]-pu[0])**2 + (positions[x][1]-pu[1])**2)

    sub_edges = []
    for k in range(len(points_on_line) - 1):
        n1 = points_on_line[k]
        n2 = points_on_line[k+1]
        if n1 != n2:
            sub_edges.append(f"{min(n1, n2)}-{max(n1, n2)}")

    sub_edges_cache[cache_key] = sub_edges
    return sub_edges

def normalize_sequence(seq):
    res = list(seq)
    if len(res) > 1 and res[0] == res[-1]:
        res.pop()
    return res

def get_edge_set(seq):
    if not seq: return []
    norm = normalize_sequence(seq)
    if not norm: return []
    edges = set()
    n = len(norm)
    for i in range(n):
        u = norm[i]
        v = norm[(i + 1) % n]
        if u != v:
            for edge in get_sub_edges(u, v):
                edges.add(edge)
    return sorted(list(edges))

def get_canonical_key(seq):
    norm = normalize_sequence(seq)
    n = len(norm)
    best_key = str(norm)
    for i in range(n):
        shifted = norm[i:] + norm[:i]
        if str(shifted) < best_key:
            best_key = str(shifted)
        reversed_shifted = shifted[::-1]
        if str(reversed_shifted) < best_key:
            best_key = str(reversed_shifted)
    return best_key

target_seq = [5, 4, 6, 5, 2, 8, 5, 0, 9]
target_edges = get_edge_set(target_seq)
start_seq = [0, 4, 5, 9]

queue = [{"state": start_seq, "path": []}]
visited = set()
visited.add(get_canonical_key(start_seq))

found = False
print("Solving...")
while queue:
    curr = queue.pop(0)
    state = curr["state"]
    path = curr["path"]

    if get_edge_set(state) == target_edges:
        print("Solution found in", len(path), "moves!")
        for move in path:
            print(move)
        found = True
        break
    
    if len(path) >= 4:
        continue

    # hook
    for f in range(10):
        for i in range(len(state)):
            prev_f = state[i]
            next_f = state[(i + 1) % len(state)]
            if f == prev_f or f == next_f:
                continue
            nxt = state.copy()
            nxt.insert(i + 1, f)
            key = get_canonical_key(nxt)
            if key not in visited:
                visited.add(key)
                new_path = path.copy()
                new_path.append(f"Hook finger {f} on segment {i} ({prev_f}-{next_f})")
                queue.append({"state": nxt, "path": new_path})

    # unhook
    if len(state) > 3:
        for i in range(len(state)):
            nxt = state.copy()
            removed = nxt.pop(i)
            key = get_canonical_key(nxt)
            if key not in visited:
                visited.add(key)
                new_path = path.copy()
                new_path.append(f"Unhook finger {removed} at index {i}")
                queue.append({"state": nxt, "path": new_path})

if not found:
    print("No solution found within 4 moves.")
