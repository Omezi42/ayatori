extends Node2D

# 高品質でモダンな「指（ハンドポインター）のアイコン」をプロシージャル描画
# 滑らかなベジェ曲線による立体的なハンド形状、グラデーションシェーディング、
# ドロップシャドウ、そしてドラッグ＆タップ時のダイナミックなリップルエフェクトを提供します。

var _pulse_phase: float = 0.0
var _ripple_radius: float = 0.0
var _ripple_alpha: float = 0.0
var _was_pressed: bool = false
var _hand_polygon: PackedVector2Array
var _thumb_crease_polyline: PackedVector2Array
var _middle_crease_polyline: PackedVector2Array
var _ring_crease_polyline: PackedVector2Array
var _pinky_crease_polyline: PackedVector2Array
var _cuff_polyline: PackedVector2Array
var _nail_polygon: PackedVector2Array
var _nail_shine_polyline: PackedVector2Array

func _ready() -> void:
	_generate_hand_geometry()

func _process(delta: float) -> void:
	_pulse_phase += delta * 4.0
	
	# スケールの変化からタップや掴み動作を検知してリップルを開始
	var is_pressed = scale.x < 0.9
	if is_pressed and not _was_pressed:
		_ripple_radius = 12.0
		_ripple_alpha = 0.85
	_was_pressed = is_pressed
	
	if _ripple_alpha > 0:
		_ripple_radius += delta * 80.0
		_ripple_alpha = max(0.0, _ripple_alpha - delta * 2.2)
		
	queue_redraw()

func _generate_hand_geometry() -> void:
	var curve = Curve2D.new()
	
	# 人差し指の指先（タッチ対象の中心 Vector2(0, 0) 付近に向ける）
	# 指先の中心は (0, -10)、左端 (-9, -10)、右端 (9, -10) の滑らかな半円をベジェ曲線で表現
	curve.add_point(Vector2(0, -12), Vector2(-6, 0), Vector2(6, 0))
	
	# 人差し指の右側面（少し右下に伸びる）
	curve.add_point(Vector2(9, 10), Vector2(0, -10), Vector2(0, 4))
	
	# 中指の第一関節・折り曲げ部の膨らみ
	curve.add_point(Vector2(21, 16), Vector2(-3, -5), Vector2(2, 5))
	
	# 薬指の折り曲げ部の膨らみ
	curve.add_point(Vector2(23, 30), Vector2(-2, -4), Vector2(1, 4))
	
	# 小指の折り曲げ部の膨らみ
	curve.add_point(Vector2(21, 44), Vector2(1, -4), Vector2(-2, 5))
	
	# 手のひら右下・手首へのつながり
	curve.add_point(Vector2(15, 58), Vector2(3, -6), Vector2(0, 4))
	
	# 手首の底面（丸みを帯びた下端）
	curve.add_point(Vector2(0, 64), Vector2(8, 0), Vector2(-8, 0))
	
	# 手首の左側面
	curve.add_point(Vector2(-16, 56), Vector2(0, 4), Vector2(-2, -6))
	
	# 手のひら左下（親指の付け根のふくらみ）
	curve.add_point(Vector2(-24, 38), Vector2(-2, 6), Vector2(2, -6))
	
	# 折り曲げた親指の先端（右上にカーブして人差し指側へ向かう）
	curve.add_point(Vector2(-20, 18), Vector2(-5, 5), Vector2(5, -5))
	
	# 親指と人差し指の谷間（水かき部分の美しいカーブ）
	curve.add_point(Vector2(-10, 12), Vector2(-4, 3), Vector2(2, -6))
	
	# 人差し指の左側面（指先へと戻る）
	curve.add_point(Vector2(-9, -2), Vector2(0, 6), Vector2(0, -5))
	
	# 高精度で分割（滑らかな曲線に変換）
	_hand_polygon = curve.tessellate(6, 1.5)
	
	# ===== 内側のシワ・関節ライン（立体感とクオリティを高めるディテール） =====
	
	# 親指の折り曲げライン（水かき部から手のひら中央へ流れるカーブ）
	var thumb_curve = Curve2D.new()
	thumb_curve.add_point(Vector2(-10, 12), Vector2(0, 0), Vector2(3, 3))
	thumb_curve.add_point(Vector2(-5, 23), Vector2(-2, -4), Vector2(2, 4))
	thumb_curve.add_point(Vector2(-2, 33), Vector2(-1, -4), Vector2(0, 0))
	_thumb_crease_polyline = thumb_curve.tessellate(5, 2.0)
	
	# 中指と人差し指・手のひらの境界ライン
	var mid_curve = Curve2D.new()
	mid_curve.add_point(Vector2(9, 10), Vector2(0, 0), Vector2(-3, 3))
	mid_curve.add_point(Vector2(2, 19), Vector2(3, -3), Vector2(0, 0))
	_middle_crease_polyline = mid_curve.tessellate(5, 2.0)
	
	# 薬指の境界ライン
	var ring_curve = Curve2D.new()
	ring_curve.add_point(Vector2(21, 24), Vector2(0, 0), Vector2(-4, 1))
	ring_curve.add_point(Vector2(8, 26), Vector2(4, -1), Vector2(0, 0))
	_ring_crease_polyline = ring_curve.tessellate(5, 2.0)
	
	# 小指の境界ライン
	var pinky_curve = Curve2D.new()
	pinky_curve.add_point(Vector2(22, 38), Vector2(0, 0), Vector2(-4, 0))
	pinky_curve.add_point(Vector2(10, 39), Vector2(4, 0), Vector2(0, 0))
	_pinky_crease_polyline = pinky_curve.tessellate(5, 2.0)
	
	# 手首のカフ（袖口／バンド）ライン
	var cuff_curve = Curve2D.new()
	cuff_curve.add_point(Vector2(-15, 54), Vector2(0, 0), Vector2(5, 2))
	cuff_curve.add_point(Vector2(0, 57), Vector2(-5, 0), Vector2(5, 0))
	cuff_curve.add_point(Vector2(15, 54), Vector2(-5, 2), Vector2(0, 0))
	_cuff_polyline = cuff_curve.tessellate(5, 2.0)
	
	# 人差し指の爪（モダンで可愛いツヤのある楕円爪）
	_nail_polygon = _get_oval_polygon(Vector2(0, -3), 5.0, 6.5, 20)
	
	# 爪のハイライト（左上の光沢ライン）
	var shine_curve = Curve2D.new()
	shine_curve.add_point(Vector2(-2.5, -7), Vector2(0, 0), Vector2(-0.5, 2))
	shine_curve.add_point(Vector2(-2.5, -2), Vector2(-0.5, -2), Vector2(0, 0))
	_nail_shine_polyline = shine_curve.tessellate(5, 2.0)

