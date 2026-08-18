extends Node

# GitHub 仓库信息
const REPO_OWNER = "thritly"
const REPO_NAME = "NewLight"
const GITHUB_API_URL = "https://api.github.com/repos/%s/%s/releases/latest"

# 信号（可选，用于外部监听）
signal update_found(version, download_url, file_size)
signal update_not_found
signal check_failed(error)

func _ready():
	# 延迟检查，避免阻塞启动流程
	call_deferred("check_for_updates")

func check_for_updates():
	# 1. 读取当前版本
	var current_version = get_current_version()
	if current_version == "":
		print("无法读取当前版本，跳过更新检查")
		# 也可弹窗提示版本文件缺失
		show_message("错误", "版本文件缺失，请重新安装游戏。")
		return

	print("当前版本: ", current_version)

	# 2. 请求 GitHub API
	var url = GITHUB_API_URL % [REPO_OWNER, REPO_NAME]
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_request_completed.bind(current_version))
	var error = http.request(url)
	if error != OK:
		print("HTTP 请求失败: ", error)
		check_failed.emit("网络请求失败")
		show_message("网络错误", "无法连接到更新服务器，请稍后重试。")
		http.queue_free()

func _on_request_completed(result, response_code, headers, body, current_version):
	var http = get_child(0)  # 获取 HTTPRequest 节点
	http.queue_free()

	if result != HTTPRequest.RESULT_SUCCESS:
		print("请求失败: ", result)
		check_failed.emit("请求失败")
		show_message("网络错误", "请求更新信息失败，请检查网络。")
		return

	if response_code != 200:
		print("HTTP 状态码: ", response_code)
		check_failed.emit("API 返回错误")
		show_message("服务器错误", "GitHub API 返回异常状态码。")
		return

	# 解析 JSON
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	if parse_result != OK:
		print("JSON 解析失败: ", json.get_error_message())
		check_failed.emit("数据解析失败")
		show_message("数据错误", "更新信息解析失败，请稍后重试。")
		return

	var data = json.data
	if not data.has("tag_name"):
		print("缺少 tag_name 字段")
		check_failed.emit("数据格式异常")
		show_message("数据错误", "更新信息格式异常。")
		return

	var latest_version = data["tag_name"]
	if latest_version.begins_with("v"):
		latest_version = latest_version.substr(1)

	# 3. 版本比较
	if is_newer_version(latest_version, current_version):
		print("发现新版本: ", latest_version)
		# 查找 Windows 平台的更新包
		var download_url = ""
		var file_size = 0
		if data.has("assets"):
			for asset in data["assets"]:
				if asset["name"] == "NewLight_v" + latest_version + "_Windows.zip":
					download_url = asset["browser_download_url"]
					file_size = asset["size"]  # 字节
					break
		if download_url == "":
			print("未找到 Windows 版本的更新包")
			check_failed.emit("未找到合适的更新包")
			show_message("更新错误", "未找到适用于 Windows 的更新包。")
			return

		# 显示更新信息（新版本）
		show_update_info(latest_version, download_url, file_size)
		update_found.emit(latest_version, download_url, file_size)
	else:
		print("已是最新版本")
		# 显示“已是最新”提示
		show_no_update_info(current_version)
		update_not_found.emit()

# ------------------------------------------------------------
# 工具函数：读取当前版本号（从 exe 同级目录的 version.txt）
# ------------------------------------------------------------
func get_current_version() -> String:
	var exe_dir = OS.get_executable_path().get_base_dir()
	var version_path = exe_dir + "/version.txt"
	if not FileAccess.file_exists(version_path):
		print("version.txt 未找到，尝试 user:// 目录")
		# 兼容旧版本：如果 exe 目录没有，尝试 user://
		var user_path = "user://version.txt"
		if FileAccess.file_exists(user_path):
			var file = FileAccess.open(user_path, FileAccess.READ)
			var content = file.get_as_text().strip_edges()
			file.close()
			return content
		return ""
	var file = FileAccess.open(version_path, FileAccess.READ)
	var content = file.get_as_text().strip_edges()
	file.close()
	return content

# ------------------------------------------------------------
# 版本比较（支持 x.y.z 格式，数字比较）
# ------------------------------------------------------------
func is_newer_version(latest, current) -> bool:
	var latest_parts = latest.split(".")
	var current_parts = current.split(".")
	var max_len = max(latest_parts.size(), current_parts.size())
	for i in range(max_len):
		var lv = int(latest_parts[i]) if i < latest_parts.size() else 0
		var cv = int(current_parts[i]) if i < current_parts.size() else 0
		if lv > cv:
			return true
		elif lv < cv:
			return false
	return false  # 版本相同

# ------------------------------------------------------------
# 显示“有更新”的信息（弹窗）
# ------------------------------------------------------------
func show_update_info(version, url, size):
	var size_mb = size / (1024.0 * 1024.0)
	var msg = "发现新版本 v%s\n文件大小: %.2f MB\n下载地址: %s" % [version, size_mb, url]
	print(msg)

	var dialog = AcceptDialog.new()
	dialog.dialog_text = msg
	dialog.title = "更新可用"
	dialog.get_ok_button().text = "复制地址"
	dialog.connect("confirmed", Callable(self, "_on_dialog_confirmed").bind(url))
	add_child(dialog)
	dialog.popup_centered()

	# 也可以添加“打开链接”按钮（可选），这里省略

# ------------------------------------------------------------
# 显示“已是最新版本”的信息（弹窗）
# ------------------------------------------------------------
func show_no_update_info(current_version):
	var msg = "当前已是最新版本 (v%s)" % current_version
	print(msg)
	show_message("更新检查", msg)

# ------------------------------------------------------------
# 通用消息弹窗（用于错误或无更新）
# ------------------------------------------------------------
func show_message(title, text):
	var dialog = AcceptDialog.new()
	dialog.dialog_text = text
	dialog.title = title
	dialog.get_ok_button().text = "确定"
	add_child(dialog)
	dialog.popup_centered()

# ------------------------------------------------------------
# 复制地址到剪贴板
# ------------------------------------------------------------
func _on_dialog_confirmed(url):
	DisplayServer.clipboard_set(url)
	print("下载地址已复制到剪贴板")
	# 如果你希望直接打开浏览器，可以取消注释下面一行：
	# OS.shell_open(url)
