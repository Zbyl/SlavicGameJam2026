extends Control
const OPTION_NONE = -1
const OPTION_CONTROLLER = 0
const OPTION_KEYBOARD = 1

@export var player_picker : Node
@onready var controller_type: OptionButton = $VBoxContainer/ControllerType
@onready var selected_controller: OptionButton = $VBoxContainer/SelectedController
@onready var press_something: Button = $VBoxContainer/PressSomething
@onready var ok_button: Button = $VBoxContainer/OkButton
@onready var up: Button = $VBoxContainer/GridContainer/Up
@onready var left: Button = $VBoxContainer/GridContainer/Left
@onready var right: Button = $VBoxContainer/GridContainer/Right
@onready var down: Button = $VBoxContainer/GridContainer/Down
@onready var jump: Button = $VBoxContainer/SplitContainer/Jump
@onready var duck: Button = $VBoxContainer/SplitContainer2/Duck

@onready var buttons = {
    "up": up,
    "down": down,
    "left": left,
    "right": right,
    "jump": jump,
    "duck": duck,
}

var originalLabels = {
    "up": "▲",
    "down": "▼",
    "left": "◄",
    "right": "►",
    "jump": "?",
    "duck": "?"
}

var keyboardPresets: Array[Dictionary] = [
    GameData.KEYBOARD_PLAYER_ARROWS_WIDE,
    GameData.KEYBOARD_PLAYER_ARROWS_TIGHT,
    GameData.KEYBOARD_PLAYER_WSAD,
    GameData.KEYBOARD_PLAYER_IKJL,
    GameData.KEYBOARD_PLAYER_NUMPAD,
]

var waitForKey = false
var buttonWaiting: String

func _ready() -> void:
    pass

func initiateWithdata(keyMap):
    var typ = keyMap.get("type", "")
    if typ == "pad":
        changeControllerType.call_deferred(OPTION_CONTROLLER)
    elif typ == "keyboard":
        changeControllerType.call_deferred(OPTION_KEYBOARD)
    else:
        changeControllerType.call_deferred(OPTION_NONE)

func updateUI():
    var keyMap: Dictionary = player_picker.keyMap
    var typ = keyMap.get("type", "")
    if typ == "pad":
        press_something.visible = false
        controller_type.selected = OPTION_CONTROLLER
        selected_controller.selected = keyMap.get("pad", 0)
    elif typ == "keyboard":
        press_something.visible = false
        controller_type.selected = OPTION_KEYBOARD
        %SelectedKeyboardMapping.selected = detectKeyboardPreset()

        var upCode = keyMap.get("up", -1)
        var downCode = keyMap.get("down", -1)
        var leftCode = keyMap.get("left", -1)
        var rightCode = keyMap.get("right", -1)
        var jumpCode = keyMap.get("jump", -1)
        var duckCode = keyMap.get("duck", -1)

        up.text = OS.get_keycode_string(upCode) if upCode!=-1 else originalLabels["up"]
        down.text = OS.get_keycode_string(downCode) if downCode!=-1 else originalLabels["down"]
        left.text = OS.get_keycode_string(leftCode) if leftCode!=-1 else originalLabels["left"]
        right.text = OS.get_keycode_string(rightCode) if rightCode!=-1 else originalLabels["right"]
        jump.text = OS.get_keycode_string(jumpCode) if jumpCode!=-1 else originalLabels["jump"]
        duck.text = OS.get_keycode_string(duckCode) if duckCode!=-1 else originalLabels["duck"]
    else:
        press_something.visible = true
        controller_type.selected = OPTION_NONE

    enableGroup("ControllerCtrl", controller_type.selected == OPTION_CONTROLLER)
    enableGroup("KeyboardCtrl", controller_type.selected == OPTION_KEYBOARD)


func changeControllerType(index: int):
    if index == OPTION_KEYBOARD:
        #selected_controller.selected = -1
        if player_picker.keyMap.get("type", "") != "keyboard":
            player_picker.keyMap = GameData.KEYBOARD_PLAYER_ARROWS_WIDE.duplicate()
        up.grab_focus.call_deferred()
    elif index == OPTION_CONTROLLER:
        #resetKeyboardMapping()
        if player_picker.keyMap.get("type", "") != "pad":
            player_picker.keyMap = GameData.PAD_PLAYER_0.duplicate()
        ok_button.grab_focus.call_deferred()
    else:
        press_something.grab_focus.call_deferred()

    updateUI()


func enableGroup(groupName, enabled):
    var objects = get_tree().get_nodes_in_group(groupName)
    for obj in objects:
        obj.visible = enabled

func _on_controller_type_item_selected(index: int) -> void:
    changeControllerType(index)

# Handler of press_something button - used to detect pad/keyboard.
func _on_press_something_gui_input(event: InputEvent) -> void:
    if event is InputEventKey:
        changeControllerType(OPTION_KEYBOARD)
    elif event is InputEventJoypadButton:
        changeControllerType(OPTION_CONTROLLER)
        selected_controller.select(event.device)
        player_picker.keyMap.set("pad", event.device)


func waitFor(key: String):
    waitForKey = true
    buttonWaiting = key
    buttons[key].text = "-?-"
    buttons[key].disabled = true

func resetKeyboardMapping():
    up.text = originalLabels["up"]
    down.text = originalLabels["down"]
    left.text = originalLabels["left"]
    right.text = originalLabels["right"]
    jump.text = originalLabels["jump"]
    duck.text = originalLabels["duck"]


# Detect which key was pressed, and assign it to "buttonWaiting" button.
func _on_keyboard_input(event: InputEvent) -> void:
    if waitForKey && event is InputEventKey:
        waitForKey = false
        # If we pressed key that was already assigned to something else, clear that something else.
        for key in player_picker.keyMap.keys():
            if typeof(player_picker.keyMap[key])==TYPE_INT && player_picker.keyMap[key] == event.keycode:
                player_picker.keyMap.erase(key)
                buttons[key].text = originalLabels[key]
        buttons[buttonWaiting].text = event.as_text_key_label()
        player_picker.keyMap.set(buttonWaiting, event.keycode)
        buttons[buttonWaiting].disabled = false
        buttonWaiting = ""
        get_viewport().set_input_as_handled()
        
        updateUI()

func detectKeyboardPreset():
    for index in keyboardPresets.size():
        if player_picker.keyMap == keyboardPresets[index]:
            return index + 1
    return 0

func _on_selected_controller_item_selected(index: int) -> void:
    if (index < 0) || (index > 3):
        return
    var previous = player_picker.keyMap.get("pad", -1)
    if previous == index:
        return
    player_picker.keyMap.set("pad", index)
    updateUI()

func _on_selected_keyboard_mapping_item_selected(index: int) -> void:
    if controller_type.selected != OPTION_KEYBOARD:
        return
    var presets: Array[Dictionary] = [player_picker.keyMap]
    for preset in keyboardPresets:
        presets.append(preset.duplicate())
    if player_picker.keyMap == presets[index]:
        return
    player_picker.keyMap = presets[index]
    updateUI()

func _on_up_pressed() -> void:
    waitFor("up")

func _on_left_pressed() -> void:
    waitFor("left")

func _on_right_pressed() -> void:
    waitFor("right")

func _on_down_pressed() -> void:
    waitFor("down")

func _on_jump_pressed() -> void:
    waitFor("jump")

func _on_duck_pressed() -> void:
    waitFor("duck")


func _on_ok_button_pressed() -> void:
    if player_picker:
        queue_free()
    else:
        get_tree().quit()
