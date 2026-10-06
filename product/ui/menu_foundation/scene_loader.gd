extends Node
## Adapted from Maaack SceneLoader (MIT). Routing and save ownership live in GameEntry.
signal scene_loaded(resource: PackedScene)
signal load_failed(message: String)
var _scene_path := ""
var progress := 0.0
var status := ResourceLoader.THREAD_LOAD_INVALID_RESOURCE
var elapsed := 0.0
func load_scene(scene_path: String) -> void:
	_scene_path = scene_path
	progress = 0.0
	elapsed = 0.0
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		load_failed.emit("冒险资源无法读取。请重试或返回标题。")
		return
	var error := ResourceLoader.load_threaded_request(_scene_path, "PackedScene")
	if error != OK:
		load_failed.emit("无法开始加载。请重试或返回标题。")
		return
	set_process(true)
func cancel() -> void:
	set_process(false)
func _ready() -> void:
	set_process(false)
func _process(delta: float) -> void:
	elapsed += delta
	var progress_array: Array = []
	status = ResourceLoader.load_threaded_get_status(_scene_path, progress_array)
	if not progress_array.is_empty(): progress = float(progress_array[0])
	match status:
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, ResourceLoader.THREAD_LOAD_FAILED:
			set_process(false)
			load_failed.emit("冒险加载失败。请重试或返回标题。")
		ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)
			var resource := ResourceLoader.load_threaded_get(_scene_path) as PackedScene
			if resource: scene_loaded.emit(resource)
			else: load_failed.emit("冒险资源不完整。请重试或返回标题。")
	if elapsed > 90.0 and is_processing():
		set_process(false)
		load_failed.emit("加载等待过久。请重试或返回标题。")
