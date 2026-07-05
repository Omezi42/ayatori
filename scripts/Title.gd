extends Control

func _ready() -> void:
	# Setup styling for start button
	var btn = $StartButton
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.92, 0.62, 0.75, 1.0)
	btn_style.corner_radius_top_left = 32
	btn_style.corner_radius_top_right = 32
	btn_style.corner_radius_bottom_left = 32
	btn_style.corner_radius_bottom_right = 32
	btn_style.shadow_color = Color(0.8, 0.35, 0.5, 0.5)
	btn_style.shadow_size = 8
	btn_style.content_margin_top = 20
	btn_style.content_margin_bottom = 20
	btn_style.content_margin_left = 60
	btn_style.content_margin_right = 60
	
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(0.96, 0.72, 0.82, 1.0)
	
	for b in [btn, $CreateButton, $HBoxContainer/LoadButton]:
		b.add_theme_stylebox_override("normal", btn_style)
		b.add_theme_stylebox_override("hover", btn_hover)
		b.add_theme_stylebox_override("pressed", btn_style)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.add_theme_color_override("font_color", Color.WHITE)
		b.add_theme_constant_override("outline_size", 4)
		b.add_theme_color_override("font_outline_color", Color(0.7, 0.4, 0.5, 0.8))
		
		b.pivot_offset = b.size / 2.0
		b.mouse_entered.connect(func(): _animate_button(b, Vector2(1.05, 1.05)))
		b.mouse_exited.connect(func(): _animate_button(b, Vector2(1.0, 1.0)))

	btn.pressed.connect(_on_start_pressed)
	$CreateButton.pressed.connect(_on_create_pressed)
	$HBoxContainer/LoadButton.pressed.connect(_on_load_pressed)
	
	FirebaseManager.load_completed.connect(_on_level_loaded)
	FirebaseManager.load_failed.connect(_on_load_failed)
	
	# Title animation
	var title = $TitleLabel
	title.pivot_offset = title.size / 2.0
	var tween = create_tween().set_loops()
	tween.tween_property(title, "scale", Vector2(1.05, 1.05), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(title, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _animate_button(btn: Button, target_scale: Vector2) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", target_scale, 0.3)

func _on_start_pressed() -> void:
	if FirebaseManager.has_meta("ugc_target"):
		FirebaseManager.remove_meta("ugc_target")
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_create_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelEditor.tscn")

func _on_load_pressed() -> void:
	var code = $HBoxContainer/CodeInput.text.strip_edges()
	if code.length() > 0:
		$HBoxContainer/LoadButton.text = "読込中..."
		$HBoxContainer/LoadButton.disabled = true
		FirebaseManager.load_level(code)

func _on_level_loaded(target_sequence: Array) -> void:
	$HBoxContainer/LoadButton.text = "コードで遊ぶ"
	$HBoxContainer/LoadButton.disabled = false
	
	# UGCとして配列を渡し、Mainシーンへ遷移する
	# ※ MainController や LevelManager にグローバルでデータを渡す必要があるため
	# AutoLoadに設定したLevelManagerでフラグを立てるか、GameStateに持たせる。
	# 今回はAutoLoadがないので、とりあえずLevelManagerの処理をMainで書き換えるために
	# グローバルに渡したいが、手っ取り早くLevelManagerをAutoLoadにするか、専用AutoLoadを作るか。
	# FirebaseManagerを利用する
	FirebaseManager.set_meta("ugc_target", target_sequence)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_load_failed(err_msg: String) -> void:
	$HBoxContainer/LoadButton.text = "失敗"
	$HBoxContainer/LoadButton.disabled = false
	print("Load Error: ", err_msg)
	await get_tree().create_timer(1.5).timeout
	$HBoxContainer/LoadButton.text = "コードで遊ぶ"
