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

@onready var baseImage: Node2D = $Kunek # Image of Boguś. Will be moved relative to CollisionShape to simulate jumping.
@onready var outlineImage: Node2D = $Outline # Outline of Boguś.
var baseImageOffsetY: float = 0.0
var outlineImageOffsetY: float = 0.0

var layerHeight: float = 40.0
var zToYOffsetRatio: float = 1.0 # Multiply z by this much to get y offset. But note that Z goes up, but y goes down.

var currentZ: float = 0.0
var velocityZ: float = 0.0

var game: Game

func _ready() -> void:
    game = GameData.game
    baseImageOffsetY = baseImage.offset.y
    outlineImageOffsetY = outlineImage.offset.y
    #debugLabel = get_node("../../%DebugLabel")

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

    var preMapPosition := GameData.layerHelpers.mapPositionFromScreenPosition(global_position, currentZ)
    var preGroundInfo := GameData.layerHelpers.groundInfoFromMapPosition(preMapPosition, currentZ)

    # Add the gravity.
    var currentlyOnGround := false
    if preGroundInfo.groundType != LayerHelpers.GroundType.EMPTY:
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

    var postMapPosition := GameData.layerHelpers.mapPositionFromScreenPosition(global_position, currentZ)
    var postGroundInfo := GameData.layerHelpers.groundInfoFromMapPosition(postMapPosition, currentZ)

    var movedOnGround := false
    if currentlyOnGround: # We know we did not apply gravity nor jumped.
        # If we are still on ground, glue player to the ground.
        if postGroundInfo.groundType != LayerHelpers.GroundType.EMPTY:
            movedOnGround = true
            deltaZ = postGroundInfo.groundHeight - currentZ

    currentZ += deltaZ
    
    global_position = GameData.layerHelpers.screenPositionFromMapPosition(postMapPosition.mapCoords, postMapPosition.offsetWithinTile, currentZ)
    var curLayer := GameData.layerHelpers.layerFromZ(currentZ)
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

    if debugLabel != null:
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

# Calculated global_position shifted up using image offset to give screen position of Kunek.
func positionOfKunek() -> Vector2:
    var mapPosition := GameData.layerHelpers.mapPositionFromScreenPosition(global_position, currentZ)
    var screenPosition := GameData.layerHelpers.screenPositionFromMapPosition(mapPosition.mapCoords, mapPosition.offsetWithinTile, 0)
    return screenPosition + Vector2(0, -currentZ * zToYOffsetRatio)
    #var imageOffset = baseImage.offset.y - baseImageOffsetY
    #return global_position + Vector2(0, imageOffset)
    
func setLayerCollisionMask(layer: int, value: bool) -> void:
    if (layer >= 0) and (layer < 16):
        set_collision_mask_value(17 + layer, value)

func clearLayerCollisionMask() -> void:
    for layer in range(16):
        setLayerCollisionMask(layer, false)
