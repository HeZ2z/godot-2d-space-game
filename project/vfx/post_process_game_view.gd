# 游戏视图后处理效果，处理位移遮罩
@tool
extends TextureRect


func _ready() -> void:
	# 获取位移遮罩视口的纹理
	var vp_text = get_node("../../DistortMaskView/SubViewport").get_texture()
	var s_mat = material as ShaderMaterial
	# 设置着色器参数中的位移遮罩
	s_mat.set_shader_parameter("displacement_mask", vp_text)
