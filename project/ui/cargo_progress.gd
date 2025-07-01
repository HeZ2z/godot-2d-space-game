# 货物进度条，显示玩家货仓容量和矿物动画
extends ProgressBar

@export var Ore: PackedScene = preload("res://world/ores/iron_ore.tscn")  # 矿物场景

@onready var arc_bottom := $ArcBottom  # 底部弧形
@onready var arc_top := $ArcTop  # 顶部弧形
@onready var fill := $Fill  # 填充部分
@onready var tween : Tween  # 补间动画
@onready var anim_player := $AnimationPlayer  # 动画播放器
@onready var audio_unload: AudioStreamPlayer = $AudioUnload  # 卸载音效

var docked_position := Vector2.ZERO  # 对接位置

var _player_is_mining := false  # 玩家是否正在开采


func _ready() -> void:
	# 连接相关事件
	Events.docked.connect(_on_Events_docked)
	Events.mine_started.connect(_on_Events_mine_started)
	Events.mine_finished.connect(_on_Events_mine_finished)
	self.value_changed.connect(_on_value_changed)
	# 共享弧形显示
	share(arc_bottom)
	share(arc_top)


func initialize(player: PlayerShip) -> void:
	# 初始化货物进度条，连接玩家货仓统计数据
	player.cargo.stats.stat_changed.connect(_on_Stats_stat_changed)
	max_value = player.cargo.stats.get_max_cargo()
	value = player.cargo.stats.get_stat("cargo")


func spawn_ore() -> void:
	# 生成矿物动画效果
	var ore := Ore.instantiate()
	add_child(ore)
	if _player_is_mining:
		# 开采时：从对接点飞向货物条
		ore.global_position = docked_position
		ore.animate_to(global_position + pivot_offset)
	else:
		# 卸载时：从货物条飞向对接点
		ore.global_position = global_position + pivot_offset
		ore.animate_to(docked_position)
		audio_unload.play()


func _on_Events_docked(docking_point: DockingPoint) -> void:
	# 记录对接点位置
	docked_position = docking_point.get_global_transform_with_canvas().origin


func _on_Events_mine_started(_mining_position: Vector2) -> void:
	# 开始开采
	_player_is_mining = true


func _on_Events_mine_finished() -> void:
	# 结束开采
	_player_is_mining = false


func _on_Stats_stat_changed(stat: String, _value_start: float, current_value: float) -> void:
	# 当货仓统计数据改变时更新进度条
	if not stat == "cargo":
		return
	value = current_value


func _on_value_changed(_value: float) -> void:
	# 当进度条值改变时播放动画和生成矿物效果
	if tween and tween.is_running():
		return
	tween = create_tween()
	tween.tween_property(
		fill,
		"scale",
		Vector2(ratio, ratio),
		0.25
	).from_current().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.play()
	spawn_ore()
