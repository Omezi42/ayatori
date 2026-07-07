class_name UIManager extends CanvasLayer

@export var string_manager: StringManager
@export var undo_button: Button
@export var reset_button: Button
@export var share_button: Button
@export var level_label: Label
@export var message_label: Label
@export var moves_label: Label

@onready var goal_panel: PanelContainer = _get_goal_panel()
@onready var goal_texture: TextureRect = _get_goal_texture()
@onready var clear_dim_rect: ColorRect = get_node_or_null("Control/ClearDimRect")
@onready var transition_rect: ColorRect = get_node_or_null("Control/TransitionRect")

func _get_goal_panel() -> PanelContainer:
	var p = get_node_or_null("Control/HeaderHBox/GoalPanel")
	if not p: p = get_node_or_null("Control/GoalPanel")
	return p as PanelContainer

func _get_goal_texture() -> TextureRect:
	var t = get_node_or_null("Control/HeaderHBox/GoalPanel/GoalVBox/GoalTextureRect")
	if not t: t = get_node_or_null("Control/GoalPanel/VBoxContainer/GoalTextureRect")
	if not t: t = get_node_or_null("Control/GoalPanel/GoalVBox/GoalTextureRect")
	return t as TextureRect

# リセット用に現在のレベルの初期状態を保持
var _current_initial_state: Array[int] = [0, 4, 5, 9]

signal next_level_requested
signal guide_toggled(is_visible: bool)
signal hint_requested

var clear_particles: CPUParticles2D
var clear_sound: AudioStreamPlayer
var center_container: CenterContainer
var result_panel: PanelContainer
var next_button: Button
var result_stars_label: Label
var res_home_btn: Button
var res_share_icon_btn: Button
var share_menu_panel: PanelContainer
var copy_image_btn: Button
var post_x_btn: Button
var res_select_btn: Button

var ui_target_drawer: TargetDrawer
var guide_enabled: bool = false

var settings_panel: PanelContainer
var settings_btn: Button
var hint_button: Button
var home_btn: Button
var guide_toggle_button: CheckButton

var hint_thinking_panel: PanelContainer
var hint_spinner_icon: TextureRect
var _is_hint_thinking: bool = false

var _cached_share_buffer: PackedByteArray
var _cached_share_image: Image
var _is_share_image_ready: bool = false
var _is_generating_share_image: bool = false

