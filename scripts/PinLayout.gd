class_name PinLayout

static func get_positions(layout_id: int) -> Array[Vector2]:
	match layout_id:
		0:
			# ステージ1: 円形（既存）
			return [
				Vector2(640, 110), # 0
				Vector2(786, 158), # 1
				Vector2(877, 283), # 2
				Vector2(877, 437), # 3
				Vector2(786, 562), # 4
				Vector2(640, 610), # 5
				Vector2(494, 562), # 6
				Vector2(403, 437), # 7
				Vector2(403, 283), # 8
				Vector2(494, 158)  # 9
			]
		1:
			# ステージ2: 2行5列
			# 時計回りに糸を張ることを考慮し、上段を左から右、下段を右から左へ
			return [
				Vector2(340, 200), # 0
				Vector2(490, 200), # 1
				Vector2(640, 200), # 2
				Vector2(790, 200), # 3
				Vector2(940, 200), # 4
				Vector2(940, 520), # 5
				Vector2(790, 520), # 6
				Vector2(640, 520), # 7
				Vector2(490, 520), # 8
				Vector2(340, 520)  # 9
			]
		2:
			# ステージ3: ピラミッド（正三角形）
			# 外周に9ピン、中央に1ピンの配置
			# これにより、トライフォース、木、矢印など、これまでと全く違う直線の表現が可能になります。
			return [
				Vector2(640, 150), # 0: 頂点
				Vector2(750, 290), # 1: 右辺上
				Vector2(860, 430), # 2: 右辺下
				Vector2(970, 570), # 3: 右下角
				Vector2(750, 570), # 4: 底辺右
				Vector2(530, 570), # 5: 底辺左
				Vector2(310, 570), # 6: 左下角
				Vector2(420, 430), # 7: 左辺下
				Vector2(530, 290), # 8: 左辺上
				Vector2(640, 430)  # 9: 内部中央
			]
		3:
			# ステージ4: 10x10 ボード (フリーモード限定)
			var pos: Array[Vector2] = []
			var start_x = 370.0
			var start_y = 90.0
			var spacing_x = 60.0
			var spacing_y = 60.0
			for y in range(10):
				for x in range(10):
					pos.append(Vector2(start_x + x * spacing_x, start_y + y * spacing_y))
			return pos
			
	return get_positions(0)
