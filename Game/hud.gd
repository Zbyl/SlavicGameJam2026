extends CanvasLayer
class_name Hud

const TEAM_PICKER = preload("res://team_picker.tscn")
const PLAYER_PICKER = preload("res://player_picker.tscn")
const WIN_SCREEN = preload("res://win_screen.tscn")
const POINTS_PER_SECOND = 12.0
const POINTS_PER_GOAL = 100.0
const pointsCatchGain = 40.0
const pointsCatchPenalty = 20.0
const pointsMax = 1000.0

const KEYBOARD_PLAYER1 = {"type":"keyboard","up":KEY_UP,"down":KEY_DOWN,"left":KEY_LEFT,"right":KEY_RIGHT,"jump":KEY_SPACE,"duck":KEY_CTRL}
const KEYBOARD_PLAYER2 = {"type":"keyboard","up":KEY_W,"down":KEY_S,"left":KEY_A,"right":KEY_D,"jump":KEY_SHIFT,"duck":KEY_Q}
const KEYBOARD_PLAYER3 = {"type":"keyboard","up":KEY_I,"down":KEY_K,"left":KEY_J,"right":KEY_L,"jump":KEY_O,"duck":KEY_U}
const KEYBOARD_PLAYER4 = {"type":"keyboard","up":KEY_KP_8,"down":KEY_KP_5,"left":KEY_KP_4,"right":KEY_KP_6,"jump":KEY_KP_0,"duck":KEY_KP_ENTER}
const PAD_PLAYER = {"type":"pad","pad":0}

signal new_game_pressed(levelIdx: int)
signal game_won(winningTeams: Array[int])

@onready var new_game_button0: Button = $Screen/Menu/VBoxContainer/NewGameButton0
@onready var teams_button: Button = $Screen/Menu/VBoxContainer/TeamsButton
@onready var controls_button: Button = $Screen/Menu/VBoxContainer/ControlsButton
@onready var background: TextureRect = $Screen/Background
@onready var backgroundForLevel: TextureRect = $Screen/BackgroundForLevel
@onready var menu: Control = $Screen/Menu
@onready var gauges: Control = $Screen/Gauges
@onready var win_delay_timer: Timer = $WinDelayTimer

@onready var menu_music: AudioStreamPlayer = $Music/MenuMusic
@onready var level_music: AudioStreamPlayer = $Music/LevelMusic

var playerData = {}

var player_huds: Dictionary = {}
var player_anims: Dictionary = {}
var player_bars: Dictionary = {}
var teamPoints: Dictionary[int, float] = {}


var countTimePoints: bool = true    # True if we should count points for passing time.

func initPlayers():
    # No point in counting time points when we have only one team.
    countTimePoints = GameData.countBerekPoints and (GameData.nonEmptyTeamToCharacters.size() > 1)
    teamPoints = {}
    for team in GameData.nonEmptyTeamToCharacters:
        teamPoints[team] = 0
    print("teamPoints={teamPoints}".format({"teamPoints": teamPoints}))

    for h in player_huds:
        player_huds[h].visible = false

    var playerOffsets: Dictionary[GameData.Character, int] = {}
    var playerOffset := 0
    for team in GameData.nonEmptyTeamToCharacters:
        var chars := GameData.getCharactersInTeam(team)
        for ch in chars:
            playerOffsets[ch] = playerOffset
            playerOffset += 1
        
    for character in playerOffsets:
        var playerNumber = GameData.ALL_CHARACTERS.find(character)
        player_huds[playerNumber].visible = true
        player_huds[playerNumber].position.y = 13 * playerOffsets[playerNumber]
        if not GameData.isCharacterBerek(character):
            player_anims[playerNumber].play()

func init_default_player_data():
    if false:
        playerData = {
            0:KEYBOARD_PLAYER2.duplicate(),
            1:KEYBOARD_PLAYER3.duplicate(),
            2:KEYBOARD_PLAYER1.duplicate(),
            3:KEYBOARD_PLAYER4.duplicate(),
        }
        return 
    var padNum = Input.get_connected_joypads().size()
    if padNum==0:
        playerData = {
            0:KEYBOARD_PLAYER1.duplicate(),
            1:KEYBOARD_PLAYER2.duplicate()
        }
    elif padNum==1:
        playerData = {
            0:PAD_PLAYER.duplicate(),
            1:KEYBOARD_PLAYER1.duplicate()
        }
    else:
        playerData = {}
        for i in range(0, padNum):
            var pl = PAD_PLAYER.duplicate()
            pl.pad = i
            playerData[i] = pl

func _ready() -> void:
    init_default_player_data()

    for i in range(4):
        player_huds[i] = get_node("Screen/Gauges/Player%dHud" % (i + 1) )
        player_huds[i].position.y = 0
    for i in range(4):
        player_anims[i] = get_node("Screen/Gauges/Player%dHud/Anim" % (i + 1) )
        player_anims[i].position.y = 22
    for i in range(4):
        player_bars[i] = get_node("Screen/Gauges/Player%dHud/Bar" % (i + 1) )
        player_bars[i].position.y = player_anims[i].position.y - 4

    show_menu(true, false)

func countPointsDudeGotMe(victim: Dude, hunter: Dude):
    if GameData.countBerekPoints:
        var victimTeam := GameData.getCharacterTeam(victim.character)
        var hunterTeam := GameData.getCharacterTeam(hunter.character)
        countPointsSet(victim.character, teamPoints[victimTeam] - pointsCatchPenalty)
        countPointsSet(hunter.character, teamPoints[hunterTeam] + pointsCatchGain)
        checkWinners()
    var playerNumber = GameData.ALL_CHARACTERS.find(victim.character)
    player_anims[playerNumber].stop()

