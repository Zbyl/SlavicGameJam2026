extends CharacterBody2D
class_name Dude

const DEADZONE = 0.1
const ACCELERATION_FACTOR = 700.0
const BEREK_ACCELERATION_FACTOR = ACCELERATION_FACTOR * 1.3
const DECELERATION_FACTOR = 2*ACCELERATION_FACTOR
const WORLD_ASPECT_FACTOR = 0.5

const MAX_SPEED: float = 450.0
const BEREK_MAX_SPEED: float = MAX_SPEED * 1.3

@export var character: GameData.Character = GameData.Character.Fox

var controllerData : Dictionary

const JUMP_VELOCITY: float = 300.0
var gravity: float = 800.0

const JUMP_BUFFER_TIME: int = 150 # How much time before landing can we push jump button. In milliseconds.
var lastTimeJumpPressed: int = 0 # Last time we pressed the jump button. In milliseconds.
const COYOTE_TIME: int = 100 # How much time after loosing ground can we jump. In milliseconds.
var lastTimeOnTheGround: int = 0 # Last time we touched the ground. In milliseconds.

var currentAngle: int = 8 # 1 to 8,  1 - SW, 2 - W, ..., 8 - S

enum DudeState {
    Idle,
    Dead,
    Jump,           # Just jumped.
    Falling,        # In air.
    Running,        # Running.
}
var currentState: DudeState = DudeState.Idle

@onready var animation: AnimatedSprite2D = $Kunek
@onready var outline: AnimatedSprite2D = $Outline
@onready var berek: AnimatedSprite2D = $Berek
@onready var megaphone: Sprite2D = $Megaphone
@onready var respawnTimer: Timer = $RespawnTimer
@onready var run_player: AudioStreamPlayer2D = $RunPlayer
@onready var jump_player: AudioStreamPlayer2D = $JumpPlayer
@onready var landing_player: AudioStreamPlayer2D = $LandingPlayer
@onready var die_player: AudioStreamPlayer2D = $DiePlayer
@onready var respawn_player: AudioStreamPlayer2D = $RespawnPlayer
@onready var gotcha_player: AudioStreamPlayer2D = $GotchaPlayer
@onready var duck_player: AudioStreamPlayer2D = $DuckPlayer
#@onready var duck_cooldown: Timer = $DuckCooldown
@onready var dust: AnimatedSprite2D = $Dust
@onready var crown: Sprite2D = $Crown

@onready var streams = [
    load("res://Sounds/Kunek/FoxRun.wav"),
    load("res://Sounds/Kunek/FerretRun.wav"),
    load("res://Sounds/Kunek/WeaselRun.wav"),
    load("res://Sounds/Kunek/SnowRun.wav")
]
@onready var duckBerek = [
    load("res://Sounds/Kunek/ech.wav"),
    load("res://Sounds/Kunek/jestem_straszny.wav"),
    load("res://Sounds/Kunek/rrrrr.wav"),
    load("res://Sounds/Kunek/lasice_sa_szybkie.wav"),
    load("res://Sounds/Kunek/lapie.wav")
]
@onready var duck = [
    load("res://Sounds/Kunek/hi_hi.wav"),
    load("res://Sounds/Kunek/o_zaba.wav"),
    load("res://Sounds/Kunek/nie_zlapiesz_mnie.wav"),
    load("res://Sounds/Kunek/uciekam.wav")
]
var run_stream: AudioStream


@export var debugLabel: Label

@onready var baseImage: Node2D = $Kunek # Image of Boguś. Will be moved relative to CollisionShape to simulate jumping.
@onready var outlineImage: Node2D = $Outline # Outline of Boguś.
@onready var megaphoneImage: Node2D = $Megaphone # Image of Megaphone
var baseImageOffsetY: float = 0.0
var outlineImageOffsetY: float = 0.0
var megaphoneImageOffsetY: float = 0.0

var layerHeight: float = 40.0
var zToYOffsetRatio: float = 1.0 # Multiply z by this much to get y offset. But note that Z goes up, but y goes down.

var currentZ: float = 0.0
var velocityZ: float = 0.0

var game: Game

