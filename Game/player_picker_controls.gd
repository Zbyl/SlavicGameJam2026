extends HBoxContainer
const INPUT_PICKER = preload("res://input_picker.tscn")

@onready var controls: Button = $Buttons/Controls
@onready var player_enable: CheckBox = $Buttons/PlayerEnable
@onready var player_picker: Control = $"../.."
@onready var settings_info: RichTextLabel = $Buttons/SettingsInfo

var keyMap = {}

func appendInfo(label: String, btn: Button, buttonMap: Dictionary):
    var keyCode: int = buttonMap.get(btn, -1)
    if keyCode!=-1:
        settings_info.newline()
        settings_info.append_text(label+": "+OS.get_keycode_string(keyCode))

func updateControls(picker: Node):
    var controller_type: OptionButton = picker.controller_type
    var selected_controller: OptionButton = picker.selected_controller
    var up: Button = picker.up
    var down: Button = picker.down
    var left: Button = picker.left
    var right: Button = picker.right
    var jump: Button = picker.jump
    var duck: Button = picker.duck
    var buttonMap: Dictionary = picker.buttonMap

    settings_info.text = ""
    if controller_type.selected == 0 && selected_controller.selected>=0:
        settings_info.append_text("Pad "+str(selected_controller.selected+1))
        keyMap["pad"]=selected_controller.selected
        keyMap["type"]="pad"
    elif controller_type.selected == 1:
        settings_info.append_text("Klawiatura")
        appendInfo("▲", up, buttonMap)
        appendInfo("▼", down, buttonMap)
        appendInfo("◄", left, buttonMap)
        appendInfo("►", right, buttonMap)
        appendInfo("skok", jump, buttonMap)
        appendInfo("kucanie", duck, buttonMap)
        keyMap["up"]=buttonMap.get(up, -1)
        keyMap["down"]=buttonMap.get(down, -1)
        keyMap["left"]=buttonMap.get(left, -1)
        keyMap["right"]=buttonMap.get(right, -1)
        keyMap["jump"]=buttonMap.get(jump, -1)
        keyMap["duck"]=buttonMap.get(duck, -1)
        keyMap["type"]="keyboard"
    else:
        settings_info.visible = false
        player_picker.updateControls(self, {})
        return
    settings_info.visible = true
    get_tree().set_group("PlayerControls", "disabled", false)
    get_tree().set_group("PlayerEnable", "disabled", false)
    player_picker.updateControls(self, keyMap)
    controls.grab_focus.call_deferred()


func _on_player_enable_toggled(toggled_on: bool) -> void:

    if toggled_on:
        controls.visible = true
        controls.grab_focus.call_deferred()
        player_picker.updateControls(self, {"type":"unknown"})
    else:
        controls.visible = false
        settings_info.visible = false
        player_picker.updateControls(self, {})

func _on_controls_pressed() -> void:
    get_tree().set_group("PlayerControls", "disabled", true)
    get_tree().set_group("PlayerEnable", "disabled", true)
    var picker = INPUT_PICKER.instantiate()
    picker.player_picker = self
    player_picker.add_child(picker)