func _ready() -> void:
	# 画面遷移アニメーション
	if transition_rect:
		transition_rect.show()
		transition_rect.modulate.a = 1.0
		var trans_tween = create_tween()
		trans_tween.tween_property(transition_rect, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
		trans_tween.tween_callback(transition_rect.hide)

	_setup_header()
	_setup_footer()
	_setup_dynamic_nodes()
	_setup_settings_panel()
	_setup_layer_order()
	_apply_premium_styles()
	
	if message_label:
		message_label.text = ""
		message_label.modulate.a = 0.0
		message_label.scale = Vector2(0.5, 0.5)

func _process(delta: float) -> void:
	if _is_hint_thinking:
		if hint_spinner_icon:
			hint_spinner_icon.pivot_offset = hint_spinner_icon.size / 2.0
			hint_spinner_icon.rotation += 8.0 * delta
		if hint_thinking_panel:
			hint_thinking_panel.position = Vector2(640 - hint_thinking_panel.size.x / 2.0, 95)

# === ヘッダー構築（Phase 2+3: 80px、ホームボタン左端） ===
func _setup_header() -> void:
	var header = get_node_or_null("Control/HeaderHBox")
	if not header:
		header = get_node_or_null("Control/HBoxContainer")
	if not header:
		return
	
	# ホームボタンをヘッダー左端に追加
	home_btn = Button.new()
	home_btn.text = ""
	home_btn.custom_minimum_size = ThemeConfig.MIN_TAP_SIZE
	home_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var home_tex = load("res://assets/ic_field_farm_01_trimmed.svg")
	if home_tex:
		home_btn.icon = home_tex
		home_btn.add_theme_constant_override("icon_max_width", 28)
	home_btn.pressed.connect(func(): _transition_to_scene("res://scenes/Title.tscn"))
	header.add_child(home_btn)
	header.move_child(home_btn, 0)
	
	# InfoPanel のラベルスタイル
	if level_label:
		level_label.add_theme_font_size_override("font_size", 24)
	if moves_label:
		moves_label.add_theme_font_size_override("font_size", 18)
	
	# GoalPanelをコンパクトに
	if goal_panel:
		goal_panel.custom_minimum_size = Vector2(180, 140)
		goal_panel.rotation = 0.0  # ポラロイド傾きを廃止

# === フッター構築（Phase 3: 100px） ===
func _setup_footer() -> void:
	var footer = get_node_or_null("Control/FooterHBox")
	if not footer:
		footer = get_node_or_null("Control/HBoxContainer")
	if not footer:
		return
	
	# ヒントボタン (フリーモード以外でのみ追加)
	if not (get_tree() and get_tree().current_scene is LevelEditor):
		hint_button = Button.new()
		hint_button.text = "ヒント"
		hint_button.custom_minimum_size = ThemeConfig.MIN_TAP_SIZE
		var hint_tex = load("res://assets/ic_social_lightbulb_01_trimmed.svg")
		if hint_tex:
			hint_button.icon = hint_tex
			hint_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hint_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			hint_button.add_theme_constant_override("icon_max_width", 28)
		hint_button.add_theme_font_size_override("font_size", ThemeConfig.FONT_BUTTON_SMALL)
		hint_button.pressed.connect(func(): hint_requested.emit())
		footer.add_child(hint_button)
		footer.move_child(hint_button, 0)
	
	# 既存ボタンのアイコン設定
	if undo_button:
		undo_button.text = "もどす"
		undo_button.custom_minimum_size = ThemeConfig.MIN_TAP_SIZE
		var undo_tex = load("res://assets/ic_system_rotate-counterclockwise_01_trimmed.svg")
		if undo_tex:
			undo_button.icon = undo_tex
			undo_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			undo_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			undo_button.add_theme_constant_override("icon_max_width", 28)
		undo_button.add_theme_font_size_override("font_size", ThemeConfig.FONT_BUTTON_SMALL)
		undo_button.pressed.connect(_on_undo_pressed)
	if reset_button:
		reset_button.text = "リセット"
		reset_button.custom_minimum_size = ThemeConfig.MIN_TAP_SIZE
		var reset_tex = load("res://assets/ic_system_refresh_01_trimmed.svg")
		if reset_tex:
			reset_button.icon = reset_tex
			reset_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			reset_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			reset_button.add_theme_constant_override("icon_max_width", 28)
		reset_button.add_theme_font_size_override("font_size", ThemeConfig.FONT_BUTTON_SMALL)
		reset_button.pressed.connect(_on_reset_pressed)
	if share_button:
		share_button.pressed.connect(_on_share_pressed)
		share_button.hide()

	# 設定・シェアボタンをフッター右端に追加
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_child(spacer)
	
	settings_btn = Button.new()
	settings_btn.text = ""
	settings_btn.custom_minimum_size = ThemeConfig.MIN_TAP_SIZE
	var gear_tex = load("res://resources/gear_icon.svg")
	if gear_tex:
		settings_btn.icon = gear_tex
		settings_btn.add_theme_constant_override("icon_max_width", 28)
	settings_btn.pressed.connect(func(): 
		settings_panel.visible = !settings_panel.visible
	)
	footer.add_child(settings_btn)

# === 設定パネル ===
func _setup_settings_panel() -> void:
	settings_panel = PanelContainer.new()
	settings_panel.visible = false
	settings_panel.custom_minimum_size = Vector2(320, 0)
	settings_panel.grow_horizontal = Control.GROW_DIRECTION_END
	settings_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	settings_panel.position = Vector2(920, 620)
	settings_panel.add_theme_stylebox_override("panel", ThemeConfig.create_settings_panel_style())
	
	var set_vbox = VBoxContainer.new()
	set_vbox.add_theme_constant_override("separation", ThemeConfig.SPACING_SM)
	settings_panel.add_child(set_vbox)
	
	var rule_label = Label.new()
	rule_label.text = "【あそびかた】\nゆびにかかっている糸をドラッグして\n別のゆびにかけたり、\nタップして外したりして\n右上の目標の形を作ろう！"
	rule_label.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
	rule_label.add_theme_font_size_override("font_size", ThemeConfig.FONT_CAPTION)
	rule_label.add_theme_constant_override("outline_size", 0)
	set_vbox.add_child(rule_label)
	
	var sep = HSeparator.new()
	set_vbox.add_child(sep)
	
	# ガイドトグル（設定内に統合・SVGアイコン使用）
	guide_toggle_button = CheckButton.new()
	guide_toggle_button.text = " ガイド"
	guide_toggle_button.icon = load("res://assets/ic_social_lightbulb_01_trimmed.svg")
	guide_toggle_button.add_theme_constant_override("icon_max_width", 24)
	guide_toggle_button.button_pressed = guide_enabled
	guide_toggle_button.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	guide_toggle_button.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
	guide_toggle_button.add_theme_constant_override("outline_size", 0)
	guide_toggle_button.toggled.connect(func(toggled_on):
		guide_enabled = toggled_on
		guide_toggled.emit(toggled_on)
	)
	set_vbox.add_child(guide_toggle_button)
	
	var vol_label = ThemeConfig.create_icon_label("res://assets/ic_volume.svg", "おんりょう", ThemeConfig.FONT_BODY, 24, ThemeConfig.TEXT_DARK)
	set_vbox.add_child(vol_label)
	
	var vol_slider = HSlider.new()
	vol_slider.value = 50
	vol_slider.custom_minimum_size = Vector2(200, 30)
	vol_slider.value_changed.connect(_on_volume_changed)
	set_vbox.add_child(vol_slider)
	ThemeConfig.apply_slider_theme(vol_slider)
	
	var theme_label = ThemeConfig.create_icon_label("res://assets/ic_palette.svg", "テーマ", ThemeConfig.FONT_BODY, 24, ThemeConfig.TEXT_DARK)
	set_vbox.add_child(theme_label)
	
	var cur_t = GameSave.current_theme if GameSave else 0
	var theme_btns = ThemeConfig.create_theme_select_buttons(cur_t, func(idx):
		if GameSave:
			GameSave.current_theme = idx
			GameSave.apply_theme()
			GameSave.save_data()
	)
	set_vbox.add_child(theme_btns)
	
	$Control.add_child(settings_panel)



# === 描画順（Zオーダー）調整 ===
func _setup_layer_order() -> void:
	# ゲーム中のメニューUIを背面、クリア時の背景ディム・結果モーダル・演出・画面遷移を前面に配置
	if clear_dim_rect:
		clear_dim_rect.hide()
		clear_dim_rect.color.a = 0.0
		clear_dim_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$Control.move_child(clear_dim_rect, -1)
	if center_container:
		$Control.move_child(center_container, -1)
	if message_label:
		$Control.move_child(message_label, -1)
	if share_menu_panel:
		$Control.move_child(share_menu_panel, -1)
	if hint_thinking_panel:
		$Control.move_child(hint_thinking_panel, -1)
	if transition_rect:
		$Control.move_child(transition_rect, -1)

func _setup_dynamic_nodes() -> void:
	# パーティクル（クリア演出）
	var p_left = CPUParticles2D.new()
	p_left.emitting = false
	p_left.one_shot = true
	p_left.amount = 60
	p_left.direction = Vector2(1, -1.5).normalized()
	p_left.spread = 25
	p_left.gravity = Vector2(0, 980)
	p_left.initial_velocity_min = 600
	p_left.initial_velocity_max = 1000
	p_left.scale_amount_min = 12
	p_left.scale_amount_max = 24
	p_left.position = Vector2(0, 720)
	var grad = Gradient.new()
	grad.colors = [Color(1, 0.5, 0.5), Color(0.5, 1, 0.5), Color(0.5, 0.5, 1), Color(1, 1, 0.5), Color(1, 0.5, 1)]
	grad.offsets = [0.0, 0.25, 0.5, 0.75, 1.0]
	p_left.color_initial_ramp = grad
	add_child(p_left)
	
	var p_right = p_left.duplicate()
	p_right.position = Vector2(1280, 720)
	p_right.direction = Vector2(-1, -1.5).normalized()
	add_child(p_right)
	
	clear_particles = p_left
	clear_particles.set_meta("partner", p_right)
	
	clear_sound = AudioStreamPlayer.new()
	add_child(clear_sound)
	
	# 結果パネル
	center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Control.add_child(center_container)
	
	result_panel = PanelContainer.new()
	result_panel.visible = false
	result_panel.custom_minimum_size = Vector2(440, 340)
	center_container.add_child(result_panel)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", ThemeConfig.SPACING_LG)
	result_panel.add_child(vbox)
	
	# 上部バー（左上にホームボタン、右上にシェアアイコンボタン）
	var top_hbox = HBoxContainer.new()
	top_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_child(top_hbox)
	
	res_home_btn = Button.new()
	res_home_btn.text = ""
	res_home_btn.custom_minimum_size = ThemeConfig.MIN_TAP_SIZE
	res_home_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var home_tex = load("res://assets/ic_field_farm_01_trimmed.svg")
	if home_tex:
		res_home_btn.icon = home_tex
		res_home_btn.add_theme_constant_override("icon_max_width", 28)
	res_home_btn.pressed.connect(func(): _transition_to_scene("res://scenes/Title.tscn"))
	top_hbox.add_child(res_home_btn)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_hbox.add_child(spacer)
	
	res_share_icon_btn = Button.new()
	res_share_icon_btn.text = ""
	res_share_icon_btn.custom_minimum_size = ThemeConfig.MIN_TAP_SIZE
	res_share_icon_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var share_tex = load("res://assets/ic_system_share_01_trimmed.svg")
	if share_tex:
		res_share_icon_btn.icon = share_tex
		res_share_icon_btn.add_theme_constant_override("icon_max_width", 28)
	res_share_icon_btn.pressed.connect(_on_res_share_icon_pressed)
	top_hbox.add_child(res_share_icon_btn)
	
	result_stars_label = Label.new()
	result_stars_label.add_theme_font_size_override("font_size", 56)
	result_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_stars_label.add_theme_color_override("font_color", ThemeConfig.STAR_GOLD)
	result_stars_label.add_theme_color_override("font_outline_color", ThemeConfig.STAR_OUTLINE)
	result_stars_label.add_theme_constant_override("outline_size", 12)
	result_stars_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.2))
	result_stars_label.add_theme_constant_override("shadow_offset_x", 0)
	result_stars_label.add_theme_constant_override("shadow_offset_y", 6)
	vbox.add_child(result_stars_label)
	
	next_button = Button.new()
	next_button.text = "つぎへ"
	next_button.add_theme_font_size_override("font_size", ThemeConfig.FONT_BUTTON_SECONDARY)
	next_button.custom_minimum_size = Vector2(200, 60)
	next_button.pressed.connect(_on_next_pressed)
	vbox.add_child(next_button)
	
	res_select_btn = Button.new()
	res_select_btn.text = "ステージ選択にもどる"
	res_select_btn.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	res_select_btn.custom_minimum_size = ThemeConfig.MIN_TAP_SIZE
	res_select_btn.pressed.connect(_on_res_select_pressed)
	vbox.add_child(res_select_btn)
	
	# シェアメニューパネル（画像をコピーとXに投稿）
	share_menu_panel = PanelContainer.new()
	share_menu_panel.visible = false
	share_menu_panel.custom_minimum_size = Vector2(230, 0)
	$Control.add_child(share_menu_panel)
	
	var share_menu_vbox = VBoxContainer.new()
	share_menu_vbox.add_theme_constant_override("separation", ThemeConfig.SPACING_SM)
	share_menu_panel.add_child(share_menu_vbox)
	
	copy_image_btn = Button.new()
	copy_image_btn.text = "画像をコピー"
	copy_image_btn.custom_minimum_size = Vector2(200, 48)
	copy_image_btn.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	copy_image_btn.pressed.connect(_on_copy_image_pressed)
	share_menu_vbox.add_child(copy_image_btn)
	
	post_x_btn = Button.new()
	post_x_btn.text = "Xに投稿"
	post_x_btn.custom_minimum_size = Vector2(200, 48)
	post_x_btn.add_theme_font_size_override("font_size", ThemeConfig.FONT_BODY)
	post_x_btn.pressed.connect(_on_post_x_pressed)
	share_menu_vbox.add_child(post_x_btn)
	
	# GoalPanel内のターゲット描画
	ui_target_drawer = TargetDrawer.new()
	var wrapper = Control.new()
	wrapper.custom_minimum_size = Vector2(160, 120)
	wrapper.clip_contents = true
	
	ui_target_drawer.scale = Vector2(0.24, 0.24)
	ui_target_drawer.position = Vector2(80 - (640 * 0.24), 60 - (360 * 0.24))
	
	wrapper.add_child(ui_target_drawer)
	if goal_panel:
		var vbox_target = goal_panel.get_node_or_null("GoalVBox")
		if not vbox_target: vbox_target = goal_panel.get_node_or_null("VBoxContainer")
		if vbox_target:
			vbox_target.add_child(wrapper)
		else:
			for child in goal_panel.get_children():
				if child is VBoxContainer:
					child.add_child(wrapper)
					break
	
	if goal_texture:
		goal_texture.hide()
		
	# ヒント考え中インジケーター（フローティングピル）
	hint_thinking_panel = PanelContainer.new()
	hint_thinking_panel.visible = false
	var pill_style = ThemeConfig.create_panel_style(ThemeConfig.BG_WHITE, ThemeConfig.RADIUS_PILL, 8)
	pill_style.border_width_left = 3
	pill_style.border_width_right = 3
	pill_style.border_width_top = 3
	pill_style.border_width_bottom = 3
	pill_style.border_color = ThemeConfig.PRIMARY
	pill_style.content_margin_left = 24
	pill_style.content_margin_right = 24
	pill_style.content_margin_top = 10
	pill_style.content_margin_bottom = 10
	hint_thinking_panel.add_theme_stylebox_override("panel", pill_style)
	hint_thinking_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint_thinking_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var hbox_thinking = HBoxContainer.new()
	hbox_thinking.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_thinking.add_theme_constant_override("separation", ThemeConfig.SPACING_SM)
	hint_thinking_panel.add_child(hbox_thinking)
	
	hint_spinner_icon = TextureRect.new()
	var spinner_tex = load("res://assets/ic_system_refresh_01_trimmed.svg")
	if spinner_tex:
		hint_spinner_icon.texture = spinner_tex
	hint_spinner_icon.custom_minimum_size = Vector2(28, 28)
	hint_spinner_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hint_spinner_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hint_spinner_icon.modulate = ThemeConfig.PRIMARY_DARK
	hbox_thinking.add_child(hint_spinner_icon)
	
	var thinking_label = Label.new()
	thinking_label.text = "ヒントを考え中..."
	thinking_label.add_theme_font_size_override("font_size", 22)
	thinking_label.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
	hbox_thinking.add_child(thinking_label)
	
	$Control.add_child(hint_thinking_panel)

