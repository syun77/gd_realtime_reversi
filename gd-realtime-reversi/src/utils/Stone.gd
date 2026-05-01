extends Node
# 石（コマンド用ユーティリティ）
class_name Stone

enum eType {
    EMPTY = 0,
    BLACK = 1,
    WHITE = 2
}

static func draw(canvas: Node2D, center: Vector2, radius: float, typ: int) -> void:
    var stone_border := Color(0, 0, 0, 0.6)
    # 外枠で立体感
    canvas.draw_circle(center + Vector2(1, 1), radius, Color(0, 0, 0, 0.12))
    # 石本体
    var fill := Color(0, 0, 0)
    if typ == eType.WHITE:
        fill = Color(1, 1, 1)
    canvas.draw_circle(center, radius, fill)
    # 輪郭
    canvas.draw_circle(center, radius, stone_border, false)
