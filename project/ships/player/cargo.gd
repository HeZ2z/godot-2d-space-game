# Worker node on the player ship that manages and maintains cargo and mining
# from mineables.
# 玩家船只上的工作节点，管理和维护货物以及从可开采物中挖矿。
class_name Cargo
extends Node

enum States { IDLE, MINING, UNLOADING }  # 状态枚举：空闲、挖矿、卸载

@export var stats: Resource = preload("res://ships/player/cargo_stats.tres") as StatsCargo  # 货物属性

var state: int = States.IDLE  # 当前状态
var is_mining := false  # 是否正在挖矿
var is_exporting := false  # 是否正在导出
var dockable_weakref: WeakRef  # 对接对象弱引用


func _ready() -> void:
	# 初始化货物系统
	stats.initialize()
	Events.docked.connect(_on_Player_docked)
	Events.undocked.connect(_on_Player_undocked)
	await owner.ready


func _physics_process(delta: float) -> void:
	# 根据状态处理货物操作
	match state:
		States.MINING:
			# 挖矿状态
			if stats.cargo == stats.get_max_cargo():
				state = States.IDLE

			var _asteroid: Asteroid = dockable_weakref.get_ref()
			if not _asteroid:
				state = States.IDLE
				Events.force_undock.emit()
			else:
				var mined: float = _asteroid.mine_amount(
					min(stats.get_max_cargo(), stats.get_mining_rate() * delta)
				)
				if mined == 0:
					Events.force_undock.emit()
					state = States.IDLE
				else:
					stats.cargo += mined
		States.UNLOADING:
			# 卸载状态
			if stats.cargo == 0:
				state = States.IDLE

			var _station: Station = dockable_weakref.get_ref()
			if not _station:
				state = States.IDLE
				Events.force_undock.emit()
			else:
				var export_amount : float = min(stats.get_unload_rate() * delta, stats.cargo)
				stats.cargo -= export_amount
				_station.accumulated_iron += export_amount
		States.IDLE:
			# 空闲状态
			Events.mine_finished.emit()


func _on_Player_docked(dockable: Node) -> void:
	# 玩家对接时的回调
	dockable_weakref = weakref(dockable)
	if dockable is Station:
		# 对接空间站，切换到卸载状态
		state = States.UNLOADING
	elif dockable is Asteroid:
		# 对接小行星，切换到挖矿状态
		state = States.MINING
		var asteroid_position: Vector2 = dockable.get_global_transform_with_canvas().origin
		Events.mine_started.emit(asteroid_position)


func _on_Player_undocked() -> void:
	# 玩家脱离对接时的回调
	state = States.IDLE
