import json
from collections import deque

def normalize(seq):
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
    # hook
    for i in range(n):
        for pin in range(10):
            if pin == seq[i] or pin == seq[(i+1)%n]:
                continue
            if not is_advanced and pin in seq:
                continue
            new_seq = list(seq)
            new_seq.insert(i+1, pin)
            neighbors.append(normalize(new_seq))
            
    # unhook
    if n > 3:
        for i in range(n):
            new_seq = list(seq[:i] + seq[i+1:])
            neighbors.append(normalize(new_seq))
            
    return set(neighbors)

def bfs(target, is_advanced):
    init_seq = normalize([0, 4, 5, 9])
    target_seq = normalize(target)
    
    if init_seq == target_seq: return 0
    
    q_f = deque([init_seq])
    q_b = deque([target_seq])
    
    dist_f = {init_seq: 0}
    dist_b = {target_seq: 0}
    
    while q_f and q_b:
        if len(dist_f) > 50000: return -1 # timeout
        
        # forward
        curr_f = q_f.popleft()
        d_f = dist_f[curr_f]
        
        for nxt in get_neighbors(curr_f, is_advanced):
            if nxt in dist_b:
                return d_f + 1 + dist_b[nxt]
            if nxt not in dist_f:
                dist_f[nxt] = d_f + 1
                q_f.append(nxt)
                
        # backward
        curr_b = q_b.popleft()
        d_b = dist_b[curr_b]
        
        for nxt in get_neighbors(curr_b, is_advanced):
            if nxt in dist_f:
                return d_b + 1 + dist_f[nxt]
            if nxt not in dist_b:
                dist_b[nxt] = d_b + 1
                q_b.append(nxt)
                
    return -1

levels = [
    {"name": "ふたごやま", "target": [0, 4, 8, 0, 5, 9], "is_adv": True},
    {"name": "ダブルトライアングル", "target": [5, 2, 8, 5, 4, 6], "is_adv": True},
    {"name": "砂時計", "target": [0, 1, 2, 3, 0, 9, 8, 7], "is_adv": True},
    {"name": "メガネ", "target": [2, 1, 0, 9, 2, 3, 5, 8], "is_adv": True},
    {"name": "クリスタル", "target": [0, 2, 5, 8, 0, 3, 5, 7], "is_adv": True},
    {"name": "クローバー", "target": [5, 4, 6, 5, 2, 8, 5, 0, 9], "is_adv": True},
    {"name": "クラウン", "target": [1, 0, 9, 1, 2, 5, 8, 9, 5], "is_adv": True},
    {"name": "かざぐるま", "target": [5, 1, 2, 5, 3, 4, 5, 6, 7, 5, 8, 9], "is_adv": True},
    {"name": "さんかく", "target": [1, 5, 8], "is_adv": False},
    {"name": "リボン", "target": [0, 4, 6, 2], "is_adv": False},
    {"name": "ダイヤ", "target": [0, 2, 5, 8], "is_adv": False},
    {"name": "いなずま", "target": [1, 7, 3, 5], "is_adv": False},
    {"name": "ロケット", "target": [0, 3, 6, 8], "is_adv": False},
    {"name": "ちょうちょ", "target": [1, 5, 9, 2, 8], "is_adv": False},
    {"name": "ほし", "target": [0, 6, 2, 8, 4], "is_adv": False},
    {"name": "おうち", "target": [0, 2, 3, 7, 8], "is_adv": False},
    {"name": "フラワー", "target": [1, 4, 6, 9, 2, 7, 5, 8, 3, 0], "is_adv": False},
    {"name": "ピラミッド-1", "target": [3, 9, 0, 1], "is_adv": False},
    {"name": "ピラミッド-2", "target": [0, 3, 5, 6, 8], "is_adv": False},
    {"name": "ピラミッド-3", "target": [8, 4, 7, 5, 3, 0, 9, 2, 1], "is_adv": False}
]

import sys

for lvl in levels:
    ans = bfs(lvl["target"], lvl["is_adv"])
    print(f"{lvl['name']}:{ans}")
    sys.stdout.flush()
