import sys
from collections import deque

LAYOUT_POSITIONS = {
    0: [(640, 110), (786, 158), (877, 283), (877, 437), (786, 562), (640, 610), (494, 562), (403, 437), (403, 283), (494, 158)],
    1: [(340, 200), (490, 200), (640, 200), (790, 200), (940, 200), (940, 500), (790, 500), (640, 500), (490, 500), (340, 500)],
    2: [(640, 110), (786, 158), (877, 283), (877, 437), (786, 562), (640, 610), (494, 562), (403, 437), (403, 283), (494, 158)] # same as 0?
}

def distance_squared_to(p1, p2):
    return (p1[0] - p2[0])**2 + (p1[1] - p2[1])**2

def get_sub_edges(u, v, layout_id):
    positions = LAYOUT_POSITIONS[layout_id]
    if u < 0 or v < 0 or u >= len(positions) or v >= len(positions):
        return [f"{min(u, v)}-{max(u, v)}"]
        
    pu = positions[u]
    pv = positions[v]
    
    points_on_line = []
    for w in range(len(positions)):
        if w == u or w == v:
            points_on_line.append(w)
            continue
            
        pw = positions[w]
        
        if min(pu[0], pv[0]) <= pw[0] <= max(pu[0], pv[0]) and \
           min(pu[1], pv[1]) <= pw[1] <= max(pu[1], pv[1]):
            cross = (pw[0] - pu[0]) * (pv[1] - pu[1]) - (pw[1] - pu[1]) * (pv[0] - pu[0])
            if abs(cross) < 0.1:
                points_on_line.append(w)
                
    points_on_line.sort(key=lambda x: distance_squared_to(pu, positions[x]))
    
    sub_edges = []
    for k in range(len(points_on_line) - 1):
        n1 = points_on_line[k]
        n2 = points_on_line[k+1]
        if n1 != n2:
            sub_edges.append(f"{min(n1, n2)}-{max(n1, n2)}")
            
    return sub_edges

def get_edge_set(seq, layout_id):
    if len(seq) == 0: return tuple()
    
    res = list(seq)
    if len(res) > 1 and res[0] == res[-1]:
        res.pop()
    
    if len(res) == 0: return tuple()
    
    edges = set()
    for i in range(len(res)):
        u = res[i]
        v = res[(i + 1) % len(res)]
        if u != v:
            for edge_key in get_sub_edges(u, v, layout_id):
                edges.add(edge_key)
                
    return tuple(sorted(list(edges)))

def normalize_simple(seq):
    if len(seq) > 1 and seq[0] == seq[-1]:
        seq = seq[:-1]
    
    best = seq[:]
    n = len(seq)
    for i in range(n):
        s = seq[i:] + seq[:i]
        if s < best: best = s
        rs = s[::-1]
        if rs < best: best = rs
    return tuple(best)

def get_neighbors(seq, is_advanced):
    neighbors = []
    n = len(seq)
    for i in range(n):
        for pin in range(10):
            if pin == seq[i] or pin == seq[(i+1)%n]:
                continue
            if not is_advanced and pin in seq:
                continue
            new_seq = list(seq)
            new_seq.insert(i+1, pin)
            neighbors.append(normalize_simple(new_seq))
            
    if n > 3:
        for i in range(n):
            new_seq = list(seq[:i] + seq[i+1:])
            neighbors.append(normalize_simple(new_seq))
            
    return set(neighbors)

def heuristic_distance(seq_edges, target_edges):
    diff = 0
    s_edges = set(seq_edges)
    t_edges = set(target_edges)
    for e in s_edges:
        if e not in t_edges: diff += 1
    for e in t_edges:
        if e not in s_edges: diff += 1
    return diff

