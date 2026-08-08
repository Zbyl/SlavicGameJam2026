extends Node
class_name LayerHelpers

var layerHeight: float = 40.0
var zToYOffsetRatio: float = 1.0 # Multiply z by this much to get y offset. But note that Z goes up, but y goes down.

var tile_map_layers: Array[TileMapLayer] = []  # Used by level preprocessing, Dudes and Shadow.
var collision_map_layers: Array[TileMapLayer] = []  # Used by level preprocessing.
var spawnPoints: Array[Vector3] = [] # @note Order of spawn points does not correspond to names inside Level.

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

# Unused
func _unused_make_boundaries(tileMapLayer: TileMapLayer, blockTile: Vector3i):
    var filled_tiles := tileMapLayer.get_used_cells()
    for filled_tile: Vector2i in filled_tiles:
        var neighboring_tiles := tileMapLayer.get_surrounding_cells(filled_tile)
        for neighbour: Vector2i in neighboring_tiles:
            if tileMapLayer.get_cell_source_id(neighbour) == -1:
                tileMapLayer.set_cell(neighbour, blockTile.z, Vector2i(blockTile.x, blockTile.y))

# blockTileLower - block tile to use for collisionMapLower.
#                  (Each collision map needs a block with appropriate collision layer.)
func make_blocks(collisionMapLower: TileMapLayer, tileMapAbove: TileMapLayer, blockTileLower: Vector3i):
    var filled_tiles := tileMapAbove.get_used_cells()
    for filled_tile: Vector2i in filled_tiles:
        var tile_data = tileMapAbove.get_cell_tile_data(filled_tile)
        if tile_data:
            var slope = tile_data.get_custom_data("Slope")
            if slope:
                continue

        collisionMapLower.set_cell(filled_tile, blockTileLower.z, Vector2i(blockTileLower.x, blockTileLower.y))


func initTileMaps(level: Node2D):
    tile_map_layers = []
    collision_map_layers = []
    for i in range(100):
        var tileMapName = "TileMapLayer{idx}".format({"idx": i})
        var collisionMapName = "CollisionLayer{idx}".format({"idx": i})
        var tileMap: TileMapLayer = level.get_node_or_null(tileMapName)
        var collisionMap: TileMapLayer = level.get_node_or_null(collisionMapName)
        if not tileMap:
            break
        assert(collisionMap, "Collision map missing")
        tile_map_layers.append(tileMap)
        collision_map_layers.append(collisionMap)

    # Load spawn points
    var spawnPointMarkers: Array[Node] = level.get_tree().get_nodes_in_group('SpawnPoint')
    spawnPoints = []
    for spawnPointMarker in spawnPointMarkers:
        var spawnParentName = spawnPointMarker.get_parent().name
        assert(spawnParentName.substr(0, "TileMapLayer".length()) == "TileMapLayer", "Invalid spawn parent name")
        var idxStr = spawnParentName.substr("TileMapLayer".length())
        var layer = int(idxStr)
        var spawnPoint := Vector3(spawnPointMarker.global_position.x, spawnPointMarker.global_position.y, layer * layerHeight)
        spawnPoints.append(spawnPoint)

    assert(spawnPoints.size() == 4, "Must have 4 spawn points in a level: {spawnPoints}".format({"spawnPoints": spawnPoints}))

    # Generate collisions
    for i in range(100):
        var currentLayer: TileMapLayer = getTileMapForLayer(i + 1)
        var previousCollisionLayer: TileMapLayer = getCollisionMapForLayer(i)
        if not currentLayer:
            break
        make_blocks(previousCollisionLayer, currentLayer, block_tiles[i])

# Returns tilemap for layer or null if this layer doesn't have a tilemap.
func getTileMapForLayer(layer: int) -> TileMapLayer:
    if layer < 0:
        return null
    if layer >= tile_map_layers.size():
        return null
    return tile_map_layers[layer]

# Returns collision tilemap for layer or null if this layer doesn't have a tilemap.
func getCollisionMapForLayer(layer: int) -> TileMapLayer:
    if layer < 0:
        return null
    if layer >= collision_map_layers.size():
        return null
    return collision_map_layers[layer]

########################################################################
# 3D movement stuff

func layerFromZ(z: float) -> int:
    return floori(z / layerHeight)