func _get_oval_polygon(center: Vector2, rx: float, ry: float, points: int = 24) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in range(points):
		var angle = (float(i) / points) * TAU
		pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	return pts

func _draw() -> void:
	if _hand_polygon.is_empty():
		_generate_hand_geometry()
		
	# 1. 押下状態（スケール変化）に応じたパラメータ計算
	# 掴む/タップする動作のときに scale が 0.8 や 0.7 になるのを検知
	var press_ratio = clamp((1.0 - scale.x) / 0.25, 0.0, 1.0)
	
	# 2. ターゲットインジケーター（タッチポイントのパルスリング）
	_draw_target_indicators(press_ratio)
	
	# 3. ドロップシャドウ（押下時に影が近づき濃くなる立体表現）
	_draw_drop_shadows(press_ratio)
	
	# 4. ハンド本体のグラデーション描画
	_draw_hand_body()
	
	# 5. 内側のディテール（関節シワ、手首カフ、爪）
	_draw_hand_details()
	
	# 6. 外枠のアウトライン（アンチエイリアス対応の美しい輪郭）
	_draw_hand_outline()

func _draw_target_indicators(press_ratio: float) -> void:
	# 外側のパルスリング（優しく拡縮してタッチ対象を示す）
	var pulse_r1 = 34.0 + sin(_pulse_phase) * 6.0
	var pulse_a1 = 0.35 + sin(_pulse_phase) * 0.15
	draw_arc(Vector2.ZERO, pulse_r1, 0, TAU, 48, Color(ThemeConfig.PRIMARY.r, ThemeConfig.PRIMARY.g, ThemeConfig.PRIMARY.b, pulse_a1), 2.5, true)
	
	# 内側のゴールド・カウンターパルスリング
	var pulse_r2 = 24.0 - sin(_pulse_phase) * 4.0
	var pulse_a2 = 0.25 - sin(_pulse_phase) * 0.1
	draw_arc(Vector2.ZERO, pulse_r2, 0, TAU, 48, Color(ThemeConfig.STAR_GOLD.r, ThemeConfig.STAR_GOLD.g, ThemeConfig.STAR_GOLD.b, pulse_a2), 2.0, true)
	
	# タッチポイントの中心グローとスポット
	draw_circle(Vector2.ZERO, 14.0, Color(ThemeConfig.PRIMARY.r, ThemeConfig.PRIMARY.g, ThemeConfig.PRIMARY.b, 0.2 + press_ratio * 0.3))
	draw_circle(Vector2.ZERO, 6.0, Color(ThemeConfig.PRIMARY.r, ThemeConfig.PRIMARY.g, ThemeConfig.PRIMARY.b, 0.7 + press_ratio * 0.3))
	draw_circle(Vector2.ZERO, 2.5, Color.WHITE)
	
	# タップ・掴みアクション時のダイナミックリップルエフェクト
	if _ripple_alpha > 0:
		draw_arc(Vector2.ZERO, _ripple_radius, 0, TAU, 48, Color(ThemeConfig.PRIMARY.r, ThemeConfig.PRIMARY.g, ThemeConfig.PRIMARY.b, _ripple_alpha), 3.5, true)
		draw_arc(Vector2.ZERO, _ripple_radius * 0.7, 0, TAU, 48, Color(ThemeConfig.STAR_GOLD.r, ThemeConfig.STAR_GOLD.g, ThemeConfig.STAR_GOLD.b, _ripple_alpha * 0.7), 2.0, true)

