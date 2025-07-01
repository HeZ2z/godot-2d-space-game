# 屏幕淡入淡出效果 - 避免菜单和游戏间的突兀切换
# Animates a black screen that covers the entire screen - keeps transitions
# from simply going menu-game or game-menu in an abrupt and jarring way.
extends TextureRect

signal animation_finished  # 动画完成信号

@export var duration_fade_in := 0.5  # 淡入持续时间
@export var duration_fade_out := 2.5  # 淡出持续时间

var is_playing := false  # 是否正在播放动画

var tween : Tween  # 补间动画


# 从当前调制颜色淡入到完全透明
# Animate from the current modulate color until the node is fully transparent.
func fade_in() -> void:
	tween = create_tween()
	tween.finished.connect(_on_Tween_tween_completed)
	tween.tween_property(
		self,
		"modulate",
		Color.TRANSPARENT,
		duration_fade_in
	).from_current().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
	show()
	tween.play()
	is_playing = true


# 从当前调制颜色淡出到完全黑色
# Animate from the current modulate color until the node is fully black.
func fade_out(is_delayed: bool = false) -> void:
	tween = create_tween()
	tween.finished.connect(_on_Tween_tween_completed)
	tween.tween_property(
		self,
		"modulate",
		Color.WHITE,
		duration_fade_out
	).from_current().set_delay(duration_fade_out if is_delayed else 0.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
	show()
	tween.play()
	is_playing = true


func _on_Tween_tween_completed() -> void:
	# 补间动画完成时的处理
	animation_finished.emit()
	if modulate == Color.TRANSPARENT:
		hide()  # 如果完全透明则隐藏
	is_playing = false
