# 铁矿物体类，负责铁矿从小行星飞向玩家的动画效果
extends Sprite2D

@onready var audio: AudioStreamPlayer = $AudioStreamPlayer  # 音频播放器


func _init() -> void:
	# 初始化时隐藏
	visible = false


func animate_to(target_position: Vector2) -> void:
	# 播放飞向目标位置的动画
	var random_delay := randf() * 0.1  # 随机延迟
	var midpoint := _calculate_mid_point(target_position)  # 计算中点

	var tween = create_tween()
	# 缩放出现动画
	tween.tween_property(
		self, "scale", scale, 0.1
	).from(Vector2.ZERO).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD).set_delay(random_delay)
	# 飞向中点
	tween.tween_property(
		self,
		"global_position",
		midpoint,
		0.4
	).from_current().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC).set_delay(random_delay)
	# 从中点飞向目标
	tween.tween_property(
		self,
		"global_position",
		target_position,
		0.6
	).from(midpoint).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(random_delay)
	scale = Vector2.ZERO
	visible = true
	# 缩放消失动画
	tween.tween_property(
		self,
		"scale",
		Vector2.ZERO,
		0.25
	).from_current().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	audio.play()  # 播放音效
	await tween.finished
	queue_free()  # 动画完成后销毁


func _calculate_mid_point(target_position: Vector2) -> Vector2:
	# 计算飞行轨迹的中点，添加一些弧形效果
	var to_target := target_position - global_position
	var midpoint := global_position.lerp(target_position, 0.4)
	var direction_offset := to_target.normalized().rotated(PI / 2)  # 垂直于飞行方向
	var _offset := direction_offset * (randf_range(-1.0, 1.0) * 60.0 + 10.0)  # 随机偏移
	return midpoint + _offset
