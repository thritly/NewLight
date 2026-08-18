extends Area2D
@onready var animated_sprite = $AnimatedSprite2D

var dragging = false
var drag_offset = Vector2()
var is_hovering = false
var drag_start_mouse = Vector2()      # 鼠标按下时的全局坐标
var drag_start_window = Vector2i()    # 窗口按下时的左上角坐标
var drag_target_window_pos = Vector2i()   # 目标窗口位置（由鼠标计算得出）

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("开始运行")
	# 直接检查自身是否有 "kati" 这个动画
	if animated_sprite.sprite_frames.has_animation("kati"):
		animated_sprite.play("kati")
	else:
		print("警告：找不到 'kati' 动画，请检查 SpriteFrames 资源")
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	# 连接 Area2D 的信号（鼠标进入/离开/点击）
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_area_input)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
	

func _input(event: InputEvent) -> void:
	# 处理拖拽移动（只在这里统一处理）
	if event is InputEventMouseMotion and dragging:
		get_window().position += Vector2i(event.relative)
	
	# 鼠标左键释放 -> 停止拖拽（无论鼠标在哪里释放）
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging = false
		
	# 响应鼠标右键按下事件
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_show_context_menu(event.global_position)   # 使用全局坐标

# 鼠标进入角色区域（可以改变光标样式或播放表情）
func _on_mouse_entered():
	is_hovering = true
	# 可选：让角色缩放一点表示“可拖拽”
	#scale = Vector2(1.1, 1.1)

# 鼠标离开角色区域
func _on_mouse_exited():
	is_hovering = false
	scale = Vector2(1, 1)
	
func _on_area_input(viewport, event, shape_idx):
	# 鼠标左键按下
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			# 记录点击位置与角色位置的偏移
			drag_start_mouse = get_global_mouse_position()
			drag_start_window = get_window().position
			print("开始拖拽")
		else:
			dragging = false
			print("结束拖拽")
		
var _menu: PopupMenu = null

func _show_context_menu(global_pos: Vector2) -> void:
	# 如果已有菜单则先删除（避免重叠）
	if _menu and is_instance_valid(_menu):
		_menu.queue_free()
	
	# 创建新的 PopupMenu 并添加到场景树（最好添加到根视图，保证坐标以屏幕为准）
	_menu = PopupMenu.new()
	get_tree().root.add_child(_menu)  # 添加到根视口，位置直接对应屏幕坐标
	
	# 设置菜单位置（PopupMenu 的 position 是相对于父节点的，因父节点是 root，所以用全局坐标）
	_menu.position = global_pos
	
	# 添加菜单项
	_menu.add_item("猫", 0)      # id 可选
	_menu.add_item("卡提", 1)
	#_menu.add_item("设置", 2)
	_menu.add_separator()
	_menu.add_item("退出", 3)
	
	# 连接信号
	_menu.id_pressed.connect(_on_menu_item_selected)
	
	# 弹出菜单
	_menu.popup()
	
	# 监听菜单关闭（可选：用于清理）
	_menu.popup_hide.connect(_on_menu_hidden)

func _on_menu_item_selected(id: int) -> void:
	match id:
		0:
			print("猫")
			animated_sprite.play("cat")
			# 实现切换逻辑
		1:
			print("卡提")
			animated_sprite.play("kati")
			# 实现说话
		#2:
			#print("打开设置")
			# 打开设置界面
		3:
			print("退出宠物")
			get_tree().quit()   # 或通知 Main 关闭
	# 菜单选择后自动关闭，无需额外操作

func _on_menu_hidden() -> void:
	# 菜单关闭后清理（可选）
	if _menu and is_instance_valid(_menu):
		_menu.queue_free()
		_menu = null
