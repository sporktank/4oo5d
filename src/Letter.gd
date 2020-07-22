extends Node2D


signal sliding_started
signal sliding_finished


var _letter = ""


onready var label = $Label


func set_letter(letter):
	_letter = letter
	label.text = letter
	


func _on_Button_button_down():
	emit_signal("sliding_started")


func _on_Button_button_up():
	emit_signal("sliding_finished")
