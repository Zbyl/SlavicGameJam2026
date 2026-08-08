extends HBoxContainer
const INPUT_PICKER = preload("res://input_picker.tscn")

@onready var controls: Button = $Buttons/Controls
@onready var player_enable: CheckBox = $Buttons/PlayerEnable
@onready var player_picker: Control = $"../.."
@onready var settings_info: RichTextLabel = $Buttons/SettingsInfo

func updateControls(picker: Node):
    print("Huzaah!")
    var controller_type: OptionButton = picker.controller_type
    var selected_controller: OptionButton = picker.selected_controller
    settings_info.text = ""
    if controller_type.selected == 0 && selected_controller.selected>=0:
        settings_info.append_text("Pad "+str(selected_controller.selected+1))
    elif controller_type.selected == 1:
        settings_info.append_text("Klawiatura")
    else:
        settings_info.visible = false
        return
    settings_info.visible = true
    controls.grab_focus.call_deferred()


func _on_player_enable_toggled(toggled_on: bool) -> void:
    if toggled_on:
        controls.visible = true
        controls.grab_focus.call_deferred()
    else:
        controls.visible = false
        settings_info.visible = false


func _on_controls_pressed() -> void:
    var picker = INPUT_PICKER.instantiate()
    picker.player_picker = self
    player_picker.add_child(picker)
