extends Node2D
# ================================================
# タイトルシーン.
# ================================================
#@onready var _btn_start := $BtnStart # スタートボタン.

# メインゲーム開始.
func _on_btn_start_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/Main.tscn") # メインゲームシーンに移行.

