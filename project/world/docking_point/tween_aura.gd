# Holds state for tweening Auras, see `DockingPoint` and its `DockingAura`.
# 保存光环补间动画的状态，参见 `DockingPoint` 及其 `DockingAura`。
class_name TweenAura

@export var scale_hidden := Vector2.ZERO  # 隐藏时的缩放
@export var scale_final := Vector2(1, 1)  # 最终缩放
@export var duration_appear := 1.0  # 出现持续时间
@export var duration_disappear := 0.5  # 消失持续时间