func _ready() -> void:
    game = GameData.game
    baseImageOffsetY = baseImage.offset.y
    outlineImageOffsetY = outlineImage.offset.y
    megaphoneImageOffsetY = megaphoneImage.offset.y
    #debugLabel = get_node("../../%DebugLabel")

    updateBerekMarker()
    if character == GameData.Character.Fox:
        run_stream = streams[0]
    elif character == GameData.Character.Ferret:
        run_stream = streams[1]
    elif character == GameData.Character.Weasel:
        run_stream = streams[2]
    elif character == GameData.Character.Snow:
        run_stream = streams[3]
    run_player.stream = run_stream

    # Set initial animation.
    animation.play(GameData.characterEnumToStr(character) + stateToAnim(currentState) + str(currentAngle))

func updateBerekMarker():
    var isBerek := GameData.isCharacterBerek(character)
    berek.visible = isBerek and not GameData.berekCooldownActive

func isDead():
    return currentState == DudeState.Dead

func normalizeDirection(direction: Vector2) -> Vector2:
    if direction.length() >= DEADZONE:
        direction /= direction.length()
        return direction
    else:
        return Vector2.ZERO

func calculateInputDirection() -> Vector2:
    if controllerData["type"]=="pad":
        var controller = controllerData["pad"]
        var x = Input.get_joy_axis(controller, JOY_AXIS_LEFT_X)
        var y = Input.get_joy_axis(controller, JOY_AXIS_LEFT_Y)
        return normalizeDirection(Vector2(x, y))
    elif controllerData["type"]=="keyboard":
        var up = Input.is_key_pressed(controllerData["up"])
        var down = Input.is_key_pressed(controllerData["down"])
        var left = Input.is_key_pressed(controllerData["left"])
        var right = Input.is_key_pressed(controllerData["right"])
        var x = 0
        var y = 0
        if up && !down:
            y = -1
        elif !up && down:
            y = 1
        if left && !right:
            x = -1
        elif !left && right:
            x = 1
        return normalizeDirection(Vector2(x, y))
    else:
        return Vector2.ZERO

func isJumpButtonPressedRaw() -> bool:
    var pressed := false
    if controllerData["type"]=="pad":
        pressed = Input.is_joy_button_pressed(controllerData["pad"], JOY_BUTTON_A)
    elif controllerData["type"]=="keyboard":
        pressed = Input.is_key_pressed(controllerData["jump"])
    return pressed

func isDuckButtonPressed() -> bool:
    var pressed := false
    if controllerData["type"]=="pad":
        pressed = Input.is_joy_button_pressed(controllerData["pad"], JOY_BUTTON_B)
    elif controllerData["type"]=="keyboard":
        pressed = Input.is_key_pressed(controllerData["duck"])
    return pressed

var wasJumpPressedLastFrame := false
var wasJumpJustPressed := false
func updateJumpButton() -> void:
    var pressed = isJumpButtonPressedRaw()
    var justPressed := false
    if pressed:
        if wasJumpPressedLastFrame:
            justPressed = false
        else:
            justPressed = true
        wasJumpPressedLastFrame = true
    else:
        justPressed = false
        wasJumpPressedLastFrame = false
    wasJumpJustPressed = justPressed

func updateDuckButton():
    if isDuckButtonPressed() and not duck_player.playing:
        var quacks: Array
        var isBerek := GameData.isCharacterBerek(character)
        if isBerek:
            quacks = duckBerek
        else:
            quacks = duck
        var idx = randi_range(0, quacks.size()-1)
        duck_player.stream = quacks[idx]
        duck_player.play()
        megaphone.visible = true
        #duck_cooldown.start()

func isJumpButtonPressed() -> bool:
    if wasJumpJustPressed:
        lastTimeJumpPressed = Time.get_ticks_msec()
        return true

    if (Time.get_ticks_msec() - lastTimeJumpPressed) <= JUMP_BUFFER_TIME:
        return true

    return false

func calculateState(dir: Vector2, justJumped: bool, isOnGround: bool) -> DudeState:
    if currentState == DudeState.Dead:
        return DudeState.Dead

    if justJumped:
        return DudeState.Jump

    if not isOnGround:
        return DudeState.Falling

    if dir == Vector2.ZERO:
        return DudeState.Idle

    return DudeState.Running

