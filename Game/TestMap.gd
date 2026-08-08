extends Node2D

@export var level: Node2D

# Empty tile Level0 is in source 1, tile 23,0
# Empty tile Level1 is in source 1, tile 0,2
var block_tiles: Array[Vector3i] = [
    Vector3i(0, 0, 1),
    Vector3i(0, 2, 1),
    Vector3i(0, 4, 1),
    Vector3i(0, 6, 1),
    Vector3i(0, 8, 1),
    Vector3i(0, 10, 1),
    Vector3i(0, 12, 1),
    Vector3i(0, 14, 1),
]

func make_boundaries(tileMapLayer: TileMapLayer, blockTile: Vector3i):
    var filled_tiles := tileMapLayer.get_used_cells()
    for filled_tile: Vector2i in filled_tiles:
        var neighboring_tiles := tileMapLayer.get_surrounding_cells(filled_tile)
        for neighbour: Vector2i in neighboring_tiles:
            if tileMapLayer.get_cell_source_id(neighbour) == -1:
                tileMapLayer.set_cell(neighbour, blockTile.z, Vector2i(blockTile.x, blockTile.y))

func make_blocks(tileMapLower: TileMapLayer, tileMapAbove: TileMapLayer, blockTileLower: Vector3i):
    var filled_tiles := tileMapAbove.get_used_cells()
    for filled_tile: Vector2i in filled_tiles:
        var tile_data = tileMapAbove.get_cell_tile_data(filled_tile)
        if tile_data:
            var slope = tile_data.get_custom_data("Slope")
            if slope:
                continue

        #if tileMapLower.get_cell_source_id(filled_tile) != -1:
        tileMapLower.set_cell(filled_tile, blockTileLower.z, Vector2i(blockTileLower.x, blockTileLower.y))

#@onready var tile_map_layer_0: TileMapLayer = $TileMapLayer0
#@onready var tile_map_layer_1: TileMapLayer = $TileMapLayer1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    #make_boundaries(tile_map_layer_0)
    #make_boundaries(tile_map_layer_1)
    var tile_map_layer_0: TileMapLayer = level.get_node("TileMapLayer0")
    var previousLayer: TileMapLayer = tile_map_layer_0
    for i in range(100):
        var tileMapName = "TileMapLayer{idx}".format({"idx": i + 1})
        var currentLayer: TileMapLayer = level.get_node_or_null(tileMapName)
        if not currentLayer:
            break
        make_blocks(previousLayer, currentLayer, block_tiles[i])
        previousLayer = currentLayer


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass
