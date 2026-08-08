extends Node2D
class_name Game

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

    level = new_level_scene.instantiate()
    GameData.layerHelpers.initTileMaps(level)
    add_child(level)

    var spawnPointMarkers: Array[Node] = get_tree().get_nodes_in_group('SpawnPoint')
    var spawnPoints: Array[Vector3] = [] # @note Order of spawn points does not correspond to names inside Level.
    for spawnPointMarker in spawnPointMarkers:
        var spawnParentName = spawnPointMarker.get_parent().name
        assert(spawnParentName.substr(0, "TileMapLayer".length()) == "TileMapLayer", "Invalid spawn parent name")
        var idxStr = spawnParentName.substr("TileMapLayer".length())
        var layer = int(idxStr)
        var spawnPoint := Vector3(spawnPointMarker.global_position.x, spawnPointMarker.global_position.y, layer * GameData.layerHelpers.layerHeight)
        spawnPoints.append(spawnPoint)

    assert(spawnPoints.size() == 4, "Must have 4 spawn points in a level")

    var dude: Dude = DUDE.instantiate()
    add_child(dude)
    dude.global_position = Vector2(spawnPoints[0].x, spawnPoints[0].y)
    dude.currentZ = spawnPoints[0].z
    dude.debugLabel = GameData.hud.get_node("./%DebugLabel")

    var newDudes: Array[Node] = get_tree().get_nodes_in_group('Dude')
    var ddudes: Array[Dude] = []
    for newDude in newDudes:
        ddudes.append(newDude as Dude)
    gameCamera.dudes = ddudes
    
    GameData.hud.show_menu(false)
