# 设置和控制升级按钮的图标和标签。@tool关键字确保我们可以在编辑器中看到结果。
@tool
# Sets and controls the icon and _label of the upgrade buttons. The tool keyword
# makes sure we can see the result in the editor.
extends TextureButton

signal appeared;  # 出现信号
signal disappeared;  # 消失信号

@export var texture: Texture2D: set = set_texture  # 纹理
@export var text := "": set = set_text  # 文本

@onready var _texture_rect := $VBoxContainer/TextureRect  # 纹理矩形
@onready var _label := $VBoxContainer/Label  # 标签
@onready var _animation_player := $AnimationPlayer  # 动画播放器


func appear(delay : float = 0) -> void:
	# 显示动画
	_play_animation("show", delay)


func disappear(delay : float = 0) -> void:
	# 隐藏动画
	_play_animation("hide", delay)


func _play_animation(animation, delay) -> void:
	# 播放动画，可选延迟
	_animation_player.set_assigned_animation(animation)
	_animation_player.seek(0, true)
	await get_tree().create_timer(delay).timeout
	_animation_player.play()


func set_texture(value: Texture2D) -> void:
	# 设置纹理
	texture = value
	if not _texture_rect:
		await self.ready
	_texture_rect.texture = value


func set_text(value: String) -> void:
	# 设置文本
	text = value
	if not _texture_rect:
		await self.ready
	_label.text = value
	_label.visible = text != ""


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	# 动画播放完成时发出相应信号
	match anim_name:
		"show":
			appeared.emit()
		"hide":
			disappeared.emit()