# Respawns a player after dying. Called by respawnTimer().
func respawn():
    if GameData.hud.isMenuOpen():
        respawnTimer.start() # Try again later!
        return

    if currentState != DudeState.Dead:
        print("Canot respawn! I'm not Dead: " + GameData.characterEnumToStr(character))
        return

    print("Respawning: " + GameData.characterEnumToStr(character))
    GameData.berekCooldownActive = false
    respawn_player.play()
    currentState = DudeState.Idle
    animation.play(GameData.characterEnumToStr(character) + stateToAnim(currentState) + str(currentAngle))

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
    if GameData.hud.isMenuOpen():
        return

    var isBerek := GameData.isCharacterBerek(character)
    updateBerekMarker()

    updateJumpButton()
    updateDuckButton()

    var direction = calculateInputDirection()
    #var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

    var isJumpPressed = isJumpButtonPressed()
    #var isJump = Input.is_action_just_pressed("ui_accept")

    if currentState == DudeState.Dead:
        direction = Vector2.ZERO
        isJumpPressed = false

    var preMapPosition := GameData.layerHelpers.mapPositionFromScreenPosition(global_position, currentZ)
    var preGroundInfo := GameData.layerHelpers.groundInfoFromMapPosition(preMapPosition, currentZ)

    # Add the gravity.
    var currentlyOnGround := false
    if preGroundInfo.groundType != LayerHelpers.GroundType.EMPTY:
        var distFromGround := currentZ - preGroundInfo.groundHeight
        var heightToConsiderOnGround := layerHeight / 20.0
        currentlyOnGround = distFromGround < heightToConsiderOnGround
    if currentlyOnGround:
        lastTimeOnTheGround = Time.get_ticks_msec()

    if currentlyOnGround:
        velocityZ = 0.0
    else:
        velocityZ -= gravity * delta

    # Handle jump.
    var didJustJump := false
    var isCoyoteTimeActive =  (Time.get_ticks_msec() - lastTimeOnTheGround) <= COYOTE_TIME
    if isJumpPressed and (currentlyOnGround or isCoyoteTimeActive):
        velocityZ = JUMP_VELOCITY
        didJustJump = true
        currentlyOnGround = false
        lastTimeJumpPressed = 0 # Turn off jump buffer time when we just used it.
        lastTimeOnTheGround = 0 # Turn off coyote time when we just used it.

    # Ustawienie prędkości
    if direction == Vector2.ZERO:
        velocity = velocity.move_toward(Vector2.ZERO, delta*DECELERATION_FACTOR)
    else:
        var max_speed = BEREK_MAX_SPEED if isBerek else MAX_SPEED
        var acceleration_factor = BEREK_ACCELERATION_FACTOR if isBerek else ACCELERATION_FACTOR
        velocity = velocity.move_toward(direction * Vector2(max_speed, max_speed * WORLD_ASPECT_FACTOR), delta*acceleration_factor)

    var prePos = global_position
    move_and_slide()
    var postPos = global_position
    var posDelta = postPos - prePos

    # Super janky hack for sliding along walls.
    debugLabel.text = "X"
    if get_slide_collision_count() > 0:
        var colliderName = ""
        for i in get_slide_collision_count():
            var collision = get_slide_collision(i)
            colliderName += " " + collision.get_collider().name
        #debugLabel.text = "Y " + colliderName
        if (direction.length() > 0.1) and (posDelta.length() > 0.1):
            var cosPrePost = direction.normalized().dot(posDelta.normalized())
            #debugLabel.text = "Z cos={cos} colliderName={colliderName}".format({"cos": cosPrePost, "colliderName": colliderName})
            if (cosPrePost >= 0) and (cosPrePost < 0.35):
                var hackyPos = prePos * 0.9 + postPos * 0.1
                global_position = hackyPos
                velocity = (hackyPos - prePos) / delta
                debugLabel.text = "W cos={cos} colliderName={colliderName}".format({"cos": cosPrePost, "colliderName": colliderName})

    var deltaZ := velocityZ * delta # @note We need to add y-offset computed from z later.
    # We don't allow falling 2 layers below, to simplify the code.
    deltaZ = clamp(deltaZ, -layerHeight, layerHeight)

    var postMapPosition := GameData.layerHelpers.mapPositionFromScreenPosition(global_position, currentZ)
    var postGroundInfo := GameData.layerHelpers.groundInfoFromMapPosition(postMapPosition, currentZ)

    if currentlyOnGround: # We know we did not apply gravity nor jumped.
        # If we are still on ground, glue player to the ground.
        if postGroundInfo.groundType != LayerHelpers.GroundType.EMPTY:
            deltaZ = postGroundInfo.groundHeight - currentZ

    # Hack for falling through the level.
    # We only handle falling through the floor, not jumping through the ceilling (for simplicity).
    var groundEpsilon := layerHeight / 20.0
    var lowerZ = min(currentZ, currentZ + deltaZ) - groundEpsilon
    var upperZ = max(currentZ, currentZ + deltaZ) + groundEpsilon
    var beetweenGrounds := GameData.layerHelpers.groundHeightsBeetweenZs(postMapPosition.mapCoords, postMapPosition.offsetWithinTile, lowerZ, upperZ)
    if deltaZ < 0:
        if beetweenGrounds.size() >= 1:
            # Stop on the highest ground.
            deltaZ = beetweenGrounds[beetweenGrounds.size() - 1] - currentZ

    currentZ += deltaZ

    global_position = GameData.layerHelpers.screenPositionFromMapPosition(postMapPosition.mapCoords, postMapPosition.offsetWithinTile, currentZ)
    var curLayer := GameData.layerHelpers.layerFromZ(currentZ)
    baseImage.offset.y = baseImageOffsetY - (currentZ - curLayer * layerHeight) * zToYOffsetRatio / baseImage.scale.y
    outlineImage.offset.y = outlineImageOffsetY - (currentZ - curLayer * layerHeight) * zToYOffsetRatio / outlineImage.scale.y
    megaphoneImage.offset.y = megaphoneImageOffsetY - (currentZ - curLayer * layerHeight) * zToYOffsetRatio / megaphoneImage.scale.y
    #image.position.y += (curLayer - prevLayer) * layerHeight * zToYOffsetRatio

    # We use collision mask from previous z. It's close enough.
    clearLayerCollisionMask()
    setLayerCollisionMask(curLayer, true)
    #setLayerCollisionMask(postGroundInfo.layer, postGroundInfo.useThisCollision)
    #setLayerCollisionMask(postGroundInfo.layer - 1, postGroundInfo.useBelowCollision)
    z_index = postGroundInfo.layer + 1
    #z_index = 1

    # State changes and animation handling.

    var changeAnimation := false
    var oldState := currentState
    currentState = calculateState(direction, didJustJump, currentlyOnGround)

    if currentState != oldState:
        if currentState == DudeState.Jump: # this is temporary solution for canceling jump
            jump_player.play()

        # If we just landed play the landing sound.
        if ((oldState == DudeState.Jump) or (oldState == DudeState.Falling)) and currentlyOnGround:
            landing_player.play()

        if currentState == DudeState.Running:
            if not run_player.playing:
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
        animation.play(GameData.characterEnumToStr(character) + stateToAnim(currentState) + str(currentAngle))

    syncAnimations()

    if debugLabel != null:
        #debugLabel.text = "state={state} imageOffset={imageOffset} z_index={z_index} gravity={gravity} deltaZ={deltaZ} velocityZ={velocityZ}\nonGround={onGround} movedOnGround={movedOnGround} mapCoords={mapCoords} currentZ={currentZ}".\
        #    format({"state": currentState, "imageOffset": baseImage.offset.y - baseImageOffsetY, "z_index": z_index, "gravity": gravity, "deltaZ": deltaZ, "velocityZ": velocityZ, "onGround": currentlyOnGround, "movedOnGround": movedOnGround, "mapCoords": postMapPosition.mapCoords, "currentZ": currentZ})
        #debugLabel.text = "isJumpPressed={isJumpPressed}".\
        #    format({"isJumpPressed": isJumpPressed})
        pass

