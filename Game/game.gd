extends Node2D
class_name Game

const CHARACTERS = ["Fox", "Ferret", "Weasel", "Snow"]

@onready var hud: CanvasLayer = $Hud

const LEVEL_1 = preload("res://Levels/Level1.tscn")
const DUDE = preload("res://characters/dude.tscn")

@onready var gameCamera: GameCamera = $GameCamera

var level: Node2D = null # Current level, or null

func _ready() -> void:
    hud.new_game_pressed.connect(_on_new_game_pressed)

func _on_new_game_pressed():
    await _switch_level(LEVEL_1)

func _switch_level(new_level_scene):
    # Cleanup
    # - Unregister Players with camera
    # - Remove Players
    # - Remove level
    # - Wait for all timers and things to finish.
    # - Hide menu
    # - Stop music?

    # Set up:
    # - Add Level
    # - Pre-process level before adding Players.
    # - Extract SpawnPoints
    # - Add Players
    # - Register Players with camera
    # - Hide menu
    # - Reset gameplay stats (health, scores, time)
    # - Start music

    gameCamera.dudes = []
    var oldDudes = get_tree().get_nodes_in_group('Dude')
    for dude in oldDudes:
        dude.queue_free()

    if level:
        level.queue_free()
        level = null

    # Hack to make sure we instantiate new level once old level is actually freed.
    # Otherwise we might have two Players at once etc.
    await get_tree().create_timer(0.01).timeout

    GameData.hud.playMusic(false)

    level = new_level_scene.instantiate()
    add_child(level)
    GameData.layerHelpers.initTileMaps(level) # Must be run when level is already in the tree (as it uses get_nodes_in_group()).

    var first = true
    for key in hud.playerData.keys():
        var controllerData = hud.playerData[key]
        var dude: Dude = DUDE.instantiate()
        dude.isBerek = first
        dude.character = CHARACTERS[key]
        dude.controllerData = controllerData
        first = false
        var spawnPoint = GameData.layerHelpers.spawnPoints[key]
        add_child(dude)
        dude.global_position = Vector2(spawnPoint.x, spawnPoint.y)
        dude.currentZ = spawnPoint.z
        dude.debugLabel = GameData.hud.get_node("./%DebugLabel")

    var newDudes: Array[Node] = get_tree().get_nodes_in_group('Dude')
    var ddudes: Array[Dude] = []
    for newDude in newDudes:
        ddudes.append(newDude as Dude)
    gameCamera.dudes = ddudes
    GameData.hud.initPlayers(ddudes)
    GameData.hud.show_menu(false, true)
