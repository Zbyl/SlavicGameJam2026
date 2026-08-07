extends CharacterBody2D

@export var tile_map_layer_0: TileMapLayer
@export var tile_map_layer_1: TileMapLayer
@export var debugLabel: Label


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@export var currentLayer: int = 0

enum OnSlope {
    NO = 0,             # Not on slope.
    GOING_DOWN = 1,     # Slope is on our layer, so we are going to a layer below.
    GOING_UP = 2,       # Slope is on layer above, so we are going to a layer above.
}


func isSlope(tileMapLayer: TileMapLayer, pos: Vector2i) -> bool:
    if tileMapLayer.get_cell_source_id(pos) == -1:
        return false
        
    var tile_data = tileMapLayer.get_cell_tile_data(pos)
    if not tile_data:
        return false
        
    var slope = tile_data.get_custom_data("Slope")
    return slope


func isOnSlope() -> OnSlope:
    var feetTileMapLayer: TileMapLayer = null
    var aboveTileMapLayer: TileMapLayer = null
    
    if currentLayer == 0:
        feetTileMapLayer = tile_map_layer_0
        aboveTileMapLayer = tile_map_layer_1
    elif currentLayer == 1:
        feetTileMapLayer = tile_map_layer_1
        aboveTileMapLayer = null

    if feetTileMapLayer == null:
        return OnSlope.NO
    
    var localCoords = feetTileMapLayer.to_local(global_position)
    var mapCoords = feetTileMapLayer.local_to_map(localCoords)

    if isSlope(feetTileMapLayer, mapCoords):
        return OnSlope.GOING_DOWN

    if aboveTileMapLayer and isSlope(aboveTileMapLayer, mapCoords):
        return OnSlope.GOING_UP
    
    return OnSlope.NO


func isOnGround() -> bool:
    var feetTileMapLayer: TileMapLayer = null
    
    if currentLayer == 0:
        feetTileMapLayer = tile_map_layer_0
    elif currentLayer == 1:
        feetTileMapLayer = tile_map_layer_1

    if feetTileMapLayer == null:
        return false
    
    var localCoords = feetTileMapLayer.to_local(global_position)
    var mapCoords = feetTileMapLayer.local_to_map(localCoords)

    if feetTileMapLayer.get_cell_source_id(mapCoords) == -1:
        return false
    
    return true


func _physics_process(delta: float) -> void:
    # Add the gravity.
    #if not is_on_floor():
    #    velocity += get_gravity() * delta

    # Handle jump.
    if Input.is_action_just_pressed("ui_accept") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    # Get the input direction and handle the movement/deceleration.
    # As good practice, you should replace UI actions with custom gameplay actions.
    var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    if direction.x:
        velocity.x = direction.x * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)

    if direction.y:
        velocity.y = direction.y * SPEED
    else:
        velocity.y = move_toward(velocity.y, 0, SPEED)

    move_and_slide()
    
    var onSlope := isOnSlope()
    var onGround := isOnGround()
    
    debugLabel.text = "onSlope={onSlope} onGround={onGround} currentLayer={currentLayer}".format({"onSlope": onSlope, "onGround": onGround, "currentLayer": currentLayer})
    
    if onSlope == OnSlope.NO:
        if not onGround:
            currentLayer -= 1
            position.y += 16
        clearLayerCollisionMask()
        setLayerCollisionMask(currentLayer, true)
    if onSlope == OnSlope.GOING_UP:
        currentLayer += 1
        position.y -= 16
        clearLayerCollisionMask()
        setLayerCollisionMask(currentLayer, true)
    if onSlope == OnSlope.GOING_DOWN:
        clearLayerCollisionMask()
        setLayerCollisionMask(currentLayer, true)

func setLayerCollisionMask(layer: int, value: bool) -> void:
    set_collision_mask_value(17 + layer, value)

func clearLayerCollisionMask() -> void:
    for layer in range(16):
        setLayerCollisionMask(layer, false)
