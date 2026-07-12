extends Node

# ===== カラーパレット (テーマ切替対応のためvarで定義) =====
var PRIMARY = Color("#F2849E")         # メインカラー
var PRIMARY_DARK = Color("#D95B7A")    # ボタン影・アウトライン
var PRIMARY_LIGHT = Color("#F5B7C6")   # セカンダリボタン・枠線
var ACCENT = Color("#8ECAE6")          # アクセント（デイリー等）
var BG_WARM = Color("#FFF8E7")         # 背景
var BG_WHITE = Color("#FFFFFF")        # パネル背景
var TEXT_DARK = Color("#5C4B51")       # テキスト暗色
var TEXT_MID = Color("#8A7A80")        # テキスト中間色
var TEXT_LIGHT = Color.WHITE           # テキスト明色
var SHADOW = Color(0.0, 0.0, 0.0, 0.1) # 汎用シャドウ
var STAR_GOLD = Color("#FFC800")       # 星の色（明るく輝くサンシャインゴールド）
var STAR_OUTLINE = Color("#F57C00")    # 星のアウトライン（温かく鮮やかなゴールデンオレンジ）

# 描画・オブジェクト用テーマカラー
var string_normal = Color("#F573A0")
var string_tense = Color("#FFA6C9")
var string_target = Color(0.96, 0.45, 0.65, 1.0)
var finger_main = Color("#FFB6C1")
var finger_shadow = Color(0, 0, 0, 0.1)
var board_bg = Color("#E6D8CE")
var board_base = Color("#D4E6CE")
var board_line = Color("#B5CCAD")

func set_theme_mode(theme_idx: int) -> void:
	if theme_idx == 1: # モノクロ (Monochrome - 洗練されたシルバー・モノトーン世界)
		PRIMARY = Color("#707070")
		PRIMARY_DARK = Color("#454545")
		PRIMARY_LIGHT = Color("#A3A3A3")
		ACCENT = Color("#78909C")
		BG_WARM = Color("#F4F6F7")
		BG_WHITE = Color("#FFFFFF")
		TEXT_DARK = Color("#263238")
		TEXT_MID = Color("#78909C")
		TEXT_LIGHT = Color.WHITE
		SHADOW = Color(0.0, 0.0, 0.0, 0.15)
		
		string_normal = Color("#546E7A")
		string_tense = Color("#90A4AE")
		string_target = Color(0.45, 0.55, 0.6, 1.0)
		finger_main = Color("#CFD8DC")
		finger_shadow = Color(0, 0, 0, 0.15)
		board_bg = Color("#ECEFF1")
		board_base = Color("#E0E0E0")
		board_line = Color("#B0BEC5")
	elif theme_idx == 2: # ダーク (Dark - 夜に優しいミッドナイト＆ネオン世界)
		PRIMARY = Color("#4361EE")         # メインカラー（ミッドナイトネオンブルー）
		PRIMARY_DARK = Color("#2B3A8C")    # ボタン影・アウトライン（ディープネイビー）
		PRIMARY_LIGHT = Color("#4CC9F0")   # セカンダリボタン・枠線（ネオンシアン）
		ACCENT = Color("#58E0C4")          # アクセント（ミントシアン）
		BG_WARM = Color("#1A1B2F")         # 背景
		BG_WHITE = Color("#25273F")        # パネル背景
		TEXT_DARK = Color("#EAEBFF")       # テキスト暗色
		TEXT_MID = Color("#9E9FB8")        # テキスト中間色
		TEXT_LIGHT = Color.WHITE           # テキスト明色
		SHADOW = Color(0.0, 0.0, 0.0, 0.3)
		
		string_normal = Color("#FF6392")
		string_tense = Color("#FF9EE2")
		string_target = Color(0.9, 0.4, 0.65, 1.0)
		finger_main = Color("#3D3F61")
		finger_shadow = Color(0, 0, 0, 0.4)
		board_bg = Color("#202238")
		board_base = Color("#2A2C48")
		board_line = Color("#454868")
	else: # 通常 (Normal - 温かく可愛いパステルピンク世界)
		PRIMARY = Color("#F2849E")
		PRIMARY_DARK = Color("#D95B7A")
		PRIMARY_LIGHT = Color("#F5B7C6")
		ACCENT = Color("#8ECAE6")
		BG_WARM = Color("#FFF8E7")
		BG_WHITE = Color("#FFFFFF")
		TEXT_DARK = Color("#5C4B51")
		TEXT_MID = Color("#8A7A80")
		TEXT_LIGHT = Color.WHITE
		SHADOW = Color(0.0, 0.0, 0.0, 0.1)
		
		string_normal = Color("#F573A0")
		string_tense = Color("#FFA6C9")
		string_target = Color(0.96, 0.45, 0.65, 1.0)
		finger_main = Color("#FFB6C1")
		finger_shadow = Color(0, 0, 0, 0.1)
		board_bg = Color("#E6D8CE")
		board_base = Color("#D4E6CE")
		board_line = Color("#B5CCAD")