func isSlope(tileMapLayer: TileMapLayer, mapCoords: Vector2i) -> bool:
    if tileMapLayer == null:
        return false

    if tileMapLayer.get_cell_source_id(mapCoords) == -1:
        return false

    var tile_data = tileMapLayer.get_cell_tile_data(mapCoords)
    if not tile_data:
        return false

    var slope = tile_data.get_custom_data("Slope")
    return slope

# Returns true if given tile is not empty.
func isSolidTile(tileMapLayer: TileMapLayer, mapCoords: Vector2i) -> bool:
    if tileMapLayer == null:
        return false

    if tileMapLayer.get_cell_source_id(mapCoords) == -1:
        return false

    return true

enum GroundType { EMPTY, SOLID, SLOPE }

class MapPositionInfo:
    var mapCoords: Vector2i
    var offsetWithinTile: Vector2
    var planarOffsetWithinTile: Vector2 # See tileOffsetToPlanarOffset().

    func _init(_mapCoords: Vector2i, _offsetWithinTile: Vector2, _planarOffsetWithinTile: Vector2):
        self.mapCoords = _mapCoords
        self.offsetWithinTile = _offsetWithinTile
        self.planarOffsetWithinTile = _planarOffsetWithinTile


class GroundInfo:
    var layer: int
    var tileMap: TileMapLayer
    var groundType: GroundType # When SLOPE layer and tileMap will contain the tileMap with slope.
    var groundHeight: float # Absolute ground height on this layer. Meaningless ifnot solid or slope.

    var useThisCollision: bool    # Use collision from this tilemap (so above the slope)
    var useBelowCollision: bool   # Use collision from tilemap below (so below the slope)

    func _init(_layer: int, _tileMap: TileMapLayer, _groundType: GroundType, _groundHeight: float, _useThisCollision: bool, _useBelowCollision: bool):
        self.layer = _layer
        self.tileMap = _tileMap
        self.groundType = _groundType
        self.groundHeight = _groundHeight
        self.useThisCollision = _useThisCollision
        self.useBelowCollision = useBelowCollision

# tileOffset - screen offset from the center of the tile (assuming z == 0)
#         /\ 0,-20
#       /    \
#-40,0/        \ 40,0
#     \        /
#       \    /
#         \/ 0,20
# Returns position on the flat plane.
#       /\ 0,1
#     /    \
#0,0/        \ 1,1
#   \        /
#     \    /
#       \/ 1,0
func tileOffsetToPlanarOffset(tileOffset: Vector2) -> Vector2:
    var unskewedOffset := Vector2(tileOffset.x, tileOffset.y * 2) / 40.0
    var sincos = 1.0 #sqrt(2.0) / 2.0
    var rotated := Vector2(unskewedOffset.x * sincos + unskewedOffset.y * sincos, unskewedOffset.x * sincos - unskewedOffset.y * sincos)
    return Vector2(rotated.x + 1, rotated.y + 1) / 2

# Position 2D is expected to already contain offset corresponding to z.
func mapPositionFromScreenPosition(globalPosition2d: Vector2, z: float) -> MapPositionInfo:
    var layer := layerFromZ(z)
    var yOffsetFromZ := layer * layerHeight * zToYOffsetRatio
    var correctedPosition := Vector2(globalPosition2d.x, globalPosition2d.y + yOffsetFromZ)
    var tile_map_layer_0 := getTileMapForLayer(0)
    var localCoords := tile_map_layer_0.to_local(correctedPosition)
    var mapCoords := tile_map_layer_0.local_to_map(localCoords)
    var tileLocalCoords := tile_map_layer_0.map_to_local(mapCoords)
    var offsetWithinTile := localCoords - tileLocalCoords
    var planarOffsetWithinTile := tileOffsetToPlanarOffset(offsetWithinTile)
    return MapPositionInfo.new(mapCoords, offsetWithinTile, planarOffsetWithinTile)

func screenPositionFromMapPosition(mapCoords: Vector2i, offsetWithinTile: Vector2, z: float) -> Vector2:
    var layer := layerFromZ(z)
    var tile_map_layer_0 := getTileMapForLayer(0)
    var mapLocalCoords = tile_map_layer_0.map_to_local(mapCoords) + offsetWithinTile
    var globalCoords = tile_map_layer_0.to_global(mapLocalCoords)
    var yOffsetFromZ :=  layer * layerHeight * zToYOffsetRatio
    globalCoords.y = globalCoords.y - yOffsetFromZ
    return globalCoords

