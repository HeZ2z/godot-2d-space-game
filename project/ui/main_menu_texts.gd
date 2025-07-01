# 主菜单文本动画控制
extends Control

const EXPOSE_DURATION := 2.0  # 显示持续时间
const FADE_DURATION := 0.5  # 淡出持续时间

@onready var container := $HBoxContainer/CenterContainer  # 容器
@onready var tween := create_tween()  # 补间动画
@onready var keyboard := container.get_node("AnyKey")  # 按键提示

func _ready() -> void:
	var total_time := 0.0
	# 设置循环播放的补间动画
	tween.set_loops()
	tween.play()
