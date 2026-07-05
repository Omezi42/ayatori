import sys

def check_intersection(seg1, seg2):
    # Two segments A-B and C-D intersect if C and D are separated by A and B on the circle.
    # Fingers are 0..9 in order around the circle.
    # Normalize so that A is 0.
    A, B = seg1
    C, D = seg2
    
    if A == C or A == D or B == C or B == D:
        return False # Shared vertex is not an intersection
        
    diff_B = (B - A) % 10
    diff_C = (C - A) % 10
    diff_D = (D - A) % 10
    
    # C is strictly inside the arc from A to B
    C_inside = 0 < diff_C < diff_B
    # D is strictly inside the arc from A to B
    D_inside = 0 < diff_D < diff_B
    
    # They intersect if exactly one of C or D is inside the arc A->B
    return C_inside != D_inside

def calculate_intersections(target):
    count = 0
    segments = []
    n = len(target)
    for i in range(n):
        segments.append((target[i], target[(i+1)%n]))
        
    for i in range(len(segments)):
        for j in range(i+1, len(segments)):
            if check_intersection(segments[i], segments[j]):
                count += 1
    return count

def calculate_stretch(target):
    stretch = 0
    n = len(target)
    for i in range(n):
        a = target[i]
        b = target[(i+1)%n]
        dist = abs(a - b)
        dist = min(dist, 10 - dist)
        stretch += dist
    return stretch / n if n > 0 else 0

level_configs = [
	{"name": "さんかく", "target": [1, 5, 8], "optimal_moves": 5},
	{"name": "しかく", "target": [1, 3, 7, 9], "optimal_moves": 6},
	{"name": "リボン", "target": [0, 4, 6, 2], "optimal_moves": 4},
	{"name": "クロス", "target": [1, 7, 9, 3], "optimal_moves": 6},
	{"name": "テント", "target": [0, 4, 5, 6, 2], "optimal_moves": 3},
	{"name": "おうち", "target": [0, 2, 3, 7, 8], "optimal_moves": 7},
	{"name": "ほし", "target": [0, 6, 2, 8, 4], "optimal_moves": 5},
	{"name": "ちょうちょ", "target": [1, 5, 9, 2, 8], "optimal_moves": 5},
	{"name": "ひしがた", "target": [0, 3, 5, 7], "optimal_moves": 4},
	{"name": "さかな", "target": [2, 7, 5, 3, 8], "optimal_moves": 7},
	{"name": "ロケット", "target": [0, 3, 6, 8], "optimal_moves": 6},
	{"name": "かざぐるま", "target": [1, 6, 9, 4], "optimal_moves": 4},
	{"name": "ダイヤ", "target": [0, 2, 5, 8], "optimal_moves": 4},
	{"name": "めがね", "target": [8, 9, 7, 6, 5, 4, 3, 2], "optimal_moves": 6},
	{"name": "キャンディ", "target": [1, 3, 2, 8, 7, 9], "optimal_moves": 8},
	{"name": "ギザギザ", "target": [0, 2, 4, 6, 8, 9, 7, 5, 3, 1], "optimal_moves": 8},
	{"name": "クラウン", "target": [0, 4, 2, 6, 8], "optimal_moves": 5},
	{"name": "クリスタル", "target": [0, 2, 4, 5, 6, 8], "optimal_moves": 4},
	{"name": "いなずま", "target": [1, 7, 3, 5], "optimal_moves": 6},
	{"name": "スパイダー", "target": [0, 4, 7, 2, 6, 9], "optimal_moves": 4},
	{"name": "ふたごぼし", "target": [0, 3, 8, 1, 6, 2], "optimal_moves": 8},
	{"name": "マジックサークル", "target": [0, 3, 5, 7, 9, 2, 4, 6, 8, 1], "optimal_moves": 8},
	{"name": "インフィニティ", "target": [2, 6, 9, 7, 3, 0], "optimal_moves": 6},
	{"name": "メイズ", "target": [0, 4, 8, 3, 7, 1, 5, 9, 2, 6], "optimal_moves": 6},
	{"name": "フラワー", "target": [1, 4, 6, 9, 2, 7, 5, 8, 3, 0], "optimal_moves": 8},
	{"name": "スーパーノヴァ", "target": [0, 5, 2, 7, 4, 9, 1, 6, 3, 8], "optimal_moves": 8},
	{"name": "ブラックホール", "target": [9, 3, 6, 1, 8, 4, 7, 2, 5, 0], "optimal_moves": 8},
	{"name": "ギャラクシー", "target": [0, 6, 3, 9, 5, 1, 8, 4, 7, 2], "optimal_moves": 6},
	{"name": "コスモス", "target": [2, 7, 4, 9, 5, 0, 6, 1, 8, 3], "optimal_moves": 8},
	{"name": "マスター", "target": [0, 4, 8, 1, 5, 9, 2, 6, 3, 7], "optimal_moves": 6}
]

for conf in level_configs:
    t = conf["target"]
    om = conf["optimal_moves"]
    inter = calculate_intersections(t)
    v = len(t)
    stretch = calculate_stretch(t)
    
    score = om * 10 + inter * 2 + v * 1 + stretch * 0.5
    conf["score"] = score
    conf["metrics"] = f"(om:{om}, i:{inter}, v:{v}, str:{stretch:.1f})"

level_configs.sort(key=lambda x: x["score"])

with open("c:\\Users\\omezi\\Documents\\ayatori\\sorted_configs.txt", "w", encoding="utf-8") as f:
    f.write("\tvar level_configs = [\n")
    for i, conf in enumerate(level_configs):
        metrics = conf.pop("metrics")
        score = conf.pop("score")
        suffix = "," if i < len(level_configs)-1 else ""
        f.write(f'\t\t{{"name": "{conf["name"]}", "target": {conf["target"]}, "optimal_moves": {conf["optimal_moves"]}}}{suffix} # score: {score:.1f} {metrics}\n')
    f.write("\t]\n")
