extends Resource
## Product-owned, data-only adapter for the retained MAP02 groundcover resource.
## Preserves serialized fields; does not implement generation or rendering.

const GroundcoverMeshData = preload("res://world/map02_groundcover_mesh_data.gd")

@export var meshes: Array[GroundcoverMeshData] = []
@export var chunkSize: int = 50
@export var viewDistance: float = 200.0
