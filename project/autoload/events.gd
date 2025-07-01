# Autoloaded singleton that holds signals that would be troublesome to wire in a
# local parent or a scene owner.
# 自动加载的单例，用于保存在局部父节点或场景所有者中难以连接的信号
# 
# This keeps objects passed through setup functions or unsafe accessors at a
# lower count, and can be replaced with simpler `Events.connect` calls.
# 这样可以减少通过设置函数或不安全访问器传递的对象数量，
# 可以用更简单的 `Events.connect` 调用来替代
extends Node

signal player_died  # 玩家死亡信号
signal quit_requested  # 请求退出信号

signal node_spawned(node)  # 节点生成信号
signal station_spawned(station, player)  # 空间站生成信号
signal pirate_spawned(pirate)  # 海盗生成信号
signal asteroid_spawned(object)  # 小行星生成信号

signal map_toggled(is_visible, animation_length)  # 地图切换信号

signal upgrade_unlocked  # 升级解锁信号
signal upgrade_chosen(choice)  # 升级选择信号

signal damaged(target, damage, shooter)  # 受伤信号

signal begin_patrol(squad_leader)  # 开始巡逻信号
signal end_patrol(squad_leader)  # 结束巡逻信号
signal reached_cluster(squad_leader)  # 到达集群信号
signal squad_leader_changed(old_leader, new_leader, current_patrol_point)  # 队长更换信号
signal target_aggroed(squad_leader, target)  # 目标仇恨信号
signal call_off_pursuit(squad_leader)  # 取消追击信号

signal force_undock  # 强制脱离对接信号
signal docked(docking_point)  # 对接信号
signal undocked  # 脱离对接信号
signal mine_started(mine_position)  # 开始挖矿信号
signal mine_finished  # 挖矿完成信号

signal explosion_occurred  # 爆炸发生信号

enum UpgradeChoices { HEALTH, SPEED, CARGO, MINING, WEAPON }  # 升级选择枚举：生命值、速度、货物、挖矿、武器

enum UITypes { UPGRADE, QUIT }  # UI类型枚举：升级、退出