# === Phase 5: 統一スタイル適用 ===
func _apply_premium_styles() -> void:
	var btn_normal = ThemeConfig.create_button_style(ThemeConfig.PRIMARY, 4.0, ThemeConfig.RADIUS_XL)
	btn_normal.content_margin_left = 16
	btn_normal.content_margin_right = 16
	btn_normal.content_margin_top = 8
	btn_normal.content_margin_bottom = 8
	
	var btn_hover = btn_normal.duplicate()
	btn_hover.bg_color = ThemeConfig.PRIMARY_LIGHT
	
	var btn_pressed = btn_normal.duplicate()
	btn_pressed.content_margin_top += 4
	btn_pressed.content_margin_bottom -= 4
	
	var free_mode_share_btn = get_node_or_null("Control/HeaderHBox/FreeModeShareBtn") as Button
	
	# 全ボタンにスタイル適用
	for btn in [hint_button, undo_button, reset_button, share_button, settings_btn, home_btn, res_home_btn, res_share_icon_btn, free_mode_share_btn]:
		if btn:
			ThemeConfig.apply_icon_button_theme(btn, btn_normal, btn_pressed)
			btn.add_theme_stylebox_override("hover", btn_hover)
			ThemeConfig.setup_button_animations(btn)
	
	# InfoPanel スタイルと文字色設定 (背景パネル有無で自動調整)
	var info_panel = get_node_or_null("Control/HeaderHBox/InfoPanel")
	var label_color = ThemeConfig.TEXT_LIGHT if info_panel != null else ThemeConfig.TEXT_DARK
	var outline_color = Color(ThemeConfig.PRIMARY_DARK, 0.8) if info_panel != null else Color(1, 1, 1, 0.8)
	
	if info_panel:
		var info_style = ThemeConfig.create_panel_style(
			Color(ThemeConfig.PRIMARY.r, ThemeConfig.PRIMARY.g, ThemeConfig.PRIMARY.b, 0.95),
			ThemeConfig.RADIUS_LG,
			6
		)
		info_style.content_margin_left = 16
		info_style.content_margin_right = 16
		info_style.content_margin_top = 8
		info_style.content_margin_bottom = 8
		info_panel.add_theme_stylebox_override("panel", info_style)
		
	if level_label:
		level_label.add_theme_color_override("font_color", label_color)
		level_label.add_theme_constant_override("outline_size", 4)
		level_label.add_theme_color_override("font_outline_color", outline_color)
	if moves_label:
		moves_label.add_theme_color_override("font_color", label_color)
		moves_label.add_theme_constant_override("outline_size", 3)
		moves_label.add_theme_color_override("font_outline_color", outline_color)

	# GoalPanel スタイル（コンパクトカード型）
	if goal_panel:
		var goal_style = ThemeConfig.create_panel_style(ThemeConfig.BG_WHITE, ThemeConfig.RADIUS_MD, 6)
		goal_style.content_margin_left = 12
		goal_style.content_margin_right = 12
		goal_style.content_margin_top = 8
		goal_style.content_margin_bottom = 8
		goal_panel.add_theme_stylebox_override("panel", goal_style)
		
	# 設定パネルスタイル
	if settings_panel:
		settings_panel.add_theme_stylebox_override("panel", ThemeConfig.create_panel_style())
		

		
	# 結果パネルスタイル（上部に余裕を持たせる）
	if result_panel:
		var rp_style = ThemeConfig.create_panel_style(Color(1.0, 0.97, 0.97, 0.98), ThemeConfig.RADIUS_XL, 16)
		rp_style.content_margin_top = ThemeConfig.SPACING_LG
		rp_style.content_margin_left = ThemeConfig.SPACING_LG
		rp_style.content_margin_right = ThemeConfig.SPACING_LG
		rp_style.content_margin_bottom = ThemeConfig.SPACING_LG
		result_panel.add_theme_stylebox_override("panel", rp_style)
		
		var res_vbox = result_panel.get_child(0) if result_panel.get_child_count() > 0 else null
		if res_vbox:
			for btn in res_vbox.get_children():
				if btn is Button:
					if btn == next_button:
						var primary_n = ThemeConfig.create_button_style(ThemeConfig.PRIMARY, 6.0)
						var primary_p = ThemeConfig.create_pressed_style(ThemeConfig.PRIMARY)
						ThemeConfig.apply_button_theme(btn, primary_n, primary_p)
					else:
						var sec_n = ThemeConfig.create_button_style(ThemeConfig.PRIMARY_LIGHT, 4.0)
						var sec_p = ThemeConfig.create_pressed_style(ThemeConfig.PRIMARY_LIGHT)
						ThemeConfig.apply_button_theme(btn, sec_n, sec_p)
					ThemeConfig.setup_button_animations(btn)

	# シェアメニューのスタイル
	if share_menu_panel:
		var sm_style = ThemeConfig.create_panel_style(ThemeConfig.BG_WHITE, ThemeConfig.RADIUS_MD, 12)
		sm_style.content_margin_top = 14
		sm_style.content_margin_bottom = 14
		sm_style.content_margin_left = 14
		sm_style.content_margin_right = 14
		share_menu_panel.add_theme_stylebox_override("panel", sm_style)
		
		var sm_hover = ThemeConfig.create_button_style(ThemeConfig.PRIMARY, 4.0, ThemeConfig.RADIUS_MD)
		for btn in [copy_image_btn, post_x_btn]:
			if btn:
				var btn_sec_n = ThemeConfig.create_button_style(ThemeConfig.PRIMARY_LIGHT, 4.0, ThemeConfig.RADIUS_MD)
				var btn_sec_p = ThemeConfig.create_pressed_style(ThemeConfig.PRIMARY_LIGHT, ThemeConfig.RADIUS_MD)
				ThemeConfig.apply_button_theme(btn, btn_sec_n, btn_sec_p)
				btn.add_theme_stylebox_override("hover", sm_hover)
				ThemeConfig.setup_button_animations(btn)

