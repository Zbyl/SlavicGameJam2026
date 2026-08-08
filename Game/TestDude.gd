extends CharacterBody2D

@export var level: Node2D
var tile_map_layers: Array[TileMapLayer] = []
@export var debugLabel: Label


const SPEED = 6000.0
const JUMP_VELOCITY = 200.0

var gravity: float = 400.0
var layerHeight: float = 40.0
var zToYOffsetRatio: float = 1.0 # Multiply z by this much to get y offset. But note that Z goes up, but y goes down.

var currentZ: float = 0.0
var velocityZ: float = 0.0

# Returns tilemap for layer or null if this layer doesn't have a tilemap.
func getTileMapForLayer(layer: int) -> TileMapLayer:
    if layer < 0:
        return null
    if layer >= tile_map_layers.size():
        return null
    return tile_map_layers[layer]

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

func _ready():
    for i in range(100):
        var tileMapName = "TileMapLayer{idx}".format({"idx": i})
        var tileMap: TileMapLayer = level.get_node_or_null(tileMapName)
        if not tileMap:
            break
        tile_map_layers.append(tileMap)
    
    print(tileOffsetToPlanarOffset(Vector2(-40, 0)))
    print(Vector2(0, 0))
    print(tileOffsetToPlanarOffset(Vector2(0, -20)))
    print(Vector2(0, 1))
    print(tileOffsetToPlanarOffset(Vector2(40, 0)))
    print(Vector2(1, 1))
    print(tileOffsetToPlanarOffset(Vector2(0, 20)))
    print(Vector2(1, 0))
    print(tileOffsetToPlanarOffset(Vector2(0, 0)))
    print(Vector2(0.5, 0.5))

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
    var yOffsetFromZ := zToYOffsetRatio * z
    var correctedPosition := Vector2(globalPosition2d.x, globalPosition2d.y + yOffsetFromZ)
    var tile_map_layer_0 := getTileMapForLayer(0)
    var localCoords := tile_map_layer_0.to_local(correctedPosition)
    var mapCoords := tile_map_layer_0.local_to_map(localCoords)
    var tileLocalCoords := tile_map_layer_0.map_to_local(mapCoords)
    var offsetWithinTile := localCoords - tileLocalCoords
    var planarOffsetWithinTile := tileOffsetToPlanarOffset(offsetWithinTile)
    return MapPositionInfo.new(mapCoords, offsetWithinTile, planarOffsetWithinTile)
    
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
    return groundInfoFromMapPositionRaw(mapPosition, z + groundEpsilon)

# Returns slopeGroundHeight (absolute), or null if not on slope.
func slopeGroundHeight(mapCoords: Vector2i, planarOffsetWithinTile: Vector2, layer: int) -> Variant: # float or null
    var tileMap = getTileMapForLayer(layer)
    if not isSlope(tileMap, mapCoords):
        return null
    var groundHeight := planarOffsetWithinTile.y * layerHeight + (layer - 1) * layerHeight
    return groundHeight

enum OnSlope {
    NO = 0,             # Not on slope.
    GOING_DOWN = 1,     # Slope is on our layer, so we are going to a layer below.
    GOING_UP = 2,       # Slope is on layer above, so we are going to a layer above.
}

func isOnSlope(mapCoords: Vector2i, feetLayer: int) -> OnSlope:
    var feetTileMapLayer := getTileMapForLayer(feetLayer)
    var aboveTileMapLayer := getTileMapForLayer(feetLayer + 1)

    if feetTileMapLayer == null:
        return OnSlope.NO
    
    if isSlope(feetTileMapLayer, mapCoords):
        return OnSlope.GOING_DOWN

    if aboveTileMapLayer and isSlope(aboveTileMapLayer, mapCoords):
        return OnSlope.GOING_UP
    
    return OnSlope.NO


func layerFromZ(z: float) -> int:
    return floori(z / layerHeight)

func _physics_process(delta: float) -> void:
    var preMapPosition := mapPositionFromScreenPosition(global_position, currentZ)
    var preGroundInfo := groundInfoFromMapPosition(preMapPosition, currentZ)

    # Add the gravity.
    var currentlyOnGround := false
    if preGroundInfo.groundType != GroundType.EMPTY:
        var distFromGround := currentZ - preGroundInfo.groundHeight
        var heightToConsiderOnGround := layerHeight / 20.0
        currentlyOnGround = distFromGround < heightToConsiderOnGround
        
    if currentlyOnGround:
        velocityZ = 0.0
    else:
        velocityZ -= gravity * delta

    # Handle jump.
    if Input.is_action_just_pressed("ui_accept") and currentlyOnGround:
        velocityZ = JUMP_VELOCITY
        currentlyOnGround = false

    var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    if direction.x:
        velocity.x = direction.x * SPEED * delta
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED * delta)

    if direction.y:
        velocity.y = direction.y * SPEED * delta / 2
    else:
        velocity.y = move_toward(velocity.y, 0, SPEED * delta)

    move_and_slide()

    var deltaZ := velocityZ * delta # @note We need to add y-offset computed from z later.
    # We don't allow falling 2 layers below, to simplify the code.
    if deltaZ > layerHeight:
        deltaZ = layerHeight
    if deltaZ < -layerHeight:
        deltaZ = -layerHeight

    var postMapPosition := mapPositionFromScreenPosition(global_position, currentZ)
    var postGroundInfo := groundInfoFromMapPosition(postMapPosition, currentZ)

    # We use collision mask from previous z. It's close enough.
    clearLayerCollisionMask()
    #setLayerCollisionMask(0, true)
    setLayerCollisionMask(postGroundInfo.layer, postGroundInfo.useThisCollision)
    setLayerCollisionMask(postGroundInfo.layer - 1, postGroundInfo.useBelowCollision)
    #z_index = postGroundInfo.layer + 1

    var movedOnGround := false
    if currentlyOnGround: # We know we did not apply gravity nor jumped.
        # If we are still on ground, glue player to the ground.
        if postGroundInfo.groundType == GroundType.SLOPE:
            movedOnGround = true
            deltaZ = postGroundInfo.groundHeight - currentZ

    currentZ += deltaZ
    global_position.y -= deltaZ * zToYOffsetRatio

    #debugLabel.text = "gravity={gravity} delta={delta} velocityZ={velocityZ} onGround={onGround} movedOnGround={movedOnGround} mapCoords={mapCoords} currentZ={currentZ}".\
    #    format({"gravity": gravity, "delta": delta, "velocityZ": velocityZ, "onGround": currentlyOnGround, "movedOnGround": movedOnGround, "mapCoords": postMapPosition.mapCoords, "currentZ": currentZ})

func setLayerCollisionMask(layer: int, value: bool) -> void:
    if (layer >= 0) and (layer < 16):
        set_collision_mask_value(17 + layer, value)

func clearLayerCollisionMask() -> void:
    for layer in range(16):
        setLayerCollisionMask(layer, false)