func countPointsForGoal(character: GameData.Character) -> void:
    if GameData.countGoalsPoints:
        var team := GameData.getCharacterTeam(character)
        countPointsSet(character, teamPoints[team] + POINTS_PER_GOAL)
        checkWinners()

func pointsToScreen(p):
    var screen_size = get_viewport().get_visible_rect().size
    var maxScreenCoord = screen_size.x - 20
    return (p / pointsMax) * maxScreenCoord


func checkWinners():
    if gameAlreadyWon:
        return
        
    var winningTeams: Array[int] = []
    for team in teamPoints:
        var points = teamPoints[team]
        if points >= pointsMax:
            winningTeams.append(team)
            
    if winningTeams.size() > 0:
        print("winningTeams={winningTeams} teamPoints={teamPoints}".format({"winningTeams": winningTeams, "teamPoints": teamPoints}))
        gameAlreadyWon = true
        game_won.emit(winningTeams)
        

func countPointsSet(team: int, points: float) -> void:
    var p = clampf(points, 0.001, pointsMax)
    teamPoints[team] = p

    var isFirst := true
    for character in GameData.getCharactersInTeam(team):
        var playerNumber = GameData.ALL_CHARACTERS.find(character)
        var bar: TextureRect = player_bars[playerNumber]
        var player_hud: Control = player_huds[playerNumber]
        var sp = pointsToScreen(p)
        bar.size.x = sp
        bar.position.x = -sp
        bar.visible = isFirst
        player_hud.position.x = sp
        isFirst = false

func countPointsReset():
    for team in teamPoints:
        countPointsSet(team, 0.0)


func _process(delta: float) -> void:
    if isInLevel() and (not isAnyPickerActive()):
        if Input.is_action_just_pressed("ui_menu"):
            show_menu(not isMenuOpen(), true)

    var elapsed: float = 0.0 if isMenuOpen() else delta

    for team in teamPoints:
        # Berek's don't get time points, even during berekCooldownActive.
        # Everyone else does, even during berekCooldownActive.
        if GameData.isTeamBerek(team):
            for character in GameData.getCharactersInTeam(team):
                var playerNumber = GameData.ALL_CHARACTERS.find(character)
                player_anims[playerNumber].stop()
        else:
            if countTimePoints:
                countPointsSet(team, teamPoints[team] + elapsed * POINTS_PER_SECOND)
            for character in GameData.getCharactersInTeam(team):
                var playerNumber = GameData.ALL_CHARACTERS.find(character)
                player_anims[playerNumber].play() # @todo Should we stop() if !countTimePoints?

    checkWinners()

func show_menu(do_show: bool, in_level: bool):
    var musicForMenu := (not in_level) and do_show
    playMusic(musicForMenu)
    background.visible = (not in_level) and do_show
    backgroundForLevel.visible = in_level and do_show
    menu.visible = do_show
    gauges.visible = !do_show
    if do_show:
        new_game_button0.grab_focus.call_deferred()


func _on_new_game_button_pressed(levelIdx: int) -> void:
    gameAlreadyWon = false
    new_game_pressed.emit(levelIdx)


func _on_full_screen_button_pressed() -> void:
    if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


func _on_exit_button_pressed() -> void:
    get_tree().quit()


func isAnyPickerActive() -> bool:
    return isTeamsPickerActive or isPickerActive

var isTeamsPickerActive := false
func _on_teams_button_pressed() -> void:
    menu.visible = false
    var picker = TEAM_PICKER.instantiate()
    picker.tree_exited.connect(_on_teams_picker_destroy)
    add_child(picker)
    isTeamsPickerActive = true

var isPickerActive := false
func _on_controls_button_pressed() -> void:
    menu.visible = false
    var picker = PLAYER_PICKER.instantiate()
    picker.tree_exited.connect(_on_player_picker_destroy)
    add_child(picker)
    isPickerActive = true

func updatePlayerData(pd: Dictionary):
    playerData = pd

func _on_teams_picker_destroy():
    menu.visible = true
    teams_button.grab_focus.call_deferred()
    isTeamsPickerActive = false

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
    return menu.visible or isAnyPickerActive()

var gameAlreadyWon: bool = false
var gameWonByTeams: Array[int] = []

func _on_game_won(winningTeams: Array[int]) -> void:
    GameData.printTeamsAndBereks()
    print("Game won by teams: " + str(winningTeams))

    for dude in get_tree().get_nodes_in_group('Dude'):
        dude.initiate_death()
        if GameData.getCharacterTeam(dude.character) in winningTeams:
            dude.crown.visible = true

    gameWonByTeams = winningTeams
    win_delay_timer.start()

func _on_win_delay_timer_timeout() -> void:
    var winners: Array[GameData.Character] = []
    for team in gameWonByTeams:
        for character in GameData.getCharactersInTeam(team):
            winners.append(character)

    print("Game winners: " + str(winners))

    var loosers: Array[GameData.Character] = []
    for character in GameData.activeCharacters:
        if character not in winners:
            loosers.push_back(character)

    print("Game loosers: " + str(loosers))

    var winScreen = WIN_SCREEN.instantiate()
    winScreen.winners = winners
    winScreen.loosers = loosers

    GameData.game._switch_level(null)
    level_music.stop()
    menu_music.stop()
    GameData.game.add_child(winScreen)
    GameData.game.move_child(winScreen, 0)
