# Generic State Machine. Initializes states and delegates engine callbacks
# (_physics_process, _unhandled_input) to the active state.
# 通用状态机。初始化状态并将引擎回调（_physics_process, _unhandled_input）委托给活动状态。
extends Node
class_name StateMachine

@export var initial_state := NodePath()  # 初始状态路径

@onready var state: State = get_node(initial_state): set = set_state  # 当前状态
@onready var _state_name := state.name  # 状态名称


func _init() -> void:
	# 添加到状态机组
	add_to_group("state_machine")


func _ready() -> void:
	# 等待所有者准备完成后进入初始状态
	await owner.ready
	state.enter()


func _unhandled_input(event: InputEvent) -> void:
	# 将未处理输入委托给当前状态
	state.unhandled_input(event)


func _physics_process(delta: float) -> void:
	# 将物理处理委托给当前状态
	state.physics_process(delta)


func transition_to(target_state_path: String, msg: Dictionary = {}) -> void:
	# 转换到目标状态
	if not has_node(target_state_path):
		return

	var target_state := get_node(target_state_path)

	state.exit()  # 退出当前状态
	self.state = target_state  # 设置新状态
	state.enter(msg)  # 进入新状态


func set_state(value: State) -> void:
	# 设置状态
	state = value
	_state_name = state.name
