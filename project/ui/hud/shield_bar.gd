# 玩家飞船的动画护盾条
# Animated shield bar for the Player's ship.
extends TextureProgressBar

@export var gradient: Gradient  # 护盾条颜色渐变
@export var stats: Resource = preload("res://ships/player/player_stats.tres") as StatsShip  # 玩家统计数据
@export var danger_threshold := 0.3  # 危险阈值（护盾低于此值时显示危险动画）

@onready var tween : Tween  # 补间动画
@onready var anim_player := $AnimationPlayer  # 动画播放器


func initialize(player: PlayerShip) -> void:
	# 初始化护盾条，连接玩家统计数据变化事件
	player.stats.stat_changed.connect(_on_Stats_stat_changed)
	max_value = player.stats.get_max_health()
	value = player.stats.get("health")
	tint_progress = gradient.sample(value / max_value)


func _on_Stats_stat_changed(stat: String, value_start: float, current_value: float) -> void:
	# 当统计数据改变时更新护盾条
	if not stat == "health":
		return
	# 停止之前的补间动画
	if tween and tween.is_running():
		tween.kill()
	# 创建新的补间动画来平滑更新护盾值
	tween = create_tween()
	tween.step_finished.connect(_on_Tween_step_finished)
	tween.tween_property(
		self, "value", current_value, 0.25
	).from(value_start).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.play()
	# 播放受损动画
	anim_player.play("damage")


func _on_Tween_step_finished(_idx: int) -> void:
	# 补间动画步骤完成时更新护盾条颜色
	var shield_ratio := value / max_value
	var gradient_color := gradient.sample(shield_ratio)
	tint_progress = gradient_color

	# 如果护盾比例低于危险阈值，播放危险动画
	if shield_ratio <= danger_threshold:
		var anim: Animation = anim_player.get_animation("danger")
		var final_tint := gradient_color + Color(1.0, 1.0, 1.0, 0.0)
		anim.track_set_key_value(0, 0, gradient_color)
		anim.track_set_key_value(0, 1, final_tint)
		anim_player.play("danger")
