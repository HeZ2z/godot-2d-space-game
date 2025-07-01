# State interface to use in Hierarchical State Machines.
# The lowest leaf tries to handle callbacks, and if it can't, it delegates the work to its parent.
# It's up to the user to call the parent state's functions, e.g. `_parent.physics_process(delta)`
# Use State as a child of a StateMachine node.
# 分层状态机中使用的状态接口。
# 最底层的叶子尝试处理回调，如果不能处理，则将工作委托给其父状态。
# 用户需要调用父状态的函数，例如 `_parent.physics_process(delta)`
# 将State用作StateMachine节点的子节点。
# tags: abstract
extends Node
class_name State

@onready var _state_machine := _get_state_machine(self)  # 状态机引用
var _parent: State = null  # 父状态


func _ready() -> void:
	# 等待所有者准备完成后设置父状态
	await owner.ready
	_parent = get_parent() as State


func unhandled_input(_event: InputEvent) -> void:
	# 处理未处理的输入事件
	pass


func physics_process(_delta: float) -> void:
	# 物理处理
	pass


func enter(_msg: Dictionary = {}) -> void:
	# 进入状态
	pass


func exit() -> void:
	# 退出状态
	pass


func _get_state_machine(node: Node) -> Node:
	# 递归查找状态机节点
	if node != null and not node.is_in_group("state_machine"):
		return _get_state_machine(node.get_parent())
	return node
