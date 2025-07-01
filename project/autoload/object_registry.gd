# Creates, maintains, and organizes spawned special effects or projectiles; 
# objects that should be untied from their spawners' lifespan when freed.
# 创建、维护和组织生成的特效或抛射物；
# 这些对象在释放时应该与生成器的生命周期解除绑定
extends Node

@onready var _effects := $Effects  # 特效节点
@onready var _projectiles := $Projectiles  # 抛射物节点
@onready var _distortions: SubViewport  # 扭曲效果视窗


func register_effect(effect: Node) -> void:
	# 注册特效节点
	_effects.add_child(effect)


func register_projectile(projectile: Node) -> void:
	# 注册抛射物节点
	_projectiles.add_child(projectile)


func register_distortion_effect(effect: Node2D) -> void:
	# 注册扭曲效果节点
	if is_instance_valid(_distortions):
		_distortions.add_child(effect)


func register_distortion_parent(viewport: SubViewport) -> void:
	# 注册扭曲效果的父视窗
	_distortions = viewport
