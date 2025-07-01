# Virtual base class for stats (health, speed...) that support upgrades.
# 支持升级的属性（生命值、速度等）的虚拟基类
#
# You must call `initialize()` to initialize the stats' values. This ensures that they are in sync
# with the values modified in Godot's inspector.
# 必须调用 `initialize()` 来初始化属性值。这确保它们与在Godot检查器中修改的值同步。
#
# Each stat should be a floating point value, and we recommend to make them private properties, as
# they should be read-only. To get a stat's calculated value, with modifiers, see `get_stat()`.
# 每个属性都应该是浮点值，我们建议将它们设为私有属性，因为它们应该是只读的。
# 要获取带有修饰符的属性计算值，请参阅 `get_stat()`。
class_name Stats
extends Resource

signal stat_changed(stat, old_value, new_value)  # 属性改变信号

# Stores a cached array of property names that are stats as strings, that we use to find and
# calculate the stats with upgrades from the base stats.
# 存储作为字符串的属性名称的缓存数组，用于查找和计算基础属性的升级
var _stats_list := _get_stats_list()
# Modifiers has a list of modifiers for each property in `_stats_list`. A modifier is a dict that
# requires a key named `value`. The value of a modifier can be positive or negative.
# 修饰符为 `_stats_list` 中每个属性都有一个修饰符列表。修饰符是一个要求有名为 `value` 键的字典。
# 修饰符的值可以是正数或负数。
var _modifiers := {}
# Stores the cached values for the computed stats
# 存储计算后属性的缓存值
var _cache := {}


# Initializes the keys in the modifiers dict, ensuring they all exist, without going through the
# property's setter.
# 初始化修饰符字典中的键，确保它们都存在，而不通过属性的设置器。
func _init() -> void:
	for stat in _stats_list:
		_modifiers[stat] = []
		_cache[stat] = 0.0


# Call this function from your node's ready function, before accessing the stats. This ensures
# they're all loaded.
# 在访问属性之前，从节点的ready函数调用此函数。这确保它们都已加载。
func initialize() -> void:
	_update_all()


# Get the final value of a stat, with all modifiers applied to it.
# 获取属性的最终值，包含所有应用的修饰符
func get_stat(stat_name := "") -> float:
	assert(stat_name in _stats_list)
	return _cache[stat_name]


# Adds a modifier to the stat corresponding to `stat_name` and returns the new modifier's id.
# 向对应 `stat_name` 的属性添加修饰符，并返回新修饰符的id
func add_modifier(stat_name: String, modifier: float) -> int:
	assert(stat_name in _stats_list)
	_modifiers[stat_name].append(modifier)
	_update(stat_name)
	return len(_modifiers)


# Removes a modifier from the stat corresponding to `stat_name`.
# 从对应 `stat_name` 的属性中移除修饰符
func remove_modifier(stat_name: String, id: int) -> void:
	assert(stat_name in _stats_list)
	_modifiers[stat_name].erase(id)
	_update(stat_name)


# Removes the last modifier applied the stat corresponding to `stat_name`.
# 移除应用到对应 `stat_name` 属性的最后一个修饰符
func pop_modifier(stat_name: String) -> void:
	assert(stat_name in _stats_list)
	_modifiers[stat_name].pop_back()
	_update(stat_name)


# Remove all modifiers and recalculate stats.
# 移除所有修饰符并重新计算属性
func reset() -> void:
	_modifiers = {}
	_update_all()


# Calculates the final value of a single stat, its based value with all modifiers applied.
# 计算单个属性的最终值，即应用所有修饰符后的基础值
func _update(stat: String = "") -> void:
	var value_start: float = self.get(_stats_list[stat])
	var value = value_start
	for modifier in _modifiers[stat]:
		value += modifier
	_cache[stat] = value
	stat_changed.emit(stat, value_start, value)


# Recalculates every stat from the base stat, with modifiers.
# 从基础属性重新计算每个属性，包含修饰符
func _update_all() -> void:
	for stat in _stats_list:
		_update(stat)


# Returns a list of stat properties as strings.
# 返回属性列表作为字符串
func _get_stats_list() -> Dictionary:
	var ignore := [
		"resource_scene_unique_id",
		"resource_local_to_scene",
		"resource_name",
		"resource_path",
		"script",
		"_stats_list",
		"_modifiers",
		"_cache"
	]
	var stats := {}
	for p in get_property_list():
		if p.name[0].capitalize() == p.name[0]:
			continue
		if p.name in ignore:
			continue
		if p.name.ends_with(".gd"):
			continue
		stats[p.name.lstrip("_")] = p.name
	return stats