# ===== 角丸 =====
const RADIUS_SM = 8
const RADIUS_MD = 16
const RADIUS_LG = 24
const RADIUS_XL = 32
const RADIUS_PILL = 100  # カプセル型

# ===== 余白 =====
const SPACING_XS = 8
const SPACING_SM = 12
const SPACING_MD = 20
const SPACING_LG = 32
const SPACING_XL = 48

# ===== フォントサイズ =====
const FONT_TITLE = 80
const FONT_HEADING = 48
const FONT_SUBHEADING = 36
const FONT_BODY = 24
const FONT_BUTTON_PRIMARY = 48
const FONT_BUTTON_SECONDARY = 32
const FONT_BUTTON_SMALL = 20
const FONT_CAPTION = 18

# ===== タップターゲット最小サイズ =====
const MIN_TAP_SIZE = Vector2(48, 48)

# ===== ボタンスタイル生成ヘルパー =====
# ===== ボタンスタイル生成ヘルパー (商業用スマホアプリ級3Dカプセル・グロス調) =====
func create_button_style(bg_col: Color, shadow_y: float = 6.0, radius: int = RADIUS_PILL) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_col
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	
	# リッチなハイライト＆3D底面ボトムエッジ
	style.border_width_top = 3
	style.border_width_bottom = int(max(4.0, shadow_y))
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = bg_col.lightened(0.35)
	style.border_color.a = 0.85 # 上面＆側面の光沢
	
	# 下部の厚み表現（立体感）
	if shadow_y > 0:
		style.shadow_color = Color(0.05, 0.04, 0.06, 0.12)
		style.shadow_size = 8
		style.shadow_offset = Vector2(0, 4)
		
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	style.content_margin_left = 32
	style.content_margin_right = 32
	return style

func create_pressed_style(bg_col: Color, radius: int = RADIUS_PILL) -> StyleBoxFlat:
	var style = create_button_style(bg_col, 0, radius)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = bg_col.darkened(0.15)
	style.shadow_color = Color(0.05, 0.04, 0.06, 0.08)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 1)
	style.content_margin_top += 4
	style.content_margin_bottom -= 4
	return style

func create_panel_style(bg_col: Color = BG_WHITE, radius: int = RADIUS_LG, shadow_size: int = 8) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_col
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(1, 1, 1, 0.65) if bg_col.get_luminance() > 0.5 else Color(1, 1, 1, 0.12)
	style.shadow_color = Color(0.06, 0.04, 0.07, 0.08)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = SPACING_MD
	style.content_margin_right = SPACING_MD
	style.content_margin_top = SPACING_MD
	style.content_margin_bottom = SPACING_MD
	return style

func create_mobile_card_style(bg_col: Color = BG_WHITE, radius: int = RADIUS_XL) -> StyleBoxFlat:
	var style = create_panel_style(bg_col, radius, 12)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	return style

