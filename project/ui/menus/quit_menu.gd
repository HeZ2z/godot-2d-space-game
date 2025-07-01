# 显示确认屏幕，询问玩家是否真的要离开游戏返回主菜单
# Presents a confirmation screen whether the player really intends on leaving
# the game back to the main menu or not.
extends MarginContainer

@onready var yes_button := $VBoxContainer/HBoxContainer/YesButton  # 确认按钮
@onready var no_button := $VBoxContainer/HBoxContainer/NoButton  # 取消按钮
@onready var menu_sounds: MenuSoundPlayer = $MenuSoundPlayer  # 菜单音效播放器


func _ready() -> void:
	visible = false
	set_process_input(false)
	# 为所有按钮连接焦点进入事件
	for button in [yes_button, no_button]:
		button.connect("focus_entered", _on_Button_focus_entered)


func _input(event: InputEvent) -> void:
	# 按取消键关闭菜单
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	# 打开退出菜单
	get_tree().paused = true  # 暂停游戏
	menu_sounds.play_open()
	show()
	no_button.grab_focus()  # 默认焦点在"否"按钮
	set_process_input(true)


func close() -> void:
	# 关闭退出菜单
	menu_sounds.play_close()
	get_tree().paused = false  # 恢复游戏
	set_process_input(false)
	hide()


func request_quit() -> void:
	# 请求退出游戏
	Events.quit_requested.emit()
	close()


func _on_YesButton_pressed() -> void:
	# 确认退出
	request_quit()


func _on_NoButton_pressed() -> void:
	# 取消退出
	close()


func _on_Button_focus_entered() -> void:
	# 按钮获得焦点时播放音效
	menu_sounds.play_hide()
