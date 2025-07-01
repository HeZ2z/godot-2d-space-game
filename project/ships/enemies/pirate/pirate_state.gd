# 海盗专用状态的样板代码
# 为海盗提供自动补全功能
# Boilerplate for Pirate-specific states
# Gives autocompletion for the Pirate
class_name PirateState
extends State

var ship: PirateShip  # 海盗飞船引用


func _ready() -> void:
	super()
	ship = owner  # 获取所有者（海盗飞船）