func create_pill_tab_style(is_selected: bool, accent_color: Color = PRIMARY) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = RADIUS_PILL
	style.corner_radius_top_right = RADIUS_PILL
	style.corner_radius_bottom_left = RADIUS_PILL
	style.corner_radius_bottom_right = RADIUS_PILL
	if is_selected:
		style.bg_color = accent_color
		style.border_width_top = 2
		style.border_width_bottom = 4
		style.border_color = accent_color.lightened(0.3)
		style.shadow_color = Color(0, 0, 0, 0.1)
		style.shadow_size = 4
		style.shadow_offset = Vector2(0, 2)
	else:
		style.bg_color = BG_WHITE.blend(Color(1, 1, 1, 0.8))
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_color = PRIMARY_LIGHT
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func create_settings_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = BG_WHITE if PRIMARY != Color("#F2849E") else Color("#FFFDF9")
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_color = PRIMARY_LIGHT # 優しい枠線
	style.corner_radius_top_left = RADIUS_LG
	style.corner_radius_top_right = RADIUS_LG
	style.corner_radius_bottom_left = RADIUS_LG
	style.corner_radius_bottom_right = RADIUS_LG
	style.shadow_color = Color(0.05, 0.04, 0.07, 0.1)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = SPACING_MD
	style.content_margin_right = SPACING_MD
	style.content_margin_top = SPACING_MD
	style.content_margin_bottom = SPACING_MD
	return style

func apply_button_theme(btn: Button, normal: StyleBoxFlat, pressed: StyleBoxFlat = null) -> void:
	if pressed == null and normal != null:
		pressed = create_pressed_style(normal.bg_color, normal.corner_radius_top_left)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", normal)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", TEXT_LIGHT)
	btn.add_theme_color_override("font_hover_color", TEXT_LIGHT)
	btn.add_theme_constant_override("outline_size", 6)
	btn.add_theme_color_override("font_outline_color", Color(PRIMARY_DARK.r, PRIMARY_DARK.g, PRIMARY_DARK.b, 0.5))

func apply_icon_button_theme(btn: Button, normal: StyleBoxFlat, pressed: StyleBoxFlat = null) -> void:
	apply_button_theme(btn, normal, pressed)
	btn.add_theme_color_override("icon_normal_color", TEXT_LIGHT)
	btn.add_theme_color_override("icon_hover_color", TEXT_LIGHT)
	btn.add_theme_color_override("icon_pressed_color", TEXT_LIGHT)

func setup_button_animations(btn: Button) -> void:
	if not btn or btn.has_meta("anim_setup"):
		return
	btn.set_meta("anim_setup", true)
	btn.pivot_offset = btn.size / 2.0
	btn.resized.connect(func(): if is_instance_valid(btn): btn.pivot_offset = btn.size / 2.0)
	btn.mouse_entered.connect(func(): _animate_btn(btn, Vector2(1.05, 1.05)))
	btn.mouse_exited.connect(func(): _animate_btn(btn, Vector2(1.0, 1.0)))
	btn.button_down.connect(func(): _animate_btn(btn, Vector2(0.93, 0.93), 0.12))
	btn.button_up.connect(func():
		if is_instance_valid(btn) and btn.get_global_rect().has_point(btn.get_global_mouse_position()):
			_animate_btn(btn, Vector2(1.05, 1.05), 0.28)
		elif is_instance_valid(btn):
			_animate_btn(btn, Vector2(1.0, 1.0), 0.28)
	)

func _animate_btn(btn: Button, target_scale: Vector2, duration: float = 0.3) -> void:
	if not is_instance_valid(btn):
		return
	var tween = btn.create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", target_scale, duration)

func apply_line_edit_theme(line_edit: LineEdit) -> void:
	if not line_edit:
		return
	line_edit.add_theme_font_size_override("font_size", FONT_BODY)
	line_edit.add_theme_color_override("font_color", TEXT_DARK)
	line_edit.add_theme_color_override("font_placeholder_color", Color(TEXT_MID.r, TEXT_MID.g, TEXT_MID.b, 0.7))
	line_edit.add_theme_color_override("caret_color", PRIMARY)
	line_edit.virtual_keyboard_enabled = true
	line_edit.clear_button_enabled = true
	line_edit.caret_blink = true
	line_edit.select_all_on_focus = false # スマホ操作で全選択され誤削除されるのを防ぐ
	line_edit.focus_mode = Control.FOCUS_ALL
	line_edit.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = BG_WHITE
	normal_style.corner_radius_top_left = RADIUS_LG
	normal_style.corner_radius_top_right = RADIUS_LG
	normal_style.corner_radius_bottom_left = RADIUS_LG
	normal_style.corner_radius_bottom_right = RADIUS_LG
	normal_style.border_width_left = 3
	normal_style.border_width_right = 3
	normal_style.border_width_top = 3
	normal_style.border_width_bottom = 3
	normal_style.border_color = PRIMARY_LIGHT
	normal_style.content_margin_left = 20
	normal_style.content_margin_right = 20
	normal_style.content_margin_top = 14
	normal_style.content_margin_bottom = 14
	
	var focus_style = normal_style.duplicate()
	focus_style.border_color = PRIMARY
	focus_style.border_width_left = 4
	focus_style.border_width_right = 4
	focus_style.border_width_top = 4
	focus_style.border_width_bottom = 4
	
	var read_only_style = normal_style.duplicate()
	read_only_style.bg_color = BG_WARM
	read_only_style.border_color = TEXT_MID
	
	line_edit.add_theme_stylebox_override("normal", normal_style)
	line_edit.add_theme_stylebox_override("focus", focus_style)
	line_edit.add_theme_stylebox_override("read_only", read_only_style)
	
	enable_mobile_text_input(line_edit, line_edit.placeholder_text if line_edit.placeholder_text != "" else "文字を入力")

