# 海盗有限状态机的休息状态。小队长设置计时器，
# 当该开始巡逻时发出信号，小队成员根据信号跟随。
# A state for the pirates' finite state machine. The squad leader sets a timer
# and emits a signal when it's time to go on patrol, and the squaddies follow
# based on the signal.
extends PirateState

var initialized := false  # 是否已初始化

const REST_TIME_MIN := 15.0  # 最小休息时间
const REST_TIME_MAX := 30.0  # 最大休息时间

var _timer: Timer  # 计时器
var _accel := GSAITargetAcceleration.new()  # 加速度（静止状态为零）


func _ready() -> void:
	super()
	owner.squad_leader_changed.connect(_on_Leader_changed)


func enter(_msg := {}) -> void:
	if ship.is_squad_leader:
		# 小队长：设置休息计时器
		if not _timer:
			_timer = Timer.new()
			add_child(_timer)
		_timer.timeout.connect(_on_Timer_timeout)
		_timer.start(ship.rng.randf_range(REST_TIME_MIN, REST_TIME_MAX))
	else:
		# 小队成员：等待领队开始巡逻的信号
		Events.begin_patrol.connect(_on_SquadLeader_begin_patrol)


func exit() -> void:
	# 退出休息状态
	if ship.is_squad_leader:
		if _timer:
			_timer.timeout.disconnect(_on_Timer_timeout)
	else:
		Events.begin_patrol.disconnect(_on_SquadLeader_begin_patrol)


func physics_process(delta: float) -> void:
	# 物理处理：应用零加速度（保持静止）
	ship.agent._apply_steering(_accel, delta)


func _on_Timer_timeout() -> void:
	# 休息时间结束，开始巡逻
	Events.begin_patrol.emit(ship)
	_state_machine.transition_to("Patrol", {patrol_point = ship.patrol_point})


func _on_SquadLeader_begin_patrol(leader: Node) -> void:
	# 小队长开始巡逻时跟随
	if ship.squad_leader == leader:
		_state_machine.transition_to("Patrol", {patrol_point = ship.patrol_point})


func _on_Leader_changed(current_patrol_point: Vector2) -> void:
	# 领队改变时重新进入休息状态
	if _state_machine.state == self:
		_state_machine.transition_to("Rest", {patrol_point = current_patrol_point})