func apply_theme_colors() -> void:
	_apply_premium_styles()
	if settings_panel:
		ThemeConfig.update_settings_panel_colors(settings_panel, GameSave.current_theme if GameSave else 0)
	if hint_thinking_panel:
		hint_thinking_panel.add_theme_stylebox_override("panel", ThemeConfig.create_panel_style(ThemeConfig.BG_WHITE, ThemeConfig.RADIUS_PILL, 6))
		for child in hint_thinking_panel.get_children():
			if child is HBoxContainer:
				for gc in child.get_children():
					if gc is Label:
						gc.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK)
					elif gc is TextureRect:
						gc.modulate = ThemeConfig.TEXT_DARK


func _transition_to_scene(path: String) -> void:
	if share_menu_panel:
		share_menu_panel.hide()
	if transition_rect:
		transition_rect.show()
		transition_rect.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(transition_rect, "modulate:a", 1.0, 0.4)
		tw.tween_callback(func(): get_tree().change_scene_to_file(path))
	else:
		get_tree().change_scene_to_file(path)

func update_level_text(level_num: int, level_name: String = "") -> void:
	if level_label:
		if level_name.is_empty():
			level_label.text = "LEVEL " + str(level_num)
		elif level_num < 0:
			level_label.text = level_name
		elif level_num == 0:
			level_label.text = "ユーザー投稿ステージ「" + level_name + "」"
		else:
			level_label.text = "LV." + str(level_num) + " " + level_name

