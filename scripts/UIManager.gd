class_name UIManager extends CanvasLayer

@export var string_manager: StringManager
@export var undo_button: Button
@export var reset_button: Button
@export var share_button: Button
@export var level_label: Label
@export var message_label: Label

func _ready() -> void:
	_apply_premium_styles()
	if undo_button:
		undo_button.text = "↩ Undo"
		_setup_button_animations(undo_button)
		undo_button.pressed.connect(_on_undo_pressed)
	if reset_button:
		reset_button.text = "↺ Reset"
		_setup_button_animations(reset_button)
		reset_button.pressed.connect(_on_reset_pressed)
	if share_button:
		share_button.text = "🔗 Share"
		_setup_button_animations(share_button)
		share_button.pressed.connect(_on_share_pressed)
		
	if message_label:
		message_label.text = ""
		message_label.modulate.a = 0.0
		message_label.scale = Vector2(0.5, 0.5)

func _apply_premium_styles() -> void:
	# Create a shared StyleBox for buttons
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	btn_style.corner_radius_top_left = 12
	btn_style.corner_radius_top_right = 12
	btn_style.corner_radius_bottom_left = 12
	btn_style.corner_radius_bottom_right = 12
	btn_style.shadow_color = Color(0, 0, 0, 0.3)
	btn_style.shadow_size = 4
	btn_style.content_margin_left = 20
	btn_style.content_margin_right = 20
	btn_style.content_margin_top = 10
	btn_style.content_margin_bottom = 10
	
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(0.25, 0.25, 0.35, 0.9)
	
	for btn in [undo_button, reset_button, share_button]:
		if btn:
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_stylebox_override("hover", btn_hover)
			btn.add_theme_stylebox_override("pressed", btn_style)
			btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
			btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
			btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	
	if level_label:
		var lbl_style = StyleBoxFlat.new()
		lbl_style.bg_color = Color(0.96, 0.45, 0.65, 0.9) # Match string color
		lbl_style.corner_radius_top_left = 16
		lbl_style.corner_radius_top_right = 16
		lbl_style.corner_radius_bottom_left = 16
		lbl_style.corner_radius_bottom_right = 16
		lbl_style.shadow_color = Color(0.96, 0.45, 0.65, 0.4)
		lbl_style.shadow_size = 6
		lbl_style.content_margin_left = 24
		lbl_style.content_margin_right = 24
		lbl_style.content_margin_top = 8
		lbl_style.content_margin_bottom = 8
		level_label.add_theme_stylebox_override("normal", lbl_style)
		level_label.add_theme_color_override("font_color", Color.WHITE)
		# Add outline for text
		level_label.add_theme_constant_override("outline_size", 2)
		level_label.add_theme_color_override("font_outline_color", Color(0.5, 0.1, 0.3, 0.5))

func _setup_button_animations(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.mouse_entered.connect(func(): _animate_button(btn, Vector2(1.05, 1.05)))
	btn.mouse_exited.connect(func(): _animate_button(btn, Vector2(1.0, 1.0)))
	btn.button_down.connect(func(): _animate_button(btn, Vector2(0.95, 0.95)))
	btn.button_up.connect(func():
		if btn.is_hovered():
			_animate_button(btn, Vector2(1.05, 1.05))
		else:
			_animate_button(btn, Vector2(1.0, 1.0))
	)

func _animate_button(btn: Button, target_scale: Vector2) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", target_scale, 0.3)

func update_level_text(level_num: int) -> void:
	if level_label:
		level_label.text = "Level " + str(level_num)

func show_message(msg: String) -> void:
	if message_label:
		message_label.text = msg
		# Reset state for animation
		message_label.scale = Vector2(0.5, 0.5)
		message_label.modulate.a = 0.0
		
		var tween = create_tween().set_parallel(true)
		# Pop in
		tween.tween_property(message_label, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(message_label, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		# Fade out after delay
		tween.chain().tween_interval(1.5)
		var fade_out_tween = create_tween().set_parallel(true)
		fade_out_tween.tween_property(message_label, "scale", Vector2(1.1, 1.1), 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		fade_out_tween.tween_property(message_label, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func _on_undo_pressed() -> void:
	if string_manager:
		string_manager.undo()

func _on_reset_pressed() -> void:
	# 簡易的に最初の状態（4点）に戻す。厳密にはLevelManagerから初期状態をもらう方がよい
	if string_manager:
		var curr_arr = string_manager.current_string
		# current_string がある程度残っていれば初期状態に戻す
		string_manager.reset_to_initial([0, 4, 5, 9]) 

func _on_share_pressed() -> void:
	# WebGLでのみ動作するJavaScript呼び出し
	if OS.has_feature("web"):
		var text = "「あやとりパズル -ゆびさきキャンバス-」で遊びました！"
		var url = "https://unityroom.com/games/ayatori_puzzle" # 仮のURL
		var x_intent = "https://twitter.com/intent/tweet?text=" + text.uri_encode() + "&url=" + url.uri_encode()
		
		# 新しいタブでXのシェア画面を開く
		JavaScriptBridge.eval("window.open('%s', '_blank');" % x_intent)
	else:
		print("X Share: ", "「あやとりパズル -ゆびさきキャンバス-」で遊びました！")

