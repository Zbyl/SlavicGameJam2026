extends CanvasLayer
const WIN_DUDE = preload("res://win_dude.tscn")
const CIRCLE_RADIUS = 100.0
const CIRCLE_CENTER = Vector2(0.5, 0.8)

@export var winners: Array[GameData.Character] = [GameData.Character.Fox, GameData.Character.Snow, GameData.Character.Weasel, GameData.Character.Ferret]
@export var loosers: Array[GameData.Character] = []
@onready var mandatory_timer: Timer = $MandatoryTimer
@onready var greeting: TextureRect = $Greeting

func _ready() -> void:
    #GameData.hud.gauges.visible = false
    greeting.modulate.a = 0.0
    var greeting_tween = create_tween().set_trans(Tween.TRANS_EXPO)
    greeting_tween.tween_property(greeting, "modulate:a", 1.0, 5.0)

    var numPlaces: int = 1 + loosers.size()

    var idx = 0
    var subIndex = 0
    for winner in winners:
        var win_dude: Node2D = WIN_DUDE.instantiate()
        win_dude.win = true
        win_dude.character = winner
        @warning_ignore("integer_division")
        win_dude.dir = 1 + 8 * idx / numPlaces
        if win_dude.dir > 8:
            win_dude.dir -= 8
        win_dude.global_position = GameData.game.get_viewport_rect().size * CIRCLE_CENTER + (Vector2(1, -1) * CIRCLE_RADIUS).rotated(2.0*idx*PI/numPlaces)/Vector2(1.0, 2.0)
        win_dude.global_position += Vector2(50, 25) * subIndex
        add_child(win_dude)
        subIndex += 1

    idx = 1
    for looser in loosers:
        var win_dude: Node2D = WIN_DUDE.instantiate()
        win_dude.win = false
        win_dude.character = looser
        @warning_ignore("integer_division")
        win_dude.dir = 1 + 8 * idx / numPlaces
        if win_dude.dir > 8:
            win_dude.dir -= 8
        win_dude.global_position = GameData.game.get_viewport_rect().size * CIRCLE_CENTER + (Vector2(1, -1) * CIRCLE_RADIUS).rotated(2.0*idx*PI/numPlaces)/Vector2(1.0, 2.0)
        add_child(win_dude)
        idx += 1

func _process(_delta: float) -> void:
    if mandatory_timer.is_stopped() && Input.is_action_pressed("ui_accept"):
        close_screen()

func close_screen():
    GameData.hud.show_menu(true, false)
    queue_free()

func _on_timer_timeout() -> void:
    close_screen()
