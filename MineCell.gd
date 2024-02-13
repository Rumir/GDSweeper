extends Button

signal mineCellPressed(fieldPos : Vector2)

var fieldPos : Vector2
var numValue := 0
var uncovered := false
var flagged := false
var flagImage : Node

# Called when the node enters the scene tree for the first time.
func _ready():
	toggle_mode = true
	size = Vector2(23,23)
	flagImage = get_node("FlagTexture")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func setPos(pos : Vector2):
	fieldPos = pos

func setGridPos():
	position = Vector2(28 * fieldPos.x + 5, 28 * fieldPos.y + 5)
	visible = true

func uncoverValue(forced : bool):
	if not flagged or forced:
		disabled = true
		if numValue > 0:
			text = str(numValue)
		elif numValue < 0:
			text = "*"
		else:
			text = ""
		uncovered = true

func initialize(pPos : Vector2, pValue : int):
	setPos(pPos)
	numValue = pValue
	
	setGridPos()

func setDisabled(pBool : bool):
	disabled = pBool

func _on_pressed():
	if not flagged:
		mineCellPressed.emit(fieldPos)
		disabled = true

func _isRightClick(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == 2:
			return true
		else:
			return false
		

func toggleFlagOnField():
	if not uncovered:
		var pState = flagged
		toggle_mode = pState
		flagImage.visible = !pState
		flagged = !pState

func _on_gui_input(event):
	if _isRightClick(event):
		toggleFlagOnField()
