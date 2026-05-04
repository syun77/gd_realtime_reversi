extends Area2D
# ================================================
# エネルギーボールクラス.
# ================================================
class_name EnergyBall
@onready var RES_LABEL_BLACK := preload("res://assets/fonts/label_black.tres")
@onready var RES_LABEL_WHITE := preload("res://assets/fonts/label_white.tres")
@onready var _shape := $Hit.shape as CircleShape2D # 衝突判定用エリア.
@onready var _label := $Label as Label # ダメージ表示用ラベル.

var _dmg:int = 0 # ダメージ量.
var _radius := 32.0 # 半径.
var _type := Disc.eType.BLACK # エネルギーボールの種類.
var _target_pos := Vector2.ZERO # 目標位置.
var _speed := 200.0 # 移動速度.
# 現在の進行方向
var _angle:float = 0
# 旋回速度
var _rot_speed = 0.05
# ホーミングの対象.
var _target_list:Array[EnergyBall] = []

# セットアップ.
func setup(type: Disc.eType, dmg: int, pos: Vector2, target_pos: Vector2, speed: float) -> void:
	_type = type
	_dmg = dmg
	position = pos
	_target_pos = target_pos
	_speed = speed
	_label.text = str(_dmg)
	if _type == Disc.eType.BLACK:
		_label.label_settings = RES_LABEL_BLACK # 黒石用のフォントを設定.
	elif _type == Disc.eType.WHITE:
		_label.label_settings = RES_LABEL_WHITE # 白石用のフォントを設定.

	_speed -= pow(dmg, 1.5) * 5.0 # ダメージ量に応じて速度を減らす.
	if _speed < 50.0:
		_speed = 50.0 # 最低速度を設定.
	
	var layer := Common.get_layer("energy")
	for child in layer.get_children():
		var e = child as EnergyBall
		if e != null:
			if e.get_type() != _type:
				# 異なる属性のインスタンスがホーミング対象.
				_target_list.append(e)
	if _target_list.size() != 0:
		# ホーミング対象が存在する場合は速度を上げる.
		if _speed < 200.0:
			_speed = 200.0
	
# ダメージ量の取得.
func get_damage() -> int:
	return _dmg

# ダメージ量を減らす.
func reduce_damage(amount: int) -> void:
	_dmg = max(0, _dmg - amount)
	_label.text = str(_dmg)
	if _dmg == 0:
		# ダメージが0になったら消える.
		destroy()

# タイプの取得.
func get_type() -> Disc.eType:
	return _type

# ホーミングターゲットの取得.
func _search_horming_target() -> EnergyBall:
	var closest:EnergyBall = null
	var closest_dist:float = INF
	for e in _target_list:
		if is_instance_valid(e) == false:
			continue # 無効なインスタンスは無視.
		var dist = position.distance_to(e.position)
		if dist < closest_dist:
			# 最も近いホーミング対象を選択.
			closest = e
			closest_dist = dist
	return closest

# 消滅.
func destroy() -> void:
	# 消滅エフェクトを生成.
	Particle.spawn_balls(position, 10, Disc.get_color(_type, 1.0)) # 消滅エフェクトを生成.
	queue_free() # エネルギーボールを削除.

# 相殺処理.
func cancel_out(e:EnergyBall) -> void:
	# タイプが異なるエネルギーボール同士が衝突したら相殺処理.
	if e.get_type() != get_type():
		var my_dmg = get_damage()
		var other_dmg = e.get_damage()
		if my_dmg > other_dmg:
			# 自分の方がダメージが大きい場合は、相手が消える.
			e.destroy()
			# 自分のダメージを減らす.
			reduce_damage(other_dmg)
		else:
			# 相手の方がダメージが大きい場合は、自分が消える.
			destroy()
			# 相手のダメージを減らす.
			e.reduce_damage(my_dmg)


# 開始.
func _ready() -> void:
	# 衝突判定エリアの形状を円形に設定.
	_radius = _shape.radius

# 更新.
func _process(delta: float) -> void:
	_update_horming(delta)
	# 半径の更新.
	_update_radius()
	queue_redraw() # 描画更新.

# ホーミングの更新.
func _update_horming(delta: float) -> void:
	# ターゲット選択.
	var aim = _target_pos
	var target = _search_horming_target()
	if target != null:
		# ターゲット変更.
		aim = target.position

	# 回転方向を決める.
	var dir = (aim - position)
	var length = dir.length()
	if length < _radius:
		# 一定距離に近づいたらダメージを与えて消える.
		Common.damage(_type, _dmg)
		destroy()
		return
	
	var rad = atan2(-dir.y, dir.x)
	var deg = rad_to_deg(rad)
	var d = _diff_angle(_angle, deg)

	# 旋回実行.
	_angle += d * _rot_speed
	# 旋回速度を上げる.
	_rot_speed = lerp(_rot_speed, 1.0, delta * 0.05)
	
	var next = position
	next.x += cos(deg_to_rad(_angle)) * _speed * delta
	next.y -= sin(deg_to_rad(_angle)) * _speed * delta
	position = next

# ダメージ量でサイズを変える
func _update_radius() -> void:
	_radius = 8.0 + pow(_dmg, 1.2) * 0.5
	_shape.radius = _radius

# 角度差を求める
func _diff_angle(now:float, next:float) -> float:
	# 差を求める
	var d = next - now
	# 0〜360に丸める
	d -= floor(d / 360.0) * 360.0
	# -180〜180にする.
	if d > 180:
		d -= 360
	return d


# 描画.
func _draw() -> void:
	# アウトラインの描画.
	var outline_size_add = randf_range(4, 8) # アウトラインのサイズをランダムに変化させる.
	var alpha = 0.8 # 透明度.
	draw_circle(Vector2.ZERO, _radius + outline_size_add, Disc.get_outline_color(_type, alpha))
	draw_circle(Vector2.ZERO, _radius, Disc.get_color(_type, 0.5))

# 衝突.
func _on_area_entered(area: Area2D) -> void:
	if is_queued_for_deletion():
		return # すでに消滅処理中の場合は無視.
	
	if area is EnergyBall:
		var ball = area as EnergyBall
		if ball.is_queued_for_deletion():
			return # すでに消滅処理中の場合は無視.

		if ball._type != _type:
			# タイプが異なるエネルギーボール同士が衝突したら、相殺処理を行う.
			cancel_out(ball)
