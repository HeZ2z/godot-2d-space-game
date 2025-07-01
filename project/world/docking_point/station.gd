# The player's station - consumes iron until an upgrade threshold is reached,
# then emits tot the gam that an upgrade has been unlocked.
# 玩家的空间站 - 消耗铁矿直到达到升级阈值，然后向游戏发出升级已解锁的信号。
class_name Station
extends DockingPoint

@export var upgrade_iron_amount := 99.0  # 升级所需铁矿量

var accumulated_iron := 0.0: set = _set_accumulated_iron  # 累积铁矿量


func _ready() -> void:
	# 初始化空间站
	super()

func _set_accumulated_iron(value: float) -> void:
	# 设置累积铁矿量
	accumulated_iron = value
	if accumulated_iron >= upgrade_iron_amount:
		# 达到升级阈值时重置并发出升级解锁信号
		accumulated_iron = 0
		Events.upgrade_unlocked.emit()
		upgrade_iron_amount *= 1.25  # 提高下次升级所需的铁矿量
