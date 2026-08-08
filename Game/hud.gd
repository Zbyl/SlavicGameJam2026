extends CanvasLayer
class_name Hud

const PLAYER_PICKER = preload("res://player_picker.tscn")

signal new_game_pressed()

@onready var player_1_hud: Control = $Screen/Gauges/Player1Hud
@onready var player_2_hud: Control = $Screen/Gauges/Player2Hud
@onready var player_3_hud: Control = $Screen/Gauges/Player3Hud
@onready var player_4_hud: Control = $Screen/Gauges/Player4Hud
@onready var player_1_anim: AnimatedSprite2D = $Screen/Gauges/Player1Hud/Anim
@onready var player_2_anim: AnimatedSprite2D = $Screen/Gauges/Player2Hud/Anim
@onready var player_3_anim: AnimatedSprite2D = $Screen/Gauges/Player3Hud/Anim
@onready var player_4_anim: AnimatedSprite2D = $Screen/Gauges/Player4Hud/Anim
@onready var player_1_bar: TextureRect = $Screen/Gauges/Player1Hud/Bar
@onready var player_2_bar: TextureRect = $Screen/Gauges/Player2Hud/Bar
@onready var player_3_bar: TextureRect = $Screen/Gauges/Player3Hud/Bar
@onready var player_4_bar: TextureRect = $Screen/Gauges/Player4Hud/Bar
@onready var new_game_button: Button = $Screen/Menu/VBoxContainer/NewGameButton
@onready var controls_button: Button = $Screen/Menu/VBoxContainer/ControlsButton
@onready var background: TextureRect = $Screen/Background
@onready var menu: Control = $Screen/Menu
@onready var gauges: Control = $Screen/Gauges

@onready var menu_music: AudioStreamPlayer = $Music/MenuMusic
@onready var level_music: AudioStreamPlayer = $Music/LevelMusic

var playerData = {
    0:{"type":"pad","pad":0},
    1:{"type":"keyboard","up":KEY_UP,"down":KEY_DOWN,"left":KEY_LEFT,"right":KEY_RIGHT,"jump":KEY_SPACE}
}

#var playerPoints = {"Fox"": 0.0, "Ferret":0.0, "Weasel":0.0, "Snow":0.0}
#var playerNumer = {"Fox"": 1, "Ferret": 2, "Weasel": 3, "Snow": 4}

func getPlayerLabel(player_hud: Control) -> Label:
    return player_hud.get_node("PlayerLabel")

func getPlayerBerek(player_hud: Control) -> TextureRect:
    return player_hud.get_node("PlayerBerek")

func _setBerek(player_hud: Control, berek: bool):
    getPlayerBerek(player_hud).visible = berek
    getPlayerLabel(player_hud).visible = !berek

func setBerek(playerNo: int):
    _setBerek(player_1_hud, playerNo==1)
    _setBerek(player_2_hud, playerNo==2)
    _setBerek(player_3_hud, playerNo==3)
    _setBerek(player_4_hud, playerNo==4)

func initPlayers(ddudes: Array[Dude]):
    var count = ddudes.size()
    player_4_hud.visible = count>=4
    player_3_hud.visible = count>=3
    player_2_hud.visible = count>=2
    player_1_hud.visible = count>=1
    #setBerek(1)
    if count >= 1:
        player_1_anim.play()
    if count >= 2:
        player_2_anim.play()
    if count >= 3:
        player_3_anim.play()
    if count >= 4:
        player_4_anim.play()

func _ready() -> void:
    #player_1_anim.play()
    #player_2_anim.play()
    #player_3_anim.play()
    #player_4_anim.play()
    show_menu(true)
    
func countPointsDudeGotMe(victim, hunter):
    pass 
    
func _process(delta: float) -> void:
    Time.get_ticks_msec()

func show_menu(do_show: bool):
    playMusic(do_show)
    background.visible = do_show
    menu.visible = do_show
    gauges.visible = !do_show
    if do_show:
        new_game_button.grab_focus.call_deferred()


func _on_new_game_button_pressed() -> void:
    new_game_pressed.emit()


func _on_full_screen_button_pressed() -> void:
    if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


func _on_exit_button_pressed() -> void:
    get_tree().quit()


func _on_controls_button_pressed() -> void:
    menu.visible = false
    var picker = PLAYER_PICKER.instantiate()
    picker.tree_exited.connect(_on_player_picker_destroy)
    add_child(picker)

func updatePlayerData(pd: Dictionary):
    playerData = pd
    new_game_button.disabled = false

func _on_player_picker_destroy():
    menu.visible = true
    controls_button.grab_focus.call_deferred()

func playMusic(forMenu: bool) -> void:
    var player := menu_music if forMenu else level_music
    var otherPlayer := menu_music if not forMenu else level_music
    otherPlayer.stop()
    if not player.playing:
        player.play()
