extends Node
## Adapted from Maaack SceneLoader (MIT). Routing and save ownership live in GameEntry.
signal scene_loaded(resource: PackedScene)
signal load_failed(message: String)
var _scene_path := ""
var progress := 0.0
var status := ResourceLoader.THREAD_LOAD_INVALID_RESOURCE
var elapsed := 0.0
var _request_generation := 0
func load_scene(scene_path: String, main_thread := false) -> void:
	_request_generation += 1
	_scene_path = scene_path
	progress = 0.0
	elapsed = 0.0
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		load_failed.emit("冒险资源无法读取。请重试或返回标题。")
		return
	if main_thread:
		# The authored world's native resources load successfully on the main
		# thread but stall in load_threaded_request. Keep the actual loading
		# surface visible, then load without moving native initialization to a worker.
		set_process(false)
		status = ResourceLoader.THREAD_LOAD_IN_PROGRESS
		_load_on_main_thread.call_deferred(scene_path, _request_generation)
		return
	var error := ResourceLoader.load_threaded_request(_scene_path, "PackedScene")
	if error != OK:
		load_failed.emit("无法开始加载。请重试或返回标题。")
		return
	set_process(true)
func cancel() -> void:
	_request_generation += 1
	set_process(false)
func _load_on_main_thread(scene_path: String, generation: int) -> void:
	await get_tree().process_frame
	if generation != _request_generation: return
	var resource := ResourceLoader.load(scene_path, "PackedScene") as PackedScene
	if generation != _request_generation: return
	if resource == null:
		status = ResourceLoader.THREAD_LOAD_FAILED
		load_failed.emit("冒险资源不完整。请重试或返回标题。")
		return
	status = ResourceLoader.THREAD_LOAD_LOADED
	progress = 1.0
	scene_loaded.emit(resource)
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
