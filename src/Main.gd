extends Control
# docstring

# NOTE: For public releases use Countdown2 audio, and Comedian2 sprite.


enum STATE {READY, STARTING, PLAYING, FINISHED}


const RIDDLES = [
		["ACESPANK", "PANCAKES", "Give them a toss"],
		["DEERNUTS", "DENTURES", "Keep them in your mouth"],
		["BUMDATER", "DRUMBEAT", "Give it a tap"],
		["FINENUTS", "FUNNIEST", "Describes me perfectly"],
		["BUMSINGE", "BEMUSING", "It's a peculiar feeling"],
		["STICKYJO", "JOYSTICK", "Will give you a good time"],
		["BEDOSMAN", "ABDOMENS", "The harder the better"],
		["BEDSOWET", "BESTOWED", "A gift from me to you"],
		["NUDEFRED", "REFUNDED", "Get what you deserve"],
		["LICKPITS", "LIPSTICK", "Get this round your mouth"],
		["NEATPOLE", "ANTELOPE", "Watch out for the horn"],
		["OHMYKNOB", "HYMNBOOK", "Often held by a priest"],
		["LIKEWANG", "WEAKLING", "A bit soft"],
		["ORALNITE", "RELATION", "Keep it in the family"],
		["IDLEPOOS", "POOLSIDE", "My favourite way to relax"],
		["TASTENIP", "PATIENTS", "There's probably a waiting list"],
		["BUMNIGHT", "THUMBING", "No fingers allowed"],
		["HARDSEMI", "MISHEARD", "Not always easy to grasp"],
		["BUMHEADS", "AMBUSHED", "Taken by surprise"],
		["NOBALARM", "ABNORMAL", "That's not right"],
		["RUDENOBS", "REBOUNDS", "People like these after a break-up"],
		["IBUMPETS", "BUMPIEST", "Not a smooth ride"],
		["LUBETITS", "SUBTITLE", "Making things easier"],
		["ASSGAMES", "MASSAGES", "Loosen up the muscles"],
		["NUDEFRED", "REFUNDED", "Get what you deserve"],
		["COCKTRAP", "CRACKTOP", "It's fun to have one of these around"],
		["PENISTIP", "NIPPIEST", "Fancy a quick one"],
		["FREEDUMP", "PERFUMED", "Smells pretty good"],
		["SENDBUMS", "DUMBNESS", "I like them thick"],
		["GIANTLOG", "GLOATING", "I'm just showing off"],
		["SHITPOLL", "HILLTOPS", "The only way is up"],
		["VOTEARSE", "OVEREATS", "Shove it all in"],
		#["", "", ""],
	]

const START_SPEECH = [
		"Here is your teaser..",
		"The words are %s",
		'And the clue is "%s"',
		"Your time starts.. now!"
	]

const PLAYING_SPEECHES = [
		["Your Mum.."],
		["Ha ha haaa!"],
		["..her? I hardly know her."],
		["Let's play Countdown!"],
		#["TNETENNBA"],
		#["0204060810121416182022242628303234"],
	]
#~35 chars  -- doesn't really flow well, need one screen versions.
#I did a sponsored walk once. In the end, I’d managed to raise so much money, I could afford a taxi.
#I had a survey done on my house. 8 out of 10 people said they really rather liked it
#I'm not being condescending, I'm too busy thinking about far more important things you wouldn't understand.
#When you eat a lot of spicy food, you can lose your taste. When I was in India last summer, I was listening to a lot of Michael Bolton.
#I love watching horror films while hiding behind the sofa… that way my neighbors don’t know I’m there.
#When I told my mom I wanted to grow up and be a comedian, she said you can’t do both.
#Swimming is good for you… especially if you’re drowning.

const FINISH_SPEECH = [
		"Let's see how you went..",
		"The words were %s",
		'And the clue was "%s"',
		"It was of course %s."
	] 

const BUTTON_TEXT = {
		STATE.READY: "PLAY",
		STATE.STARTING: "",
		STATE.PLAYING: "LOCK IT IN",
		STATE.FINISHED: "",
	}

const TOTAL_LETTERS = 8
const MAX_TIME = 30.0
const DISTRACT_TIME = 2.7


var _state = STATE.READY
var _sliding_letter = null
var _time_remaining
var _distract_texts = []
var _initial_positions = []
var _word
var _clue
var _answer


