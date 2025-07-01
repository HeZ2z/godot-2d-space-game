# Code-based special effect that animates a set of lines extending out to
# represent a 'pop'. For full effect, make a popping noise with your mouth.
# 基于代码的特效，通过动画显示一组向外延伸的线条来表现"爆裂"效果。
# 为了达到完整效果，请用嘴发出爆裂声。
extends Node2D

@export var color := Color.BLUE  # 线条颜色
@export var radius := 200.0  # 半径
@export var lines := 12  # 线条数量
@export var length_max := 100.0  # 最大长度
@export var distance_start := 10.0  # 起始距离
@export var distance_max := 30.0  # 最大距离
@export var duration := 0.35  # 持续时间

var current_length := 0.0  # 当前长度
var current_distance := 10.0  # 当前距离
var elapsed := 0.0  # 经过时间


func _ready() -> void:
	# 设置为顶级节点
	set_as_top_level(true)


func _draw() -> void:
	# 绘制爆裂线条
	var angle_iteration := 360.0 / lines
	for i in range(lines):
		var angle := i * angle_iteration
		var direction := GSAIUtils.angle_to_vector2(deg_to_rad(angle))
		draw_line(
			direction * current_distance,
			(direction * current_distance) + direction * current_length,
			color
		)


func _process(delta: float) -> void:
	# 更新动画
	elapsed += delta
	var t := elapsed / duration
	current_distance = lerpf(distance_start, distance_max, t)  # 插值距离
	current_length = lerpf(0, length_max, t)  # 插值长度
	queue_redraw()  # 重新绘制
	if t >= duration:
		queue_free()  # 动画完成后销毁
