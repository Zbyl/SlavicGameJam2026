extends Control
@onready var player_enable: CheckBox = $GridContainer/Kunek/Buttons/PlayerEnable
@onready var kunek: HBoxContainer = $GridContainer/Kunek
@onready var ferret: HBoxContainer = $GridContainer/Ferret
@onready var weasel: HBoxContainer = $GridContainer/Weasel
@onready var snow: HBoxContainer = $GridContainer/Snow
@onready var dudes = [kunek, ferret, weasel, snow]
@onready var ok_button: Button = $GridContainer/OkButton
@onready var timer: Timer = $Timer

var playerData = {}

func  _ready() -> void:
    player_enable.grab_focus.call_deferred()
    playerData = GameData.hud.playerData
    timer.start()

func updateControls(idx:int, keyMap: Dictionary):
    print("updateControls")
    playerData[idx]=keyMap
    for key in playerData.keys():
        if playerData[key].keys().size()==0:
            playerData.erase(key)

    ok_button.disabled = !validate()

func validateKeyMap(map: Dictionary) -> bool:
    print("Validate")
    print(map)
    var type:String =  map.get("type", "")

    if type=="pad":
        var padNum:int = map.get("pad", -1)
        return padNum>=0 && padNum<=3
    elif type=="keyboard":
        return map.get("up", -1)!=-1 && \
            map.get("down", -1)!=-1 && \
            map.get("left", -1)!=-1 && \
            map.get("right", -1)!=-1 && \
            map.get("jump", -1)!=-1 && \
            map.get("duck", -1)!=-1
    return false

func validate():
    var count = 0
    for key in playerData.keys():
        count+=1
        if !validateKeyMap(playerData[key]):
            return false
    return count>0


func _on_ok_button_pressed() -> void:
    GameData.hud.updatePlayerData(playerData)
    queue_free()


func _on_cancel_button_pressed() -> void:
    queue_free()


func _on_timer_timeout() -> void:
    for key in playerData.keys():
        dudes[key].initiateWithData(playerData[key])
    ok_button.disabled = !validate()
