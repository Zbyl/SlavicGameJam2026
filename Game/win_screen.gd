extends CanvasLayer
const WIN_DUDE = preload("res://win_dude.tscn")
const CIRCLE_RADIUS = 100.0
const CIRCLE_CENTER = Vector2(0.5, 0.8)
const NAME_INDEXES = {
    "Fox": 0,
    "Ferret": 1,
    "Weasel": 2,
    "Snow": 3
}

@export var dudes: Array = ["Fox", "Snow", "Weasel", "Ferret"]
@onready var mandatory_timer: Timer = $MandatoryTimer
@onready var greeting: TextureRect = $Greeting

func _ready() -> void:
    #GameData.hud.gauges.visible = false
    greeting.modulate.a = 0.0
    var greeting_tween = create_tween().set_trans(Tween.TRANS_EXPO)
    greeting_tween.tween_property(greeting, "modulate:a", 1.0, 5.0)

    var idx = 0
    for dude in dudes:
        var win_dude: Node2D = WIN_DUDE.instantiate()
        win_dude.win = idx==0
        win_dude.character = dude
        win_dude.playerIndex = NAME_INDEXES[dude]
        win_dude.dir = 1+8*idx/dudes.size()
        if win_dude.dir > 8:
            win_dude.dir -= 8
        win_dude.global_position = GameData.game.get_viewport_rect().size * CIRCLE_CENTER + (Vector2(1, -1) * CIRCLE_RADIUS).rotated(2.0*idx*PI/dudes.size())/Vector2(1.0, 2.0)
        add_child(win_dude)
        idx += 1

func _process(delta: float) -> void:
    if mandatory_timer.is_stopped() && Input.is_action_pressed("ui_accept"):
        close_screen()

func close_screen():
    GameData.hud.show_menu(true, false)
    queue_free()

func _on_timer_timeout() -> void:
    close_screen()