func is_mobile_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")

func enable_mobile_text_input(line_edit: LineEdit, prompt_title: String = "テキストを入力") -> void:
	if not line_edit or line_edit.has_meta("mobile_input_setup"):
		return
	line_edit.set_meta("mobile_input_setup", true)
	line_edit.focus_mode = Control.FOCUS_ALL
	line_edit.virtual_keyboard_enabled = true
	line_edit.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# スマホ・タッチ操作時およびWeb HTML5エクスポート時にキーボードや入力プロンプトを確実に表示する
	line_edit.gui_input.connect(func(event: InputEvent):
		if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			if not is_mobile_device():
				return
			line_edit.grab_focus()
			if DisplayServer.has_method("virtual_keyboard_show"):
				DisplayServer.virtual_keyboard_show(line_edit.text)
			
			# Webブラウザ（スマホSafari・Chrome等）のCanvasでソフトキーボードがブロックされた場合の救済プロンプト
			if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
				var current_t = line_edit.text.replace("'", "\\'").replace('"', '\\"')
				var js_code = "window.prompt('" + prompt_title + "', '" + current_t + "')"
				var res = JavaScriptBridge.eval(js_code)
				if res != null and str(res) != "null":
					line_edit.text = str(res)
					line_edit.text_changed.emit(str(res))
					line_edit.text_submitted.emit(str(res))
	)

func apply_option_button_theme(btn: OptionButton, normal: StyleBoxFlat = null, pressed: StyleBoxFlat = null) -> void:
	if not btn:
		return
	if not normal:
		normal = create_button_style(PRIMARY_LIGHT, 4, RADIUS_LG)
		normal.content_margin_left = 16
		normal.content_margin_right = 16
		normal.content_margin_top = 8
		normal.content_margin_bottom = 8
	if not pressed:
		pressed = create_pressed_style(PRIMARY_LIGHT, RADIUS_LG)
		pressed.content_margin_left = 16
		pressed.content_margin_right = 16
		pressed.content_margin_top += 4
		pressed.content_margin_bottom -= 4
	
	apply_button_theme(btn, normal, pressed)
	btn.add_theme_font_size_override("font_size", FONT_BODY)
	btn.add_theme_color_override("icon_normal_color", TEXT_LIGHT)
	btn.add_theme_color_override("icon_hover_color", TEXT_LIGHT)
	btn.add_theme_color_override("icon_pressed_color", TEXT_LIGHT)
	
	if btn.has_method("get_popup") and btn.get_popup():
		apply_popup_menu_theme(btn.get_popup())

