# 连接各种升级按钮的按下事件，发出升级信号 - 玩家选择后改进相应能力，
# 同时海盗会生成
# Connects the press of the various upgrade buttons to emitting a signal that
# indicates an upgrade - the player reacts by improving what was selected,
# and pirates spawn.
extends Control

@onready var health_button := $HBoxContainer/HealthUpgrade  # 生命值升级按钮
@onready var speed_button := $HBoxContainer/SpeedUpgrade  # 速度升级按钮
@onready var cargo_button := $HBoxContainer/CargoUpgrade  # 货仓升级按钮
@onready var mine_button := $HBoxContainer/MiningUpgrade  # 开采升级按钮
@onready var weapon_button := $HBoxContainer/WeaponUpgrade  # 武器升级按钮
@onready var menu_sounds: MenuSoundPlayer = $MenuSoundPlayer  # 菜单音效播放器

@onready var buttons := $HBoxContainer.get_children()  # 所有按钮


func _ready() -> void:
	# 连接各升级按钮的事件
	health_button.button_down.connect(select_upgrade.bind(Events.UpgradeChoices.HEALTH))
	speed_button.button_down.connect(select_upgrade.bind(Events.UpgradeChoices.SPEED))
	cargo_button.button_down.connect(select_upgrade.bind(Events.UpgradeChoices.CARGO))
	mine_button.button_down.connect(select_upgrade.bind(Events.UpgradeChoices.MINING))
	weapon_button.button_down.connect(select_upgrade.bind(Events.UpgradeChoices.WEAPON))

	# 为所有按钮连接焦点进入事件
	for button in buttons:
		button.focus_entered.connect(_on_Button_focus_entered)


func open() -> void:
	# 打开升级菜单
	get_tree().paused = true  # 暂停游戏
	health_button.grab_focus()  # 默认焦点在生命值升级
	# 按顺序显示所有按钮，带有延迟动画
	for button in buttons:
		var delay: float = button.get_index() * 0.1
		menu_sounds.play_open(delay)
		button.appear(delay)
	show()


# 通过Events信号总线发出信号，解锁玩家选择的升级
# Emit a signal through the Events signal bus to unlock the upgrade selected by the player.
func select_upgrade(type: int) -> void:
	get_tree().paused = false  # 恢复游戏
	Events.upgrade_chosen.emit(type)  # 发出升级选择信号
	menu_sounds.play_confirm()
	# 按顺序隐藏所有按钮
	for button in buttons:
		var delay: float = button.get_index() * 0.1
		button.disappear(delay)
	await buttons[-1].disappeared  # 等待最后一个按钮消失
	hide()


func _on_Button_focus_entered() -> void:
	# 按钮获得焦点时播放音效
	menu_sounds.play_hide()
