extends CanvasLayer
class_name Hud

const PLAYER_PICKER = preload("res://player_picker.tscn")

signal new_game_pressed()
signal game_won(info: String)

@onready var new_game_button: Button = $Screen/Menu/VBoxContainer/NewGameButton
@onready var controls_button: Button = $Screen/Menu/VBoxContainer/ControlsButton
@onready var background: TextureRect = $Screen/Background
@onready var backgroundForLevel: TextureRect = $Screen/BackgroundForLevel
@onready var menu: Control = $Screen/Menu
@onready var gauges: Control = $Screen/Gauges

@onready var menu_music: AudioStreamPlayer = $Music/MenuMusic
@onready var level_music: AudioStreamPlayer = $Music/LevelMusic

var playerData = {
    0:{"type":"pad","pad":0},
    1:{"type":"keyboard","up":KEY_UP,"down":KEY_DOWN,"left":KEY_LEFT,"right":KEY_RIGHT,"jump":KEY_SPACE}
}

var player_huds: Dictionary = {}
var player_anims: Dictionary = {}
var player_bars: Dictionary = {}
var playerNumber: Dictionary = {"Fox": 0, "Ferret": 1, "Weasel": 2, "Snow": 3}
var playerPoints: Dictionary = {"Fox": 0.0, "Ferret": 0.0, "Weasel": 0.0, "Snow": 0.0}
var dudes: Dictionary = {"Fox": null, "Ferret": null, "Weasel": null, "Snow": null}
var pointsCatchGain = 40.0
var pointsCatchPenalty = 20.0
var pointsMax = 1000.0

#func getPlayerLabel(player_hud: Control) -> Label:
#    return player_hud.get_node("PlayerLabel")

#func getPlayerBerek(player_hud: Control) -> TextureRect:
#    return player_hud.get_node("PlayerBerek")

#func _setBerek(player_hud: Control, berek: bool):
#    getPlayerBerek(player_hud).visible = berek
#    getPlayerLabel(player_hud).visible = !berek

#func setBerek(playerNo: int):
#    for(dude_hud in player_huds)
#    _setBerek(player_1_hud, playerNo==1)
#    _setBerek(player_2_hud, playerNo==2)
#    _setBerek(player_3_hud, playerNo==3)
#    _setBerek(player_4_hud, playerNo==4)

func initPlayers(ddudes: Array[Dude]):
    for h in player_huds:
        player_huds[h].visible = false

    if ddudes.size() > 1:
        for dude in ddudes:
            dudes[dude.character] = dude
            player_huds[playerNumber[dude.character]].visible = true
            if ! dude.isBerek:
                player_anims[playerNumber[dude.character]].play()

func _ready() -> void:

    for i in range(4):
        player_huds[i] = get_node("Screen/Gauges/Player%dHud" % (i + 1) )
    for i in range(4):
        player_anims[i] = get_node("Screen/Gauges/Player%dHud/Anim" % (i + 1) )
    for i in range(4):
        player_bars[i] = get_node("Screen/Gauges/Player%dHud/Bar" % (i + 1) )

    show_menu(true, false)

func countPointsDudeGotMe(victim, hunter):
    countPointsSet(victim.character, playerPoints[victim.character] - pointsCatchPenalty)
    countPointsSet(hunter.character, playerPoints[hunter.character] + pointsCatchGain)
    player_anims[playerNumber[victim.character]].stop()

func pointsToScreen(p):
    var screen_size = get_viewport().get_visible_rect().size
    var maxScreenCoord = screen_size.x - 20
    return (p / pointsMax) * maxScreenCoord


func countPointsSet(ch, points):
    var p = max(0.001, min(pointsMax, points))
    playerPoints[ch] = p
    if points > pointsMax: game_won.emit(ch)

    var bar: TextureRect = player_bars[playerNumber[ch]]
    var player_hud: Control = player_huds[playerNumber[ch]]
    var sp = pointsToScreen(playerPoints[ch])
    bar.size.x = sp
    bar.position.x = -sp
    player_hud.position.x = sp

func countPointsReset():
    for ch in playerPoints:
        countPointsSet(ch, 0.0)


func _process(delta: float) -> void:
    if isInLevel() and (not isPickerActive):
        if Input.is_action_just_pressed("ui_menu"):
            show_menu(not isMenuOpen(), true)

    const POINTS_PER_SECOND := 6.0
    var elapsed: float = 0.0 if isMenuOpen() else delta

    for ch in playerPoints:
        if dudes[ch] != null:
            if dudes[ch].isBerek or dudes[ch].isDead():
                player_anims[playerNumber[ch]].stop()
            else:
                countPointsSet(ch, playerPoints[ch] + elapsed * POINTS_PER_SECOND)
                player_anims[playerNumber[ch]].play()

func show_menu(do_show: bool, in_level: bool):
    var musicForMenu := (not in_level) and do_show
    playMusic(musicForMenu)
    background.visible = (not in_level) and do_show
    backgroundForLevel.visible = in_level and do_show
    menu.visible = do_show
    gauges.visible = !do_show
    if do_show:
        new_game_button.grab_focus.call_deferred()


func _on_new_game_button_pressed() -> void:
    countPointsReset()
    new_game_pressed.emit()


func _on_full_screen_button_pressed() -> void:
    if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


func _on_exit_button_pressed() -> void:
    get_tree().quit()


var isPickerActive := false
func _on_controls_button_pressed() -> void:
    menu.visible = false
    var picker = PLAYER_PICKER.instantiate()
    picker.tree_exited.connect(_on_player_picker_destroy)
    add_child(picker)
    isPickerActive = true

func updatePlayerData(pd: Dictionary):
    playerData = pd
    new_game_button.disabled = false

func _on_player_picker_destroy():
    menu.visible = true
    controls_button.grab_focus.call_deferred()
    isPickerActive = false

func playMusic(forMenu: bool) -> void:
    var player := menu_music if forMenu else level_music
    var otherPlayer := menu_music if not forMenu else level_music
    otherPlayer.stop()
    if not player.playing:
        player.play()

func isInLevel() -> bool:
    return GameData.game.level != null

func isMenuOpen() -> bool:
    return menu.visible or isPickerActive