func apply_popup_menu_theme(popup: PopupMenu) -> void:
	if not popup:
		return
	popup.add_theme_font_size_override("font_size", FONT_BODY)
	popup.add_theme_color_override("font_color", TEXT_DARK)
	popup.add_theme_color_override("font_hover_color", TEXT_LIGHT)
	popup.add_theme_color_override("font_selected_color", TEXT_LIGHT)
	popup.add_theme_color_override("font_separator_color", TEXT_MID)
	popup.add_theme_color_override("font_disabled_color", TEXT_MID)
	
	var panel_style = create_panel_style(BG_WHITE, RADIUS_MD, 10)
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = PRIMARY_LIGHT
	panel_style.content_margin_left = SPACING_SM
	panel_style.content_margin_right = SPACING_SM
	panel_style.content_margin_top = SPACING_SM
	panel_style.content_margin_bottom = SPACING_SM
	popup.add_theme_stylebox_override("panel", panel_style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = PRIMARY
	hover_style.corner_radius_top_left = RADIUS_SM
	hover_style.corner_radius_top_right = RADIUS_SM
	hover_style.corner_radius_bottom_left = RADIUS_SM
	hover_style.corner_radius_bottom_right = RADIUS_SM
	hover_style.content_margin_left = SPACING_SM
	hover_style.content_margin_right = SPACING_SM
	hover_style.content_margin_top = 8
	hover_style.content_margin_bottom = 8
	popup.add_theme_stylebox_override("hover", hover_style)
	popup.add_theme_stylebox_override("item_hover", hover_style)
	
	popup.add_theme_constant_override("v_separation", 10)
	popup.add_theme_constant_override("h_separation", 12)

func apply_slider_theme(slider: Slider) -> void:
	if not slider:
		return
	var groove = StyleBoxFlat.new()
	groove.bg_color = Color(PRIMARY_LIGHT.r, PRIMARY_LIGHT.g, PRIMARY_LIGHT.b, 0.4)
	groove.corner_radius_top_left = RADIUS_PILL
	groove.corner_radius_top_right = RADIUS_PILL
	groove.corner_radius_bottom_left = RADIUS_PILL
	groove.corner_radius_bottom_right = RADIUS_PILL
	groove.content_margin_top = 6
	groove.content_margin_bottom = 6
	slider.add_theme_stylebox_override("slider", groove)
	
	var grabber_area = StyleBoxFlat.new()
	grabber_area.bg_color = PRIMARY
	grabber_area.corner_radius_top_left = RADIUS_PILL
	grabber_area.corner_radius_top_right = RADIUS_PILL
	grabber_area.corner_radius_bottom_left = RADIUS_PILL
	grabber_area.corner_radius_bottom_right = RADIUS_PILL
	grabber_area.content_margin_top = 6
	grabber_area.content_margin_bottom = 6
	slider.add_theme_stylebox_override("grabber_area", grabber_area)
	slider.add_theme_stylebox_override("grabber_area_highlight", grabber_area)

func apply_dialog_theme(dialog: AcceptDialog) -> void:
	if not dialog:
		return
	dialog.transparent = true
	dialog.add_theme_font_size_override("title_font_size", FONT_BODY)
	dialog.add_theme_color_override("title_color", TEXT_LIGHT)
	
	if dialog.has_method("get_label") and dialog.get_label():
		dialog.get_label().add_theme_color_override("font_color", TEXT_DARK)

	
	# ウィンドウ（タイトルバーと外枠）のスタイル
	var embed_style = StyleBoxFlat.new()
	embed_style.bg_color = PRIMARY
	embed_style.corner_radius_top_left = RADIUS_LG
	embed_style.corner_radius_top_right = RADIUS_LG
	embed_style.corner_radius_bottom_left = RADIUS_LG
	embed_style.corner_radius_bottom_right = RADIUS_LG
	embed_style.expand_margin_top = 36 # タイトルバーの高さ
	embed_style.content_margin_left = 4
	embed_style.content_margin_right = 4
	embed_style.content_margin_top = 4
	embed_style.content_margin_bottom = 4
	embed_style.border_width_left = 4
	embed_style.border_width_right = 4
	embed_style.border_width_bottom = 4
	embed_style.border_width_top = 4
	embed_style.border_color = PRIMARY_LIGHT
	embed_style.shadow_color = SHADOW
	embed_style.shadow_size = 12
	
	dialog.add_theme_stylebox_override("embedded_border", embed_style)
	dialog.add_theme_stylebox_override("embedded_unfocused_border", embed_style)
	
	# パネル本体のスタイル
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = BG_WHITE
	panel_style.corner_radius_top_left = 0
	panel_style.corner_radius_top_right = 0
	panel_style.corner_radius_bottom_left = RADIUS_LG
	panel_style.corner_radius_bottom_right = RADIUS_LG
	panel_style.content_margin_left = SPACING_MD
	panel_style.content_margin_right = SPACING_MD
	panel_style.content_margin_top = SPACING_MD
	panel_style.content_margin_bottom = SPACING_MD
	dialog.add_theme_stylebox_override("panel", panel_style)
	
	# ダイアログ内のラベル色
	for child in dialog.get_children():
		if child is Label:
			child.add_theme_color_override("font_color", TEXT_DARK)
		elif child is CheckBox or child is CheckButton:
			child.add_theme_color_override("font_color", TEXT_DARK)
			child.add_theme_color_override("font_pressed_color", TEXT_DARK)
			child.add_theme_color_override("font_hover_color", TEXT_DARK)
			child.add_theme_color_override("font_hover_pressed_color", TEXT_DARK)
			child.add_theme_color_override("font_focus_color", TEXT_DARK)
			
		for gc in child.get_children():
			if gc is Label:
				gc.add_theme_color_override("font_color", TEXT_DARK)
			elif gc is CheckBox or gc is CheckButton:
				gc.add_theme_color_override("font_color", TEXT_DARK)
				gc.add_theme_color_override("font_pressed_color", TEXT_DARK)
				gc.add_theme_color_override("font_hover_color", TEXT_DARK)
				gc.add_theme_color_override("font_hover_pressed_color", TEXT_DARK)
				gc.add_theme_color_override("font_focus_color", TEXT_DARK)
	
	# OKボタン
	var ok_btn = dialog.get_ok_button()
	if ok_btn:
		ok_btn.text = "OK"
		var btn_n = create_button_style(PRIMARY, 4, RADIUS_LG)
		var btn_p = create_pressed_style(PRIMARY, RADIUS_LG)
		apply_button_theme(ok_btn, btn_n, btn_p)
		setup_button_animations(ok_btn)
	
	# キャンセルボタン
	if dialog is ConfirmationDialog:
		var cancel_btn = dialog.get_cancel_button()
		if cancel_btn:
			cancel_btn.text = "キャンセル"
			var sec_n = create_button_style(PRIMARY_LIGHT, 4, RADIUS_LG)
			var sec_p = create_pressed_style(PRIMARY_LIGHT, RADIUS_LG)
			apply_button_theme(cancel_btn, sec_n, sec_p)
			setup_button_animations(cancel_btn)

func popup_responsive_dialog(dialog: AcceptDialog, default_width: float = 450.0, default_height: float = 220.0) -> void:
	if not dialog or not dialog.is_inside_tree():
		return
	var screen_size = dialog.get_viewport().get_visible_rect().size
	if dialog.get_tree() and dialog.get_tree().root:
		screen_size = dialog.get_tree().root.get_visible_rect().size
	var target_w = min(default_width, max(280.0, screen_size.x - 40.0))
	var target_h = min(default_height, max(180.0, screen_size.y - 40.0))
	for child in dialog.get_children():
		if child is Control:
			child.custom_minimum_size = Vector2(min(child.custom_minimum_size.x, target_w - 40.0), child.custom_minimum_size.y)
	dialog.popup_centered(Vector2(target_w, target_h))

func create_icon_label(icon_path: String, text_str: String, font_size: int = FONT_BODY, icon_size: int = 24, font_color: Color = TEXT_DARK) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	hbox.add_theme_constant_override("separation", SPACING_SM)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var tex_rect = TextureRect.new()
	var tex = load(icon_path)
	if tex:
		tex_rect.texture = tex
	tex_rect.custom_minimum_size = Vector2(icon_size, icon_size)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.modulate = font_color
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(tex_rect)
	
	var label = Label.new()
	label.text = text_str
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 0) # 太い茶色アウトラインを解除
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(label)
	
	return hbox

