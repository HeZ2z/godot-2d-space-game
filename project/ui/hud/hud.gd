# HUD (Head-Up Display) controller
# HUD（抬头显示器）控制器
extends Control

@onready var shield_bar := $ShieldBar  # 护盾条
@onready var cargo_gauge := $CargoGauge  # 货物量表


func initialize(player: PlayerShip) -> void:
	# 初始化HUD元素
	shield_bar.initialize(player)
	cargo_gauge.initialize(player)
