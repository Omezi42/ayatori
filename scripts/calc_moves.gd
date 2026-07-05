extends SceneTree

func _init():
	var level_configs = [
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
	
	var string_manager = preload("res://scripts/StringManager.gd").new()
	var initial_seq: Array[int] = [0, 4, 5, 9]
	
	for config in level_configs:
		var target: Array[int] = []
		target.assign(config["target"])
		var optimal = string_manager.calculate_optimal_moves(initial_seq, target)
		print("name:", config["name"], " optimal:", optimal)
		
	quit()
