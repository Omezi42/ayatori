class_name TutorialManager extends Node2D

@export var main_controller: MainController
var hand_node: Node2D
var tween: Tween

func _ready() -> void:
	# ダミーの手のアイコンをプロシージャルに描画する
	# 画像アセットがないのでPolygon2DやCanvasLayerでそれっぽくする
	hand_node = Node2D.new()
	hand_node.set_script(preload("res://scripts/TutorialHand.gd"))
	add_child(hand_node)
	hand_node.modulate.a = 0.0
	
func show_hint(from_pos: Vector2, to_pos: Vector2) -> void:
	if tween and tween.is_running():
		tween.kill()
		
	hand_node.position = from_pos
	hand_node.modulate.a = 0.0
	hand_node.scale = Vector2(1, 1)
	
	tween = create_tween().set_loops(3)
	# フェードイン
	tween.tween_property(hand_node, "modulate:a", 1.0, 0.3)
	# 少し縮んで「掴む」表現
	tween.tween_property(hand_node, "scale", Vector2(0.8, 0.8), 0.2)
	# ドラッグ移動
	tween.tween_property(hand_node, "position", to_pos, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# 離す表現
	tween.tween_property(hand_node, "scale", Vector2(1, 1), 0.2)
	# フェードアウト
	tween.tween_property(hand_node, "modulate:a", 0.0, 0.3)
	
	# 3回ループしたら消える
	tween.finished.connect(func(): hand_node.modulate.a = 0.0)

func show_unhook_hint(pos: Vector2) -> void:
	if tween and tween.is_running():
		tween.kill()
		
	hand_node.position = pos
	hand_node.modulate.a = 0.0
	hand_node.scale = Vector2(1, 1)
	
	tween = create_tween().set_loops(3)
	# フェードイン
	tween.tween_property(hand_node, "modulate:a", 1.0, 0.3)
	# 少し縮んで「タップ」表現
	tween.tween_property(hand_node, "scale", Vector2(0.7, 0.7), 0.15)
	# タップしたまま少し待つ
	tween.tween_interval(0.3)
	# 離す表現
	tween.tween_property(hand_node, "scale", Vector2(1, 1), 0.15)
	# フェードアウト
	tween.tween_property(hand_node, "modulate:a", 0.0, 0.3)
	
	# 3回ループしたら消える
	tween.finished.connect(func(): hand_node.modulate.a = 0.0)

func _draw() -> void:
	pass
	
# Sprite2Dの代わりに_drawを使って手を描画するためのスクリプトアタッチ
func _setup_dummy_hand() -> void:
	var hand_img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	hand_img.fill(Color(0,0,0,0))
	# とてもシンプルな手のアイコンを無理やり描画（円の組み合わせ）
	# 代わりに Godotの _draw() で描画するカスタムノードを使う方がきれい。
	pass