func update_moves_display(moves: int, optimal: int) -> void:
	if not moves_label:
		return
	var stars = 3
	if moves > optimal:
		if moves <= optimal + 2:
			stars = 2
		else:
			stars = 1
			
	var stars_text = ""
	for i in range(stars):
		stars_text += "★"
	for i in range(3 - stars):
		stars_text += "☆"
		
	moves_label.text = "%d手 / 最短%d  %s" % [moves, optimal, stars_text]

func set_result_stars(stars: int) -> void:
	if result_stars_label:
		var stars_text = ""
		for i in range(stars):
			stars_text += "★"
		for i in range(3 - stars):
			stars_text += "☆"
		var total = 0
		if GameSave: total = GameSave.total_stars
		result_stars_label.text = stars_text + "\n累計: " + str(total) + " ★"

func _animate_goal_bounce() -> void:
	if goal_panel:
		goal_panel.scale = Vector2.ZERO
		goal_panel.pivot_offset = goal_panel.size / 2.0
		var tw = create_tween()
		tw.tween_property(goal_panel, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func set_goal_texture(texture: Texture2D) -> void:
	if goal_texture:
		goal_texture.texture = texture
		if texture:
			goal_texture.show()
			if ui_target_drawer:
				ui_target_drawer.hide()
			_animate_goal_bounce()
		else:
			goal_texture.hide()
			if ui_target_drawer:
				ui_target_drawer.show()

func set_goal_layout(layout_id: int) -> void:
	if ui_target_drawer:
		ui_target_drawer.set_layout(layout_id)

func set_goal_sequence(sequence: Array[int], layout_id: int = 0) -> void:
	if ui_target_drawer:
		ui_target_drawer.set_layout(layout_id)
		ui_target_drawer.set_target(sequence)
		if goal_texture and not goal_texture.visible:
			_animate_goal_bounce()

func set_initial_state(state: Array[int]) -> void:
	_current_initial_state = state.duplicate()
	_is_share_image_ready = false
	_is_generating_share_image = false
	_cached_share_buffer = PackedByteArray()
	_cached_share_image = null
	if share_menu_panel:
		share_menu_panel.hide()
	if result_panel:
		result_panel.hide()
	if clear_dim_rect:
		clear_dim_rect.hide()
		clear_dim_rect.color.a = 0.0
		clear_dim_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if message_label:
		message_label.modulate.a = 0.0

func play_clear_animation() -> void:
	if settings_panel:
		settings_panel.visible = false
		
	if clear_sound:
		clear_sound.play()
	if clear_particles:
		clear_particles.emitting = true
		if clear_particles.has_meta("partner"):
			clear_particles.get_meta("partner").emitting = true
	
	if clear_dim_rect:
		clear_dim_rect.show()
		clear_dim_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		var dim_tw = create_tween()
		dim_tw.tween_property(clear_dim_rect, "color:a", 0.6, 0.5).set_trans(Tween.TRANS_SINE)
		
	if message_label:
		message_label.text = "クリア！"
		message_label.pivot_offset = message_label.size / 2.0
		message_label.scale = Vector2.ZERO
		message_label.rotation = -0.2
		message_label.modulate.a = 1.0
		message_label.self_modulate = Color(1, 1, 1, 1)
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(message_label, "scale", Vector2(1.3, 1.3), 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(message_label, "rotation", 0.05, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(message_label, "self_modulate", Color(1.0, 0.9, 0.4), 0.5)
		
		var seq = create_tween()
		seq.tween_interval(0.4)
		seq.tween_property(message_label, "rotation", -0.02, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		seq.tween_property(message_label, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		seq.tween_property(message_label, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		seq.tween_interval(0.3)
		seq.tween_property(message_label, "scale", Vector2(1.1, 1.1), 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		seq.parallel().tween_property(message_label, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func show_result_panel() -> void:
	_prepare_share_image()
	if message_label:
		message_label.modulate.a = 0.0
	if share_menu_panel:
		share_menu_panel.hide()
		
	if res_select_btn:
		if FirebaseManager.has_meta("is_daily") and FirebaseManager.get_meta("is_daily") == true:
			res_select_btn.text = "タイトルにもどる"
		elif FirebaseManager.has_meta("ugc_target"):
			res_select_btn.text = "お題を探すにもどる"
		else:
			res_select_btn.text = "ステージ選択にもどる"
			
	if result_panel:
		result_panel.show()
		result_panel.scale = Vector2.ZERO
		result_panel.pivot_offset = Vector2(220, 170)
		var tween = create_tween()
		tween.tween_property(result_panel, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_next_pressed() -> void:
	if share_menu_panel:
		share_menu_panel.hide()
	if result_panel:
		result_panel.hide()
	if message_label:
		message_label.modulate.a = 0.0
	if clear_dim_rect:
		clear_dim_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tw = create_tween()
		tw.tween_property(clear_dim_rect, "color:a", 0.0, 0.3)
		tw.tween_callback(clear_dim_rect.hide)
	
	if transition_rect:
		transition_rect.show()
		var tw = create_tween()
		tw.tween_property(transition_rect, "modulate:a", 1.0, 0.3)
		tw.tween_callback(func():
			next_level_requested.emit()
			var tw2 = create_tween()
			tw2.tween_property(transition_rect, "modulate:a", 0.0, 0.5)
			tw2.tween_callback(transition_rect.hide)
		)
	else:
		next_level_requested.emit()

func show_message(msg: String) -> void:
	if message_label:
		message_label.text = msg
		message_label.scale = Vector2(0.5, 0.5)
		message_label.modulate.a = 0.0
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(message_label, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(message_label, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		tween.chain().tween_interval(1.5)
		tween.chain().tween_property(message_label, "scale", Vector2(1.1, 1.1), 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(message_label, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func set_hint_thinking(is_thinking: bool) -> void:
	_is_hint_thinking = is_thinking
	if hint_button:
		hint_button.disabled = is_thinking
		hint_button.text = "考え中..." if is_thinking else "ヒント"
	
	if not hint_thinking_panel:
		return
		
	if is_thinking:
		hint_thinking_panel.show()
		hint_thinking_panel.modulate.a = 0.0
		hint_thinking_panel.scale = Vector2(0.8, 0.8)
		hint_thinking_panel.pivot_offset = hint_thinking_panel.size / 2.0
		var tw = create_tween().set_parallel(true)
		tw.tween_property(hint_thinking_panel, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(hint_thinking_panel, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		var tw = create_tween().set_parallel(true)
		tw.tween_property(hint_thinking_panel, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_property(hint_thinking_panel, "scale", Vector2(0.9, 0.9), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(hint_thinking_panel.hide)

func _on_res_select_pressed() -> void:
	if FirebaseManager.has_meta("is_daily") and FirebaseManager.get_meta("is_daily") == true:
		_transition_to_scene("res://scenes/Title.tscn")
	elif FirebaseManager.has_meta("ugc_target"):
		_transition_to_scene("res://scenes/LevelBrowser.tscn")
	else:
		_transition_to_scene("res://scenes/LevelSelect.tscn")

func _on_undo_pressed() -> void:
	if string_manager:
		string_manager.undo()

func _on_reset_pressed() -> void:
	if string_manager:
		string_manager.reset_to_initial(_current_initial_state.duplicate())

func _prepare_share_image() -> void:
	if _is_generating_share_image or _is_share_image_ready:
		return
	_is_generating_share_image = true
	_generate_share_image(func(buffer: PackedByteArray, img: Image):
		_cached_share_buffer = buffer
		_cached_share_image = img
		_is_share_image_ready = true
		_is_generating_share_image = false
	)

func _get_ready_share_image(callback: Callable) -> void:
	if _is_share_image_ready and _cached_share_buffer.size() > 0:
		callback.call(_cached_share_buffer, _cached_share_image)
		return
	if not _is_generating_share_image:
		_prepare_share_image()
	while _is_generating_share_image:
		await get_tree().process_frame
	callback.call(_cached_share_buffer, _cached_share_image)

func _generate_share_image(callback: Callable) -> void:
	var vp = SubViewport.new()
	vp.size = Vector2(800, 640)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	var bg = ColorRect.new()
	bg.color = ThemeConfig.BG_WHITE if ThemeConfig else Color.WHITE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp.add_child(bg)
	
	var inner = ColorRect.new()
	inner.color = Color(0.97, 0.97, 0.97)
	inner.position = Vector2(40, 140)
	inner.size = Vector2(720, 460)
	vp.add_child(inner)
	
	var title_lbl = Label.new()
	title_lbl.text = level_label.text if level_label else "あやとりパズル"
	title_lbl.add_theme_font_size_override("font_size", 40)
	title_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_DARK if ThemeConfig else Color(0.2, 0.2, 0.2))
	title_lbl.position = Vector2(40, 30)
	title_lbl.size = Vector2(720, 50)
	vp.add_child(title_lbl)
	
	if result_stars_label and result_stars_label.text != "":
		var stars_str = result_stars_label.text.split("\n")[0]
		var stars_lbl = Label.new()
		stars_lbl.text = stars_str
		stars_lbl.add_theme_font_size_override("font_size", 48)
		stars_lbl.add_theme_color_override("font_color", ThemeConfig.STAR_GOLD if ThemeConfig else Color(1, 0.8, 0))
		stars_lbl.add_theme_color_override("font_outline_color", ThemeConfig.STAR_OUTLINE if ThemeConfig else Color(0.8, 0.6, 0))
		stars_lbl.add_theme_constant_override("outline_size", 8)
		stars_lbl.position = Vector2(40, 80)
		vp.add_child(stars_lbl)
	
	var line_area = Control.new()
	line_area.position = Vector2(40, 140)
	line_area.size = Vector2(720, 460)
	vp.add_child(line_area)
	
	var line = Line2D.new()
	line.width = 16.0
	line.default_color = GameSave.get_current_string_color() if GameSave and GameSave.has_method("get_current_string_color") else (ThemeConfig.PRIMARY if ThemeConfig else Color(1, 0, 0))
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	var main_node = get_parent()
	if main_node and main_node.has_node("StringDrawer"):
		var string_drawer = main_node.get_node("StringDrawer")
		if string_manager and string_drawer:
			var arr = string_manager.current_string
			var fp = string_drawer.finger_positions
			var min_x = 9999.0
			var max_x = -9999.0
			var min_y = 9999.0
			var max_y = -9999.0
			for f_id in arr:
				if fp.has(f_id):
					var p = fp[f_id]
					if p.x < min_x: min_x = p.x
					if p.x > max_x: max_x = p.x
					if p.y < min_y: min_y = p.y
					if p.y > max_y: max_y = p.y
					
			var size_x = max_x - min_x
			var size_y = max_y - min_y
			var scale_factor = 1.0
			if size_x > 0 and size_y > 0:
				scale_factor = min(680.0 / (size_x + 20), 420.0 / (size_y + 20))
				
			var offset_x = (720.0 - size_x * scale_factor) / 2.0
			var offset_y = (460.0 - size_y * scale_factor) / 2.0
			
			for f_id in arr:
				if fp.has(f_id):
					var p = fp[f_id]
					var sp = Vector2((p.x - min_x) * scale_factor + offset_x, (p.y - min_y) * scale_factor + offset_y)
					line.add_point(sp)
			if arr.size() > 0 and fp.has(arr[0]):
				var p = fp[arr[0]]
				var sp = Vector2((p.x - min_x) * scale_factor + offset_x, (p.y - min_y) * scale_factor + offset_y)
				line.add_point(sp)
	line_area.add_child(line)
	
	add_child(vp)
	await get_tree().process_frame
	await get_tree().process_frame
	
	var img = vp.get_texture().get_image()
	var buffer = img.save_png_to_buffer()
	vp.queue_free()
	
	callback.call(buffer, img)

func _on_volume_changed(val: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val / 100.0))

func _on_share_pressed() -> void:
	var share_text = "「あやとりパズル -ゆびさきキャンバス-」で遊びました！ #unityroom"
	if level_label and level_label.text != "":
		share_text = "「あやとりパズル」で " + level_label.text + " をクリアしたよ！ #unityroom"
		
	_get_ready_share_image(func(buffer: PackedByteArray, _img: Image = null):
		if OS.has_feature("web"):
			var js_code = """
				var array = new Uint8Array(%s);
				var blob = new Blob([array], {type: 'image/png'});
				var file = new File([blob], 'ayatori_clear.png', {type: 'image/png'});
				var shareData = {
					title: 'あやとりパズル',
					text: '%s',
					url: 'https://unityroom.com/games/ayatori_puzzle',
					files: [file]
				};
				if (navigator.canShare && navigator.canShare({ files: [file] })) {
					navigator.share(shareData).catch((err) => console.log('Share failed:', err));
				} else {
					var intentUrl = 'https://x.com/intent/tweet?text=' + encodeURIComponent('%s') + '&url=' + encodeURIComponent('https://unityroom.com/games/ayatori_puzzle');
					window.open(intentUrl, '_blank');
				}
			""" % [str(Array(buffer)), share_text.replace("'", "\\'"), share_text.replace("'", "\\'")]
			JavaScriptBridge.eval(js_code)
		else:
			DisplayServer.clipboard_set(share_text)
			print("X Share text copied. Buffer size: ", buffer.size())
	)

func toggle_share_menu(target_btn: Control) -> void:
	if not share_menu_panel:
		return
	share_menu_panel.visible = !share_menu_panel.visible
	if share_menu_panel.visible:
		var panel_width = max(share_menu_panel.size.x, share_menu_panel.custom_minimum_size.x)
		var btn_rect = target_btn.get_global_rect()
		share_menu_panel.global_position = Vector2(btn_rect.end.x - panel_width, btn_rect.end.y + 8)
		share_menu_panel.scale = Vector2(0.8, 0.8)
		share_menu_panel.pivot_offset = Vector2(panel_width, 0)
		var tw = create_tween()
		tw.tween_property(share_menu_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_res_share_icon_pressed() -> void:
	toggle_share_menu(res_share_icon_btn)

func _on_copy_image_pressed() -> void:
	if share_menu_panel:
		share_menu_panel.hide()
	var share_text = "「あやとりパズル -ゆびさきキャンバス-」で遊びました！ #unityroom"
	if level_label and level_label.text != "":
		if level_label.text == "フリーモード":
			share_text = "「あやとりパズル」のフリーモードで図形を作ったよ！ #unityroom"
		else:
			share_text = "「あやとりパズル」で " + level_label.text + " をクリアしたよ！ #unityroom"
		
	_get_ready_share_image(func(buffer: PackedByteArray, img: Image):
		if OS.has_feature("web"):
			var js_code = """
				var array = new Uint8Array(%s);
				var blob = new Blob([array], {type: 'image/png'});
				function showToast(msg) {
					var d = document.createElement('div');
					d.textContent = msg;
					d.style.cssText = 'position:fixed;top:20px;left:50%%;transform:translateX(-50%%);background:rgba(40,40,40,0.95);color:#fff;padding:12px 24px;border-radius:30px;font-size:16px;font-family:sans-serif;z-index:999999;box-shadow:0 4px 12px rgba(0,0,0,0.3);transition:opacity 0.3s;';
					document.body.appendChild(d);
					setTimeout(function() { d.style.opacity = '0'; setTimeout(function() { d.remove(); }, 300); }, 3000);
				}
				function showImageModal() {
					var url = URL.createObjectURL(blob);
					var modal = document.createElement('div');
					modal.style.cssText = 'position:fixed;top:0;left:0;width:100%%;height:100%%;background:rgba(0,0,0,0.8);z-index:999999;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:20px;box-sizing:border-box;font-family:sans-serif;';
					var container = document.createElement('div');
					container.style.cssText = 'background:#fff;border-radius:16px;padding:20px;max-width:90%%;max-height:90%%;display:flex;flex-direction:column;align-items:center;box-shadow:0 10px 30px rgba(0,0,0,0.5);';
					var title = document.createElement('div');
					title.textContent = 'クリア画像';
					title.style.cssText = 'font-size:20px;font-weight:bold;color:#333;margin-bottom:8px;';
					container.appendChild(title);
					var desc = document.createElement('div');
					desc.textContent = '※お使いの環境では画像の直接コピーが制限されています。下の画像を右クリック（スマホは長押し）してコピーまたは保存してください。';
					desc.style.cssText = 'font-size:13px;color:#666;margin-bottom:16px;text-align:center;line-height:1.4;max-width:400px;';
					container.appendChild(desc);
					var img = document.createElement('img');
					img.src = url;
					img.style.cssText = 'max-width:100%%;max-height:50vh;border-radius:8px;border:1px solid #eee;margin-bottom:16px;user-select:all;-webkit-user-select:all;';
					container.appendChild(img);
					var btnBox = document.createElement('div');
					btnBox.style.cssText = 'display:flex;gap:12px;width:100%%;justify-content:center;';
					var dlBtn = document.createElement('a');
					dlBtn.href = url;
					dlBtn.download = 'ayatori_clear.png';
					dlBtn.textContent = '画像をダウンロード';
					dlBtn.style.cssText = 'background:#ff8c00;color:#fff;text-decoration:none;padding:10px 20px;border-radius:24px;font-weight:bold;font-size:14px;display:inline-block;cursor:pointer;';
					btnBox.appendChild(dlBtn);
					var closeBtn = document.createElement('button');
					closeBtn.textContent = '閉じる';
					closeBtn.style.cssText = 'background:#f0f0f0;color:#333;border:none;padding:10px 20px;border-radius:24px;font-weight:bold;font-size:14px;cursor:pointer;';
					closeBtn.onclick = function() { modal.remove(); URL.revokeObjectURL(url); };
					btnBox.appendChild(closeBtn);
					container.appendChild(btnBox);
					modal.appendChild(container);
					modal.onclick = function(e) { if (e.target === modal) { modal.remove(); URL.revokeObjectURL(url); } };
					document.body.appendChild(modal);
				}
				if (navigator.clipboard && navigator.clipboard.write) {
					var item = new ClipboardItem({ 'image/png': blob });
					navigator.clipboard.write([item]).then(() => {
						showToast('✓ 画像をクリップボードにコピーしました！');
					}).catch((err) => {
						console.log('Clipboard write failed:', err);
						if (navigator.canShare && navigator.canShare({ files: [new File([blob], 'ayatori_clear.png', {type: 'image/png'})] })) {
							var file = new File([blob], 'ayatori_clear.png', {type: 'image/png'});
							navigator.share({
								title: 'あやとりパズル',
								text: '%s',
								url: 'https://unityroom.com/games/ayatori_puzzle',
								files: [file]
							}).catch(() => showImageModal());
						} else {
							showImageModal();
						}
					});
				} else if (navigator.canShare && navigator.canShare({ files: [new File([blob], 'ayatori_clear.png', {type: 'image/png'})] })) {
					var file = new File([blob], 'ayatori_clear.png', {type: 'image/png'});
					navigator.share({
						title: 'あやとりパズル',
						text: '%s',
						url: 'https://unityroom.com/games/ayatori_puzzle',
						files: [file]
					}).catch(() => showImageModal());
				} else {
					showImageModal();
				}
			""" % [str(Array(buffer)), share_text.replace("'", "\\'"), share_text.replace("'", "\\'")]
			JavaScriptBridge.eval(js_code)
		else:
			if img:
				var path = "user://ayatori_share.png"
				img.save_png(path)
				OS.shell_open(ProjectSettings.globalize_path("user://"))
				show_message("画像を出力しました！")
			else:
				DisplayServer.clipboard_set(share_text)
				show_message("シェアテキストをコピーしました！")
	)

func _on_post_x_pressed() -> void:
	if share_menu_panel:
		share_menu_panel.hide()
	var share_text = "「あやとりパズル -ゆびさきキャンバス-」で遊びました！ #unityroom"
	if level_label and level_label.text != "":
		if level_label.text == "フリーモード":
			share_text = "「あやとりパズル」のフリーモードで図形を作ったよ！ #unityroom"
		else:
			share_text = "「あやとりパズル」で " + level_label.text + " をクリアしたよ！ #unityroom"
		
	var tweet_url = "https://x.com/intent/tweet?text=" + share_text.uri_encode() + "&url=" + "https://unityroom.com/games/ayatori_puzzle".uri_encode()
	
	_get_ready_share_image(func(buffer: PackedByteArray, img: Image):
		if OS.has_feature("web"):
			var js_code = """
				var array = new Uint8Array(%s);
				var blob = new Blob([array], {type: 'image/png'});
				function showToast(msg) {
					var d = document.createElement('div');
					d.textContent = msg;
					d.style.cssText = 'position:fixed;top:20px;left:50%%;transform:translateX(-50%%);background:rgba(40,40,40,0.95);color:#fff;padding:12px 24px;border-radius:30px;font-size:16px;font-family:sans-serif;z-index:999999;box-shadow:0 4px 12px rgba(0,0,0,0.3);transition:opacity 0.3s;';
					document.body.appendChild(d);
					setTimeout(function() { d.style.opacity = '0'; setTimeout(function() { d.remove(); }, 300); }, 3500);
				}
				function showImageModal() {
					var url = URL.createObjectURL(blob);
					var modal = document.createElement('div');
					modal.style.cssText = 'position:fixed;top:0;left:0;width:100%%;height:100%%;background:rgba(0,0,0,0.8);z-index:999999;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:20px;box-sizing:border-box;font-family:sans-serif;';
					var container = document.createElement('div');
					container.style.cssText = 'background:#fff;border-radius:16px;padding:20px;max-width:90%%;max-height:90%%;display:flex;flex-direction:column;align-items:center;box-shadow:0 10px 30px rgba(0,0,0,0.5);';
					var title = document.createElement('div');
					title.textContent = 'X(Twitter)への画像添付';
					title.style.cssText = 'font-size:20px;font-weight:bold;color:#333;margin-bottom:8px;';
					container.appendChild(title);
					var desc = document.createElement('div');
					desc.textContent = '※環境により自動コピーが制限されました。下の画像を右クリック（スマホは長押し）してコピーまたは保存し、Xの投稿画面に添付してください。';
					desc.style.cssText = 'font-size:13px;color:#666;margin-bottom:16px;text-align:center;line-height:1.4;max-width:400px;';
					container.appendChild(desc);
					var img = document.createElement('img');
					img.src = url;
					img.style.cssText = 'max-width:100%%;max-height:50vh;border-radius:8px;border:1px solid #eee;margin-bottom:16px;user-select:all;-webkit-user-select:all;';
					container.appendChild(img);
					var btnBox = document.createElement('div');
					btnBox.style.cssText = 'display:flex;gap:12px;width:100%%;justify-content:center;';
					var dlBtn = document.createElement('a');
					dlBtn.href = url;
					dlBtn.download = 'ayatori_clear.png';
					dlBtn.textContent = '画像をダウンロード';
					dlBtn.style.cssText = 'background:#ff8c00;color:#fff;text-decoration:none;padding:10px 20px;border-radius:24px;font-weight:bold;font-size:14px;display:inline-block;cursor:pointer;';
					btnBox.appendChild(dlBtn);
					var closeBtn = document.createElement('button');
					closeBtn.textContent = '閉じる';
					closeBtn.style.cssText = 'background:#f0f0f0;color:#333;border:none;padding:10px 20px;border-radius:24px;font-weight:bold;font-size:14px;cursor:pointer;';
					closeBtn.onclick = function() { modal.remove(); URL.revokeObjectURL(url); };
					btnBox.appendChild(closeBtn);
					container.appendChild(btnBox);
					modal.appendChild(container);
					modal.onclick = function(e) { if (e.target === modal) { modal.remove(); URL.revokeObjectURL(url); } };
					document.body.appendChild(modal);
				}
				if (navigator.clipboard && navigator.clipboard.write) {
					var item = new ClipboardItem({ 'image/png': blob });
					navigator.clipboard.write([item]).then(() => {
						showToast('✓ 画像をクリップボードにコピーしました！投稿画面で貼り付け（Ctrl+V）してください');
					}).catch((err) => {
						console.log('Clipboard write failed:', err);
						showImageModal();
					});
				} else {
					showImageModal();
				}
				window.open('%s', '_blank');
			""" % [str(Array(buffer)), tweet_url.replace("'", "\\'")]
			JavaScriptBridge.eval(js_code)
		else:
			if img:
				var path = "user://ayatori_share.png"
				img.save_png(path)
				OS.shell_open(ProjectSettings.globalize_path("user://"))
				show_message("画像を出力しました！")
			else:
				DisplayServer.clipboard_set(share_text)
				show_message("シェアテキストをコピーしました！")
			OS.shell_open(tweet_url)
	)
