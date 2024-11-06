extends Node2D

@export var _tileSet:TileSet
@export var _chunkSize = Vector2(32, 32)
@export var _chunkBuffer:int = 1
var _loadedChunks = {}
var _noise = FastNoiseLite.new()
var HoldingMouse = false
var _noiseValues = []
var _hoverChunk = Vector2()

func _ready():
	_noise.seed = randi() % 2000000 - 1000000
	_noise.frequency = 0.01
	load_chunks_around_position(Vector2.ZERO)

func refresh_chunks(pos: Vector2) -> void:
	load_chunks_around_position(pos)
	unload_chunks_outside_position(pos)

func load_chunks_around_position(current_position):
	for x in range(-_chunkBuffer, _chunkBuffer + 1):
		for y in range(-_chunkBuffer, _chunkBuffer + 1):
			var chunkPosition = get_chunk_position(current_position) + Vector2i(x, y)
			if not _loadedChunks.has(chunkPosition):
				var chunk = TileMapLayer.new()
				chunk.set_tile_set(_tileSet)
				chunk.get_tile_set().tile_size = _tileSet.tile_size
				add_child(chunk)
				_loadedChunks[chunkPosition] = chunk

	var chunk_keys = _loadedChunks.keys()
	for chunk in chunk_keys:
		var chunkPosition = chunk
		var chunkLayer = _loadedChunks.get(chunk)
		for x in range(_chunkSize.x):
			for y in range(_chunkSize.y):
				var tilePosition = chunkPosition as Vector2 * _chunkSize as Vector2 + Vector2(x, y)
				var tileValue = _noise.get_noise_2d(tilePosition.x, tilePosition.y)

				if tileValue < -0.25:
					chunkLayer.set_cell(Vector2(tilePosition.x, tilePosition.y), 0, Vector2(5, 0), 0)
				elif tileValue < -0.1:
					chunkLayer.set_cell(Vector2(tilePosition.x, tilePosition.y), 0, Vector2(2, 0), 0)
				elif tileValue < 0.0 and tileValue >= -0.1:
					chunkLayer.set_cell(Vector2(tilePosition.x, tilePosition.y), 0, Vector2(1, 0), 0)
				else:
					chunkLayer.set_cell(Vector2(tilePosition.x, tilePosition.y), 0, Vector2(0, 0), 0)

func unload_chunks_outside_position(current_position):
	var chunksToRemove = []

	var chunk_keys = _loadedChunks.keys()
	for chunk in chunk_keys:
		if not is_position_has_around_chunk(current_position, chunk):
			chunksToRemove.append(chunk)
			var chunk_to_remove = _loadedChunks.get(chunk)
			remove_child(chunk_to_remove)
			chunk_to_remove.queue_free()

	for chunkPosition in chunksToRemove:
		_loadedChunks.erase(chunkPosition)

func get_chunk_position(current_position):
	var tileSize = _tileSet.tile_size
	#print("chunk_pos_x: " + str(floor(current_position.x / (_chunkSize.x * tileSize.x))) + ", chunk_pos_y: " + str(floor(current_position.y / (_chunkSize.y * tileSize.y))))
	return Vector2i(floor(current_position.x / (_chunkSize.x * tileSize.x)), floor(current_position.y / (_chunkSize.y * tileSize.y)))

func is_position_has_around_chunk(current_position, chunkPosition):
	var tileSize = _tileSet.tile_size
	for x in range(-_chunkBuffer, _chunkBuffer + 1):
		for y in range(-_chunkBuffer, _chunkBuffer + 1):
			var chunk = chunkPosition + Vector2i(x, y)
			var chunkWorldPosition_x = chunk.x * _chunkSize.x * tileSize.x
			var chunkWorldPosition_y = chunk.y * _chunkSize.y * tileSize.y
			var chunkWorldPosition = Vector2(chunkWorldPosition_x, chunkWorldPosition_y)
			var rect_size_x = _chunkSize.x * tileSize.x
			var rect_size_y = _chunkSize.y * tileSize.y
			var rect_size = Vector2(rect_size_x, rect_size_y)
			var chunkBounds = Rect2(chunkWorldPosition, rect_size)
			if chunkBounds.has_point(current_position):
				return true
	return false

func is_position_inside_chunk(current_position, chunkPosition):
	var tileSize = _tileSet.tile_size
	var chunkWorldPosition_x = chunkPosition.x * _chunkSize.x * tileSize.x
	var chunkWorldPosition_y = chunkPosition.y * _chunkSize.y * tileSize.y
	var chunkWorldPosition = Vector2(chunkWorldPosition_x, chunkWorldPosition_y)
	var rect_size_x = _chunkSize.x * tileSize.x
	var rect_size_y = _chunkSize.y * tileSize.y
	var rect_size = Vector2(rect_size_x, rect_size_y)
	var chunkBounds = Rect2(chunkWorldPosition, rect_size)
	return chunkBounds.has_point(current_position)

func get_tile_position(current_position):
	var tileSize = _tileSet.tile_size
	var chunkPosition = get_chunk_position(current_position)
	var chunkWorldPosition_x = chunkPosition.x * _chunkSize.x * tileSize.x
	var chunkWorldPosition_y = chunkPosition.y * _chunkSize.y * tileSize.y
	var chunkWorldPosition = Vector2(chunkWorldPosition_x, chunkWorldPosition_y)
	var localPosition = current_position - chunkWorldPosition
	return Vector2(int(localPosition.x / tileSize.x), int(localPosition.y / tileSize.y))

func get_tile_world_position(current_position, chunkPosition):
	var tileSize = _tileSet.tile_size
	var chunkWorldPosition_x = chunkPosition.x * _chunkSize.x * tileSize.x
	var chunkWorldPosition_y = chunkPosition.y * _chunkSize.y * tileSize.y
	var chunkWorldPosition = Vector2(chunkWorldPosition_x, chunkWorldPosition_y)
	return chunkWorldPosition + Vector2(current_position.x * tileSize.x, current_position.y * tileSize.y)
