extends Control
@onready var player_enable: CheckBox = $GridContainer/Kunek/Buttons/PlayerEnable

func  _ready() -> void:
    player_enable.grab_focus.call_deferred()