func groundInfoFromMapPositionRaw(mapPosition: MapPositionInfo, z: float) -> GroundInfo:
    var layer := layerFromZ(z)
    var tileMap = getTileMapForLayer(layer)
    var tileMapAbove = getTileMapForLayer(layer + 1)
    var groundType: GroundType = GroundType.EMPTY
    var groundHeight: float = 0.0
    if isSlope(tileMap, mapPosition.mapCoords):
        groundType = GroundType.SLOPE
        groundHeight = slopeGroundHeight(mapPosition.mapCoords, mapPosition.planarOffsetWithinTile, layer)
    elif isSlope(tileMapAbove, mapPosition.mapCoords):
        groundType = GroundType.SLOPE
        groundHeight = slopeGroundHeight(mapPosition.mapCoords, mapPosition.planarOffsetWithinTile, layer + 1)
        layer = layer + 1
        tileMap = tileMapAbove
    elif isSolidTile(tileMap, mapPosition.mapCoords):
        groundType = GroundType.SOLID
        groundHeight = layer * layerHeight

    var useThisCollision := false
    var useBelowCollision := false
    if groundType == GroundType.SLOPE:
        var onSlopeHeight := groundHeight - layer * layerHeight
        useThisCollision = onSlopeHeight > (layerHeight * 0.75)
        useBelowCollision = onSlopeHeight < (layerHeight * 0.25)
    if groundType == GroundType.SOLID:
        useThisCollision = true
        useBelowCollision = false
    return GroundInfo.new(layer, tileMap, groundType, groundHeight, useThisCollision, useBelowCollision)

# Return information about ground on z, but if ground is right above z, return that instead.
func groundInfoFromMapPosition(mapPosition: MapPositionInfo, z: float) -> GroundInfo:
    var groundEpsilon := layerHeight / 20
    var groundAbove := groundInfoFromMapPositionRaw(mapPosition, z + groundEpsilon)
    if groundAbove.groundType != GroundType.EMPTY:
        return groundAbove
    return groundInfoFromMapPositionRaw(mapPosition, z)


# Returns slopeGroundHeight (absolute), or null if not on slope.
func slopeGroundHeight(mapCoords: Vector2i, planarOffsetWithinTile: Vector2, layer: int) -> Variant: # float or null
    var tileMap = getTileMapForLayer(layer)
    if not isSlope(tileMap, mapCoords):
        return null
    var groundHeight := planarOffsetWithinTile.y * layerHeight + (layer - 1) * layerHeight
    return groundHeight

# Returns heights of all grounds on given map coordinates. Sorted from bottom to top.
# If nothing elso would be found one element equal to zero is returned.
func allGroundHeightsInPosition(mapCoords: Vector2i, planarOffsetWithinTile: Vector2) -> Array[float]:
    var grounds: Array[float] = []
    for layer in range(tile_map_layers.size()):
        var tileMap := getTileMapForLayer(layer)
        if isSolidTile(tileMap, mapCoords):
            grounds.append(layer * layerHeight)
            continue
        if isSlope(tileMap, mapCoords):
            grounds.append(slopeGroundHeight(mapCoords, planarOffsetWithinTile, layer))
            continue

    if grounds.size() == 0:
        grounds = [0.0]

    return grounds

# Returs height of the highest ground below or equal to given z.
# If z is < 0 will return 0.
func groundHeightBelow(mapCoords: Vector2i, planarOffsetWithinTile: Vector2, z: float) -> float:
    var grounds := allGroundHeightsInPosition(mapCoords, planarOffsetWithinTile)
    var lastLowerGround := 0.0
    for ground in grounds:
        if ground <= z:
            lastLowerGround = z
    return lastLowerGround

# Returns all ground heights between, and including, lower and upper z. Sorted ascending.
# Can return an empty array.
func groundHeightsBeetweenZs(mapCoords: Vector2i, planarOffsetWithinTile: Vector2, lowerZ: float, upperZ: float) -> Array[float]:
    var grounds := allGroundHeightsInPosition(mapCoords, planarOffsetWithinTile)
    var beetweenGrounds: Array[float] = []
    for ground in grounds:
        if (ground >= lowerZ) and (ground <= upperZ):
            beetweenGrounds.append(ground)
    return beetweenGrounds
