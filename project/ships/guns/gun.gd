# Spawns, positions and configures a Projectile instance in space and registers
# it into the global projectiles registry. Firing rate is controlled via a
# cooldown timer.
# 在空间中生成、定位和配置抛射物实例，并将其注册到全局抛射物注册表中。
# 射击频率通过冷却计时器控制。
class_name Gun
extends Node2D

@export var projectile: PackedScene  # 抛射物场景
@export var stats: Resource = preload("res://ships/player/player_gun_stats.tres")  # 武器属性

@onready var cooldown: Timer = $Cooldown  # 冷却计时器


func _ready() -> void:
	# 初始化属性并设置冷却时间
	stats.initialize()
	cooldown.wait_time = stats.get_cooldown()


func _get_configuration_warnings() -> PackedStringArray:
	# 配置警告：缺少抛射物场景
	return PackedStringArray(["Missing Projectile scene, the gun will not be able to fire"]) if not Projectile else PackedStringArray([])


func fire(spawn_position: Vector2, spawn_orientation: float, projectile_mask: int) -> void:
	# 开火：生成抛射物
	if not cooldown.is_stopped() or not Projectile:
		return

	var spread: float = stats.get_spread()  # 获取散布角度

	var projectile_inst: Projectile = projectile.instantiate()
	projectile_inst.global_position = spawn_position
	projectile_inst.rotation = spawn_orientation + deg_to_rad(random_spread(spread))
	projectile_inst.speed *= 1.0 + random_spread(0.4)  # 添加速度随机变化
	projectile_inst.collision_mask = projectile_mask
	projectile_inst.shooter = owner  # 设置射击者
	projectile_inst.damage += stats.get_damage()  # 设置伤害值

	ObjectRegistry.register_projectile(projectile_inst)
	cooldown.wait_time = stats.get_cooldown() * (1.0 + random_spread(0.2))  # 冷却时间随机变化
	cooldown.start()


func _on_Stats_stat_changed(stat_name: String, _old_value: float, new_value: float) -> void:
	# 属性改变时的回调
	match stat_name:
		"cooldown":
			cooldown.wait_time = new_value


static func random_spread(value: float) -> float:
	# 生成随机散布值
	var half_spread := value / 2.0
	return randf_range(-half_spread, half_spread)
