extends CharacterBody2D
class_name Dude

const DEADZONE = 0.1
const ACCELERATION_FACTOR = 700
const DECELERATION_FACTOR = 2*ACCELERATION_FACTOR
const WORLD_ASPECT_FACTOR = 0.5

@export var speed: float = 300.0
@export var character: String = "Fox"
@export var controller: int = 0
@export var jumpButton = JOY_BUTTON_A
@export var isBerek: bool = false

const JUMP_VELOCITY: float = 200.0
var gravity: float = 400.0

var currentAngle: int = 8 # 1 to 8,  1 - SW, 2 - W, ..., 8 - S
var currentState: String = "None"
#  - None - unused, invalid
#  - Idle
#  - Die
#  - Jump
#  - Dir - running (Dir name is used because animations are named Dir)

@onready var animation: AnimatedSprite2D = $Kunek
@onready var outline: AnimatedSprite2D = $Outline
@onready var berek: AnimatedSprite2D = $Berek
@onready var timer: Timer = $Timer
@onready var run_player: AudioStreamPlayer2D = $RunPlayer
@onready var jump_player: AudioStreamPlayer2D = $JumpPlayer
@onready var die_player: AudioStreamPlayer2D = $DiePlayer
@onready var respawn_player: AudioStreamPlayer2D = $RespawnPlayer
@onready var streams = [
    load("res://Sounds/Kunek/FoxRun.wav"),
    load("res://Sounds/Kunek/FerretRun.wav"),
    load("res://Sounds/Kunek/WeaselRun.wav"),
    load("res://Sounds/Kunek/SnowRun.wav")
]
var run_stream: AudioStream


@export var debugLabel: Label

# @todo Move to some Level/Game thingy.
@export var level: Node2D
var tile_map_layers: Array[TileMapLayer] = []

@onready var baseImage: Node2D = $Kunek # Image of Boguś. Will be moved relative to CollisionShape to simulate jumping.
@onready var outlineImage: Node2D = $Outline # Outline of Boguś.
var baseImageOffsetY: float = 0.0
var outlineImageOffsetY: float = 0.0

var layerHeight: float = 40.0
var zToYOffsetRatio: float = 1.0 # Multiply z by this much to get y offset. But note that Z goes up, but y goes down.

var currentZ: float = 0.0
var velocityZ: float = 0.0


func _ready() -> void:
    baseImageOffsetY = baseImage.offset.y
    outlineImageOffsetY = outlineImage.offset.y
    #debugLabel = get_node("../../%DebugLabel")
    # @todo Move to some Level/Game thingy.
    for i in range(100):
        var tileMapName = "TileMapLayer{idx}".format({"idx": i})
        var tileMap: TileMapLayer = level.get_node_or_null(tileMapName)
        if not tileMap:
            break
        tile_map_layers.append(tileMap)

    setBerek(isBerek)
    if character == "Fox":
        run_stream = streams[0]
    elif character == "Ferret":
        run_stream = streams[1]
    elif character == "Weasel":
        run_stream = streams[2]
    elif character == "Snow":
        run_stream = streams[3]
    run_player.stream = run_stream

func setBerek(state: bool):
    isBerek = state
    if isBerek:
        add_to_group("Berek")
    else:
        remove_from_group("Berek")
    berek.visible = isBerek

func calculateInputDirection() -> Vector2:
    var x = Input.get_joy_axis(controller, JOY_AXIS_LEFT_X)
    var y = Input.get_joy_axis(controller, JOY_AXIS_LEFT_Y)
    var dir = Vector2(x, y)
    if dir.length() < DEADZONE:
        dir = Vector2.ZERO
    return dir

func isJumpButtonPressed() -> bool:
    return Input.is_joy_button_pressed(controller, jumpButton)

func calculateState(dir: Vector2, isJump: bool) -> String:
    if currentState=="Die":
        return "Die"
    elif isJump:
        return "Jump"
    elif currentState=="Jump":
        return "Jump"
    elif dir == Vector2.ZERO:
        return "Idle"
    else:
        return "Dir"

func resetState():
    if currentState == "Die":
        get_tree().call_group("Berek", "setBerek", false)
        respawn_player.play()
        setBerek(true)
    currentState="None"

func calculateAngle(dir: Vector2) -> int:
    var angle = roundi((rad_to_deg(atan2(dir.y, dir.x))+270.0)/45.0)
    if angle<1:
        angle += 8
    if angle>8:
        angle -= 8
    return angle

func syncAnimations():
    outline.animation="Outline"+animation.animation
    outline.frame=animation.frame

