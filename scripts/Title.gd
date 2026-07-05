extends Control

func _ready() -> void:
	# 1. 全体テーマ（フォントアウトラインの統一）
	var theme = Theme.new()
	theme.set_color("font_outline_color", "Label", Color("#5C4B51"))
	theme.set_color("font_outline_color", "Button", Color("#5C4B51"))
	theme.set_constant("outline_size", "Label", 12)
	theme.set_constant("outline_size", "Button", 8)
	self.theme = theme

	# 2. プライマリボタン（スタート）のスタイル
	var primary_normal = _create_button_style(Color("#F2849E"), 6)
	var primary_pressed = _create_button_style(Color("#F2849E"), 0)
	primary_pressed.content_margin_top += 6    # 押し込み表現
	primary_pressed.content_margin_bottom -= 6
	
	_apply_button_styles($ButtonContainer/StartButton, primary_normal, primary_pressed)
	
	# 3. セカンダリボタン（作成・読込）のスタイル
	var secondary_normal = _create_button_style(Color("#F5B7C6"), 6) # 少しトーンを落とす
	var secondary_pressed = _create_button_style(Color("#F5B7C6"), 0)
	secondary_pressed.content_margin_top += 6
	secondary_pressed.content_margin_bottom -= 6
	
	_apply_button_styles($ButtonContainer/CreateButton, secondary_normal, secondary_pressed)
	_apply_button_styles($ButtonContainer/LoadContainer/LoadButton, secondary_normal, secondary_pressed)
	
	# シグナルの接続
	$ButtonContainer/StartButton.pressed.connect(_on_start_pressed)
	$ButtonContainer/CreateButton.pressed.connect(_on_create_pressed)
	$ButtonContainer/LoadContainer/LoadButton.pressed.connect(_on_load_pressed)
	
	FirebaseManager.load_completed.connect(_on_level_loaded)
	FirebaseManager.load_failed.connect(_on_load_failed)
	
	# ロゴのアニメーション（ふわふわ浮遊させる）
	var logo = $LogoContainer
	logo.pivot_offset = logo.size / 2.0
	var tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(logo, "position:y", logo.position.y - 10, 1.5)
	tween.tween_property(logo, "position:y", logo.position.y + 10, 1.5)

# ボタンのスタイルボックスを生成するヘルパー関数
func _create_button_style(bg_col: Color, shadow_y: float) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_col
	# カプセル型にするための大きなR
	style.corner_radius_top_left = 100
	style.corner_radius_top_right = 100
	style.corner_radius_bottom_left = 100
	style.corner_radius_bottom_right = 100
	# 影の設定
	if shadow_y > 0:
		style.shadow_color = Color("#D95B7A")
		style.shadow_size = 0 # ぼかしをなくしてシャープな影に
		style.shadow_offset = Vector2(0, shadow_y)
	
	# 基本の余白
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	style.content_margin_left = 40
	style.content_margin_right = 40
	return style

# ボタンにスタイルを適用するヘルパー関数
func _apply_button_styles(btn: Button, normal_style: StyleBoxFlat, pressed_style: StyleBoxFlat) -> void:
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", normal_style) # ホバー時はnormalと同じでOK
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", Color.WHITE)

func _on_start_pressed() -> void:
	if FirebaseManager.has_meta("ugc_target"):
		FirebaseManager.remove_meta("ugc_target")
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_create_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelEditor.tscn")

func _on_load_pressed() -> void:
	var code = $ButtonContainer/LoadContainer/CodeInput.text.strip_edges()
	if code.length() > 0:
		$ButtonContainer/LoadContainer/LoadButton.text = "読込中..."
		$ButtonContainer/LoadContainer/LoadButton.disabled = true
		FirebaseManager.load_level(code)

func _on_level_loaded(target_sequence: Array) -> void:
	$ButtonContainer/LoadContainer/LoadButton.text = "コードで遊ぶ"
	$ButtonContainer/LoadContainer/LoadButton.disabled = false
	FirebaseManager.set_meta("ugc_target", target_sequence)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_load_failed(err_msg: String) -> void:
	$ButtonContainer/LoadContainer/LoadButton.text = "失敗"
	$ButtonContainer/LoadContainer/LoadButton.disabled = false
	print("Load Error: ", err_msg)
	await get_tree().create_timer(1.5).timeout
	$ButtonContainer/LoadContainer/LoadButton.text = "コードで遊ぶ"
