class_name BeerMinigame
extends CanvasLayer

const GOLDEN_ZONE_MIN := 0.6
const GOLDEN_ZONE_MAX := 0.8
const FILL_SPEED := 0.35
const HEAL_PERFECT := 100
const HEAL_LOW := 25
const HEAL_HIGH := 50
const COOLDOWN_SECS := 30.0

var fill_level: float = 0.0
var is_filling: bool = false
var can_play: bool = true
var on_cooldown: bool = false

signal minigame_complete(heal_amount: int)

@onready var fill_bar: ProgressBar = $Background/BarContainer/FillBar
@onready var result_label: PanelContainer = $Background/ResultLabel
@onready var result_text: Label = $Background/ResultLabel/ResultText
@onready var cooldown_label: PanelContainer = $Background/CooldownLabel

func _ready() -> void:
	layer = 10
	visible = false
	add_to_group("beer_minigame")

func open() -> void:
	if on_cooldown:
		if cooldown_label:
			cooldown_label.visible = true
		return
	if not can_play:
		return
	fill_level = 0.0
	is_filling = false
	visible = true
	if result_label:
		result_label.visible = false
		result_text.modulate = Color(1, 1, 1, 1)
	if cooldown_label:
		cooldown_label.visible = false
	_update_fill_bar()

func _process(delta: float) -> void:
	if not visible:
		return
	if is_filling:
		fill_level = min(1.0, fill_level + FILL_SPEED * delta)
		_update_fill_bar()
		if fill_level >= 1.0:
			_release()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("attack"):
		is_filling = true
	if event.is_action_released("attack"):
		_release()

func _release() -> void:
	if not is_filling and fill_level == 0.0:
		return
	is_filling = false
	var heal := _calculate_heal()
	_show_result(heal)
	can_play = false
	on_cooldown = true
	_finish_and_cooldown(heal)

func _finish_and_cooldown(heal: int) -> void:
	await get_tree().create_timer(2.0).timeout
	visible = false
	minigame_complete.emit(heal)
	await get_tree().create_timer(COOLDOWN_SECS).timeout
	on_cooldown = false
	can_play = true

func _calculate_heal() -> int:
	if fill_level >= GOLDEN_ZONE_MIN and fill_level <= GOLDEN_ZONE_MAX:
		return HEAL_PERFECT
	elif fill_level < GOLDEN_ZONE_MIN:
		return HEAL_LOW
	else:
		return HEAL_HIGH

func _update_fill_bar() -> void:
	if fill_bar:
		fill_bar.value = fill_level * 100.0

func _show_result(heal: int) -> void:
	if not result_label or not result_text:
		return
	if heal == HEAL_PERFECT:
		result_text.text = "Perfect Pour!   Full HP restored!"
		result_text.modulate = Color(1.0, 0.9, 0.0)
	elif heal == HEAL_LOW:
		result_text.text = "Too little...  +" + str(heal) + " HP"
		result_text.modulate = Color(1.0, 0.5, 0.5)
	else:
		result_text.text = "Overflow!  +" + str(heal) + " HP"
		result_text.modulate = Color(0.6, 0.85, 1.0)
	result_label.visible = true