def bfs_bidirectional(target_edges, layout_id, is_advanced, init_seq):
    init_seq_norm = normalize_simple(init_seq)
    if get_edge_set(init_seq_norm, layout_id) == target_edges: return 0
    
    # Actually, let's just do an A* or bounded BFS
    q = deque([(init_seq_norm, 0)])
    visited = {init_seq_norm: 0}
    
    while q:
        curr, d = q.popleft()
        
        if d >= 10:
            continue
            
        for nxt in get_neighbors(curr, is_advanced):
            if nxt not in visited:
                visited[nxt] = d + 1
                nxt_edges = get_edge_set(nxt, layout_id)
                if nxt_edges == target_edges:
                    return d + 1
                
                # Prune if heuristic is too large
                h = heuristic_distance(nxt_edges, target_edges)
                if d + 1 + h > 18:
                    continue
                    
                q.append((nxt, d + 1))
                
    return -1

levels = [
    {"name": "ふたごやま", "target": [0, 4, 8, 0, 5, 9], "layout_id": 2, "is_adv": True},
    {"name": "ダブルトライアングル", "target": [5, 2, 8, 5, 4, 6], "layout_id": 0, "is_adv": True},
    {"name": "砂時計", "target": [0, 1, 2, 3, 0, 9, 8, 7], "layout_id": 0, "is_adv": True},
    {"name": "メガネ", "target": [2, 1, 0, 9, 2, 3, 5, 8], "layout_id": 0, "is_adv": True},
    {"name": "クリスタル", "target": [0, 2, 5, 8, 0, 3, 5, 7], "layout_id": 0, "is_adv": True},
    {"name": "クローバー", "target": [5, 4, 6, 5, 2, 8, 5, 0, 9], "layout_id": 0, "is_adv": True},
    {"name": "クラウン", "target": [1, 0, 9, 1, 2, 5, 8, 9, 5], "layout_id": 0, "is_adv": True},
    {"name": "かざぐるま", "target": [5, 1, 2, 5, 3, 4, 5, 6, 7, 5, 8, 9], "layout_id": 0, "is_adv": True},
    {"name": "さんかく", "target": [1, 5, 8], "layout_id": 0, "is_adv": False},
    {"name": "リボン", "target": [0, 4, 6, 2], "layout_id": 0, "is_adv": False},
    {"name": "ダイヤ", "target": [0, 2, 5, 8], "layout_id": 0, "is_adv": False},
    {"name": "いなずま", "target": [1, 7, 3, 5], "layout_id": 0, "is_adv": False},
    {"name": "ロケット", "target": [0, 3, 6, 8], "layout_id": 0, "is_adv": False},
    {"name": "ちょうちょ", "target": [1, 5, 9, 2, 8], "layout_id": 0, "is_adv": False},
    {"name": "ほし", "target": [0, 6, 2, 8, 4], "layout_id": 0, "is_adv": False},
    {"name": "おうち", "target": [0, 2, 3, 7, 8], "layout_id": 0, "is_adv": False},
    {"name": "フラワー", "target": [1, 4, 6, 9, 2, 7, 5, 8, 3, 0], "layout_id": 0, "is_adv": False},
    {"name": "ピラミッド-1", "target": [3, 9, 0, 1], "layout_id": 1, "is_adv": False},
    {"name": "ピラミッド-2", "target": [0, 3, 5, 6, 8], "layout_id": 1, "is_adv": False},
    {"name": "ピラミッド-3", "target": [8, 4, 7, 5, 3, 0, 9, 2, 1], "layout_id": 1, "is_adv": False}
]

for lvl in levels:
    target_edges = get_edge_set(lvl["target"], lvl["layout_id"])
    
    init_seq = [0, 4, 5, 9]
    if lvl["layout_id"] == 1:
        init_seq = [0, 5, 9]
    elif lvl["layout_id"] == 2:
        init_seq = [0, 4, 8]
        
    ans = bfs_bidirectional(target_edges, lvl["layout_id"], lvl["is_adv"], init_seq)
    print(f'{lvl["name"]}: {ans}')
    sys.stdout.flush()