func initiate_death():
        currentState = DudeState.Dead
        animation.play(GameData.characterEnumToStr(character) + stateToAnim(currentState) + str(currentAngle))
        syncAnimations()
        dust.visible = true
        dust.play("dirt")


func _on_area_2d_body_entered(body: Node2D) -> void:
    if (not GameData.berekCooldownActive) and body.is_in_group("Dude"):
        # Check if we are close enough in z.
        var zDist = absf(currentZ - body.currentZ)
        if zDist > GameData.layerHelpers.layerHeight:
            return

        if !GameData.canZberkowac(body.character, character):
            return

        GameData.doZberkuj(body.character, character)
        GameData.berekCooldownActive = true

        print("Berek {berek} caught player {caught}.".format({ "berek": body.character, "caught": character }))
        GameData.hud.countPointsDudeGotMe(self, body)

        run_player.stop()
        die_player.play()
        gotcha_player.play()

        initiate_death()
        respawnTimer.start()

func _dust_dispersed():
    dust.visible = false

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

func stateToAnim(state: DudeState) -> String:
    if state == DudeState.Dead:
        return "Die"
    if state == DudeState.Running:
        return "Dir"
    if state == DudeState.Falling:
        return "Dir"
    return DudeState.find_key(state)


func _on_duck_player_finished() -> void:
    megaphone.visible = false