func _physics_process(delta: float):
    var direction = calculateInputDirection()
    #var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

    var isJump = isJumpButtonPressed()
    #var isJump = Input.is_action_just_pressed("ui_accept")

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
    if isJump and currentlyOnGround:
        velocityZ = JUMP_VELOCITY
        currentlyOnGround = false

    # Ustawienie prędkości
    if direction == Vector2.ZERO:
        velocity = velocity.move_toward(Vector2.ZERO, delta*DECELERATION_FACTOR)
    else:
        velocity = velocity.move_toward(direction * Vector2(speed, speed * WORLD_ASPECT_FACTOR), delta*ACCELERATION_FACTOR)

    move_and_slide()

    var deltaZ := velocityZ * delta # @note We need to add y-offset computed from z later.
    # We don't allow falling 2 layers below, to simplify the code.
    deltaZ = clamp(deltaZ, -layerHeight, layerHeight)

    var postMapPosition := mapPositionFromScreenPosition(global_position, currentZ)
    var postGroundInfo := groundInfoFromMapPosition(postMapPosition, currentZ)

    var movedOnGround := false
    if currentlyOnGround: # We know we did not apply gravity nor jumped.
        # If we are still on ground, glue player to the ground.
        if postGroundInfo.groundType != GroundType.EMPTY:
            movedOnGround = true
            deltaZ = postGroundInfo.groundHeight - currentZ

    currentZ += deltaZ
    
    global_position = screenPositionFromMapPosition(postMapPosition.mapCoords, postMapPosition.offsetWithinTile, currentZ)
    var curLayer := layerFromZ(currentZ)
    baseImage.offset.y = baseImageOffsetY - (currentZ - curLayer * layerHeight) * zToYOffsetRatio / baseImage.scale.y
    outlineImage.offset.y = outlineImageOffsetY - (currentZ - curLayer * layerHeight) * zToYOffsetRatio / outlineImage.scale.y
    #image.position.y += (curLayer - prevLayer) * layerHeight * zToYOffsetRatio

    # We use collision mask from previous z. It's close enough.
    clearLayerCollisionMask()
    setLayerCollisionMask(curLayer, true)
    #setLayerCollisionMask(postGroundInfo.layer, postGroundInfo.useThisCollision)
    #setLayerCollisionMask(postGroundInfo.layer - 1, postGroundInfo.useBelowCollision)
    z_index = postGroundInfo.layer + 1
    #z_index = 1

    # State changes and animation handling.

    var changeAnimation = false
    var state = calculateState(direction, isJump)

    if state != currentState:
        currentState = state
        if state == "Jump": # this is temporary solution for canceling jump
            timer.wait_time = 0.5;
            timer.start()
            jump_player.play()

        if state == "Dir":
            run_player.play()
        else:
            run_player.stop()

        changeAnimation = true

    if direction != Vector2.ZERO:

        var angle = calculateAngle(direction)
        if angle != currentAngle:
            currentAngle = angle
            changeAnimation = true

    if changeAnimation:
        animation.play(character+currentState+str(currentAngle))

    syncAnimations()

    debugLabel.text = "imageOffset={imageOffset} z_index={z_index} gravity={gravity} deltaZ={deltaZ} velocityZ={velocityZ}\nonGround={onGround} movedOnGround={movedOnGround} mapCoords={mapCoords} currentZ={currentZ}".\
        format({"imageOffset": baseImage.offset.y - baseImageOffsetY, "z_index": z_index, "gravity": gravity, "deltaZ": deltaZ, "velocityZ": velocityZ, "onGround": currentlyOnGround, "movedOnGround": movedOnGround, "mapCoords": postMapPosition.mapCoords, "currentZ": currentZ})


func _on_area_2d_body_entered(body: Node2D) -> void:
    if !is_in_group("Berek") && body.is_in_group("Berek"):
        body.setBerek(false)

        print("I'm dying!")

        die_player.play()
        currentState="Die"
        animation.play(character+currentState+str(currentAngle))
        syncAnimations()
        timer.wait_time = 2.0;
        timer.start()


########################################################################
# 3D movement stuff

func layerFromZ(z: float) -> int:
    return floori(z / layerHeight)

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
    
# Calculated global_position shifted up using image offset to give screen position of Kunek.
func positionOfKunek() -> Vector2:
    var mapPosition := mapPositionFromScreenPosition(global_position, currentZ)
    var screenPosition := screenPositionFromMapPosition(mapPosition.mapCoords, mapPosition.offsetWithinTile, 0)
    return screenPosition + Vector2(0, -currentZ * zToYOffsetRatio)
    #var imageOffset = baseImage.offset.y - baseImageOffsetY
    #return global_position + Vector2(0, imageOffset)
    
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

func setLayerCollisionMask(layer: int, value: bool) -> void:
    if (layer >= 0) and (layer < 16):
        set_collision_mask_value(17 + layer, value)

func clearLayerCollisionMask() -> void:
    for layer in range(16):
        setLayerCollisionMask(layer, false)
