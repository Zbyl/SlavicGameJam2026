extends Node2D

# Empty tile Level0 is in source 3, tile 9,0
# Empty tile Level1 is in source 3, tile 10,0
var block_tile_level0: Vector3i = Vector3i(9, 0, 3)
var block_tile_level1: Vector3i = Vector3i(10, 0, 3)

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

@onready var tile_map_layer_0: TileMapLayer = $TileMapLayer0
@onready var tile_map_layer_1: TileMapLayer = $TileMapLayer1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    #make_boundaries(tile_map_layer_0)
    #make_boundaries(tile_map_layer_1)
    make_blocks(tile_map_layer_0, tile_map_layer_1, block_tile_level0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass
