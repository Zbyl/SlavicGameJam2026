extends HBoxContainer
const INPUT_PICKER = preload("res://input_picker.tscn")
const UNKNOWN = {}

@export var playerIndex: int
@onready var controls: Button = $Buttons/Controls
@onready var player_enable: CheckBox = $Buttons/PlayerEnable
@onready var player_picker: Control = $"../.."
@onready var settings_info: RichTextLabel = $Buttons/SettingsInfo

var keyMap = UNKNOWN.duplicate()

func initiateWithData(data: Dictionary):
    player_enable.button_pressed = true
    controls.visible = true
    keyMap = data
    updateSettingsInfoText(data)

func appendInfo(label: String, keyCode):
    if keyCode!=-1:
        settings_info.newline()
        settings_info.append_text(label+": "+OS.get_keycode_string(keyCode))

func _on_player_picker_destroy():
    updateSettingsInfoText(keyMap)

    get_tree().set_group("PlayerControls", "disabled", false)
    get_tree().set_group("PlayerEnable", "disabled", false)
    print("update controls")
    print(playerIndex)
    print(keyMap)
    player_picker.updateControls(playerIndex, keyMap)
    controls.grab_focus.call_deferred()

func updateSettingsInfoText(keyMapParam: Dictionary):
    settings_info.text = ""
    if keyMapParam.has("type") && keyMapParam["type"]=="pad":
        settings_info.append_text("Pad "+str(keyMapParam["pad"]+1))
    elif keyMapParam.has("type") && keyMapParam["type"]=="keyboard":
        settings_info.append_text("Klawiatura")
        appendInfo("▲", keyMapParam.get("up", -1))
        appendInfo("▼", keyMapParam.get("down", -1))
        appendInfo("◄", keyMapParam.get("left", -1))
        appendInfo("►", keyMapParam.get("right", -1))
        appendInfo("skok", keyMapParam.get("jump", -1))
        appendInfo("gadanie", keyMapParam.get("duck", -1))
    else:
        settings_info.visible = false
        player_picker.updateControls(playerIndex, UNKNOWN.duplicate())
        return
    settings_info.visible = true


func _on_player_enable_toggled(toggled_on: bool) -> void:

    if toggled_on:
        controls.visible = true
        controls.grab_focus.call_deferred()
    else:
        controls.visible = false
        settings_info.visible = false
        keyMap = UNKNOWN.duplicate()
        player_picker.updateControls(playerIndex, keyMap)

func _on_controls_pressed() -> void:
    get_tree().set_group("PlayerControls", "disabled", true)
    get_tree().set_group("PlayerEnable", "disabled", true)
    var picker = INPUT_PICKER.instantiate()
    picker.player_picker = self
    picker.tree_exited.connect(_on_player_picker_destroy)
    player_picker.add_child(picker)
    if keyMap.has("type") && keyMap["type"] != "unknown":
        picker.initiateWithdata(keyMap)