onready var countdown = $Countdown/Countdown2 ## Change depending on public/private.
onready var button = $Controls/Center/ActionButton
onready var clock_hand = $Middle/Center/ClockHand
onready var speech = $Middle/Center/SpeechBubble/Label
onready var letters = [
		$Controls/Center/Letter1,
		$Controls/Center/Letter2,
		$Controls/Center/Letter3,
		$Controls/Center/Letter4,
		$Controls/Center/Letter5,
		$Controls/Center/Letter6,
		$Controls/Center/Letter7,
		$Controls/Center/Letter8,
	]


##


func _ready():
	randomize()
	for letter in letters:
		_initial_positions.append(letter.position)
		letter.connect("sliding_started", self, "_sliding_started", [letter])
		letter.connect("sliding_finished", self, "_sliding_finished", [letter])


func _process(delta):
	button.text = BUTTON_TEXT[_state]
	match _state:
		STATE.READY:
			clock_hand.rotation_degrees = -90
		STATE.PLAYING:
			# Distractions.
			_display_text(_distract_texts[int((MAX_TIME - _time_remaining)/DISTRACT_TIME)], 0.0)
			# Actual game.
			_time_remaining -= delta
			if _time_remaining <= 0.0:
				_time_remaining = 0.0
				_finish_game()
			clock_hand.rotation_degrees = -90 + (MAX_TIME - _time_remaining)/MAX_TIME * 180


func _input(event):
	if _sliding_letter != null and event is InputEventMouseMotion:
		var x_dist = abs((event.position - _sliding_letter.global_position).x)
		# Find next closest letter to mouse.
		var min_x_dist = 9999
		var closest_letter = null
		for letter in letters:
			if letter != _sliding_letter:
				var this_x_dist = abs((event.position - letter.global_position).x)
				if this_x_dist < min_x_dist:
					min_x_dist = this_x_dist
					closest_letter = letter
		# If closer than sliding letter then swap them.
		if min_x_dist < x_dist:
			var temp_position = _sliding_letter.global_position
			_sliding_letter.global_position = closest_letter.global_position
			closest_letter.global_position = temp_position


##


func _sliding_started(letter):
	if _state != STATE.PLAYING:
		return
	_sliding_letter = letter


func _sliding_finished(letter):
	_sliding_letter = null


func _on_ActionButton_pressed():
	match _state:
		STATE.READY:
			var tmp = RIDDLES[randi() % RIDDLES.size()]
			_word = tmp[0]
			_answer = tmp[1]
			_clue = tmp[2]
			_state = STATE.STARTING
			yield(_display_start_speech(_word, _clue), "completed")
			_show_letters(_word)
			_state = STATE.PLAYING
			countdown.play()
			_time_remaining = MAX_TIME
			_distract_texts.clear()
			for i in range(int(MAX_TIME/DISTRACT_TIME)+1):
				var texts = PLAYING_SPEECHES[randi() % PLAYING_SPEECHES.size()]
				_distract_texts.push_back("")
				for t in texts:
					_distract_texts.push_back(t)
		STATE.PLAYING:
			_finish_game()


func _finish_game():
	_state = STATE.FINISHED
	countdown.stop()
	yield(get_tree().create_timer(0.8), "timeout")
	yield(_display_finish_speech(_word, _clue, _answer), "completed")
	_show_letters(_answer)
	yield(get_tree().create_timer(3.0), "timeout")
	_state = STATE.READY
	_show_letters("        ")
	_display_text("", 0.0)


func _display_start_speech(word, clue):
	yield(_display_text(START_SPEECH[0],          2.5), "completed")
	yield(_display_text(START_SPEECH[1] % [word], 2.5), "completed")
	yield(_display_text(START_SPEECH[2] % [clue], 2.5), "completed")
	yield(_display_text(START_SPEECH[3],          1.0), "completed")


func _display_finish_speech(word, clue, answer):
	yield(_display_text(FINISH_SPEECH[0],            2.5), "completed")
	yield(_display_text(FINISH_SPEECH[1] % [word],   2.5), "completed")
	yield(_display_text(FINISH_SPEECH[2] % [clue],   2.5), "completed")
	yield(_display_text(FINISH_SPEECH[3] % [answer], 0.0), "completed")


func _display_text(text, delay):
	speech.text = text
	yield(get_tree().create_timer(delay), "timeout")


func _show_letters(word):
	assert(word.length() == TOTAL_LETTERS)
	for i in range(TOTAL_LETTERS):
		letters[i].position = _initial_positions[i]
		letters[i].set_letter(word[i])