# テーマ選択UI（3ボタン式）作成ヘルパー
func create_theme_select_buttons(current_theme_idx: int, on_selected: Callable) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", SPACING_SM)
	
	var themes = ["通常", "モノクロ", "ダーク"]
	var buttons: Array[Button] = []
	
	for i in range(themes.size()):
		var btn = Button.new()
		btn.text = themes[i]
		btn.custom_minimum_size = Vector2(80, 36)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.add_theme_font_size_override("font_size", FONT_CAPTION)
		btn.add_theme_constant_override("outline_size", 0)
		
		btn.pressed.connect(func():
			on_selected.call(i)
			for j in range(buttons.size()):
				_update_theme_button_style(buttons[j], j == i)
		)
		
		buttons.append(btn)
		hbox.add_child(btn)
		_update_theme_button_style(btn, i == current_theme_idx)
		setup_button_animations(btn)
		
	return hbox

func _update_theme_button_style(btn: Button, is_selected: bool) -> void:
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = RADIUS_MD
	style.corner_radius_top_right = RADIUS_MD
	style.corner_radius_bottom_left = RADIUS_MD
	style.corner_radius_bottom_right = RADIUS_MD
	# マージンとボーダーの太さを選択/非選択で同一に固定してサイズズレを完全防止！
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.shadow_size = 0
	style.shadow_offset = Vector2(0, 2)
	
	if is_selected:
		style.bg_color = PRIMARY
		style.border_color = PRIMARY # ボーダー色を背景と同じにする
		style.shadow_color = Color(PRIMARY_DARK.r, PRIMARY_DARK.g, PRIMARY_DARK.b, 0.3)
		
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.add_theme_color_override("font_color", TEXT_LIGHT)
		btn.add_theme_color_override("font_hover_color", TEXT_LIGHT)
		btn.add_theme_color_override("font_pressed_color", TEXT_LIGHT)
		btn.add_theme_constant_override("outline_size", 2)
		btn.add_theme_color_override("font_outline_color", PRIMARY_DARK)
	else:
		style.bg_color = BG_WHITE
		style.border_color = PRIMARY_LIGHT
		style.shadow_color = Color(0, 0, 0, 0.05)
		
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.add_theme_color_override("font_color", TEXT_DARK)
		btn.add_theme_color_override("font_hover_color", PRIMARY)
		btn.add_theme_color_override("font_pressed_color", PRIMARY)
		btn.add_theme_constant_override("outline_size", 0)