func _draw_drop_shadows(press_ratio: float) -> void:
	# 押下時は画面に近づくため、影の位置が手元に寄り、濃くなる
	var shadow_offset_wide = lerp(Vector2(4, 14), Vector2(2, 6), press_ratio)
	var shadow_offset_tight = lerp(Vector2(2, 6), Vector2(1, 3), press_ratio)
	
	var alpha_wide = lerp(0.08, 0.14, press_ratio)
	var alpha_tight = lerp(0.12, 0.20, press_ratio)
	
	# 柔らかい広範囲の影
	var shadow_pts_wide = PackedVector2Array()
	for p in _hand_polygon:
		shadow_pts_wide.append(p + shadow_offset_wide)
	draw_polygon(shadow_pts_wide, PackedColorArray([Color(0.0, 0.0, 0.0, alpha_wide)]))
	
	# 濃い近接の影
	var shadow_pts_tight = PackedVector2Array()
	for p in _hand_polygon:
		shadow_pts_tight.append(p + shadow_offset_tight)
	draw_polygon(shadow_pts_tight, PackedColorArray([Color(0.0, 0.0, 0.0, alpha_tight)]))

func _draw_hand_body() -> void:
	# 頂点ごとの色指定による3Dボリューム・グラデーションシェーディング
	# 左上（指先・親指側）は明るいクリームホワイト、右下（手首・折り曲げ指側）は暖かみのあるローズシャドウ
	var colors = PackedColorArray()
	var col_top_left = Color("#FFFFFF")     # 純白のハイライト
	var col_bottom_right = Color("#F2E6E4") # 暖色系の微かな影色
	
	for p in _hand_polygon:
		# 位置に基づくグラデーション係数 (y: -12 ~ 64, x: -25 ~ 25)
		var factor = clamp((p.x + p.y + 20.0) / 80.0, 0.0, 1.0)
		colors.append(col_top_left.lerp(col_bottom_right, factor))
		
	draw_polygon(_hand_polygon, colors)

func _draw_hand_details() -> void:
	var crease_color = Color("#8C7A80", 0.5) # 柔らかい暖色の関節ライン
	var cuff_color = Color("#8C7A80", 0.6)
	
	# 関節と折り曲げのシワライン
	draw_polyline(_thumb_crease_polyline, crease_color, 2.2, true)
	draw_polyline(_middle_crease_polyline, crease_color, 2.0, true)
	draw_polyline(_ring_crease_polyline, crease_color, 2.0, true)
	draw_polyline(_pinky_crease_polyline, crease_color, 2.0, true)
	
	# 手首のカフライン
	draw_polyline(_cuff_polyline, cuff_color, 2.5, true)
	
	# 人差し指の爪（ほんのりピンクでツヤのある質感）
	draw_polygon(_nail_polygon, PackedColorArray([Color(1.0, 0.88, 0.92, 0.85)]))
	
	# 爪の輪郭
	var nail_outline = _nail_polygon.duplicate()
	nail_outline.append(_nail_polygon[0])
	draw_polyline(nail_outline, Color("#D95B7A", 0.5), 1.5, true)
	
	# 爪のツヤ（ハイライト）
	draw_polyline(_nail_shine_polyline, Color(1.0, 1.0, 1.0, 0.95), 2.0, true)

func _draw_hand_outline() -> void:
	# 輪郭を閉じるために先頭点を最後に追加
	var outline_pts = _hand_polygon.duplicate()
	if outline_pts.size() > 0:
		outline_pts.append(outline_pts[0])
	
	# くっきりとしたアンチエイリアス対応のダークウォーム・アウトライン
	var outline_color = Color("#5C4B51") # ThemeConfig.TEXT_DARK
	draw_polyline(outline_pts, outline_color, 2.8, true)
