shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.96, 0.45, 0.65, 1.0);
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 0.5) = 0.15;

void fragment() {
    // UV.y が線の幅方向 (0.0 ～ 1.0)
    float dist = abs(UV.y - 0.5) * 2.0;
    
    // エッジ部分をアウトラインカラーにする
    if (dist > 1.0 - outline_width * 2.0) {
        COLOR = outline_color;
    } else {
        COLOR = base_color;
    }
}