func update_theme_select_buttons(hbox: HBoxContainer, current_theme_idx: int) -> void:
	for i in range(hbox.get_child_count()):
		var btn = hbox.get_child(i) as Button
		if btn:
			_update_theme_button_style(btn, i == current_theme_idx)

func update_settings_panel_colors(panel: PanelContainer, current_theme_idx: int) -> void:
	if not panel:
		return
	panel.add_theme_stylebox_override("panel", create_settings_panel_style())
	_update_node_colors_recursive(panel, current_theme_idx)

func _update_node_colors_recursive(node: Node, current_theme_idx: int) -> void:
	if node is Label:
		node.add_theme_color_override("font_color", TEXT_DARK)
	elif node is TextureRect and node.get_parent() is HBoxContainer:
		node.modulate = TEXT_DARK
	elif node is CheckButton:
		node.add_theme_color_override("font_color", TEXT_DARK)
	elif node is LineEdit:
		apply_line_edit_theme(node)
	elif node is OptionButton:
		apply_option_button_theme(node)
	elif node is PopupMenu:
		apply_popup_menu_theme(node)
	elif node is Slider:
		apply_slider_theme(node)
	elif node is AcceptDialog:
		apply_dialog_theme(node)
	elif node is Button and node.text.begins_with(" 今日のお題"):
		var daily_normal = create_button_style(ACCENT, 4)
		daily_normal.content_margin_left = 16
		daily_normal.content_margin_right = 16
		daily_normal.content_margin_top = 8
		daily_normal.content_margin_bottom = 8
		var daily_pressed = daily_normal.duplicate()
		daily_pressed.content_margin_top += 4
		daily_pressed.content_margin_bottom -= 4
		apply_button_theme(node, daily_normal, daily_pressed)
		node.add_theme_color_override("font_outline_color", Color(ACCENT.darkened(0.4), 0.8))
	elif node is Button and node.text.begins_with(" ショップを開く"):
		var shop_style_norm = create_button_style(PRIMARY, 4, RADIUS_MD)
		shop_style_norm.content_margin_top = 8
		shop_style_norm.content_margin_bottom = 8
		var shop_style_press = create_pressed_style(PRIMARY, RADIUS_MD)
		shop_style_press.content_margin_top = 8
		shop_style_press.content_margin_bottom = 8
		apply_button_theme(node, shop_style_norm, shop_style_press)
	elif node is HBoxContainer and node.get_child_count() == 3 and node.get_child(0) is Button and (node.get_child(0) as Button).text == "通常":
		update_theme_select_buttons(node, current_theme_idx)
		return
		
	for child in node.get_children():
		_update_node_colors_recursive(child, current_theme_idx)
