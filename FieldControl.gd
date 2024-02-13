extends Node

var cells := []
var mines := []
var openCells := 0
var isGameOver := false
var isWinner := false

var apiConnection

const fieldSize = Vector2(10,10)

const cellClass = preload("res://MineCell.tscn")
const apiClass = preload("res://ServerAPIConnection.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	generateCells()
	loadAllCells()
	apiConnection = apiClass.instantiate()
	apiConnection.remote_command_click.connect(_on_remote_command_click_received)
	add_child(apiConnection)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if not isGameOver and not isWinner and openCells == ( fieldSize.x * fieldSize.y) - mines.size():
		print("Winner!")
		isWinner = true
		showAllMinesText()

func createNewAPIConnection():
	apiConnection = null
	apiConnection = apiClass.instantiate()

func generateMines():
	mines = []
	for e in range(10):
		var mineCoord: Vector2
		while true:
			var randoNum = randi() % 100
			@warning_ignore("integer_division")
			mineCoord = Vector2(randoNum % int(fieldSize.x), randoNum / int(fieldSize.y))
			if not mineCoord in mines:
				break
		mines.append(mineCoord)

func generateCells():
	for oldCell in get_tree().get_nodes_in_group("cellButtons"):
		remove_child(oldCell)
	cells = []
	generateMines()
	
	for y in range(fieldSize.y + 2):
		if y < 10:
			cells.append([])
		for x in range(10):
			if y < 10:
				var newCell = cellClass.instantiate()
				newCell.mineCellPressed.connect(_on_mine_cell_mine_cell_pressed)
				newCell.add_to_group("cellButtons")
				newCell.initialize(Vector2(x, y), 0)
				cells[y].append(newCell)
			if y > 1:
				cells[y - 2][x].numValue = calculateCellValue(Vector2(x, y - 2))
	
func calculateCellValue(cellPosition):
	var cellValue := 0
	if cellPosition in mines:
		cellValue = -1
	else:
		for y in range(cellPosition.y - 1, cellPosition.y + 2):
			if y < 0 || y > 9:
				continue
			for x in range(cellPosition.x - 1, cellPosition.x + 2):
				if Vector2(x, y) == cellPosition:
					continue
				if x < 0 || x > 9:
					continue
				if Vector2(x, y) in mines:
					cellValue += 1
	return cellValue

func addCellInField(cell):
	add_child(cell)
	

func loadAllCells():
	for e in cells:
		for f in e:
			addCellInField(f)

func _on_mine_cell_mine_cell_pressed(fieldPos):
	if not isGameOver and not isWinner:
		var cell = cells[fieldPos.y][fieldPos.x]
		uncoverCell(cell)

func uncoverCell(cell):
	if not cell.flagged:
		if cell.numValue < 0 and not isGameOver:
			print("GameOver")
			isGameOver = true
			uncoverAllCells()
		if not cell.uncovered:
			openCells += 1
			cell.uncoverValue(isGameOver)
			if not isGameOver and cell.numValue == 0:
				uncoverSurroundingCells(cell)

func uncoverSurroundingCells(cell):
	var xPos = cell.fieldPos.x
	var yPos = cell.fieldPos.y
	for y in range(yPos - 1, yPos + 2):
		if y >= fieldSize.y or y < 0:
			continue
		for x in range(xPos - 1, xPos + 2):
			if x >= fieldSize.x or x < 0:
				continue
			var tCell = cells[y][x]
			if not tCell.fieldPos == cell.fieldPos:# and not tCell in openCells:
				uncoverCell(tCell)

func uncoverAllMines():
	for e in mines:
		cells[e.y][e.x].uncoverValue(true)
	get_tree().call_group("cellButtons","setDisabled",true)
	
func showMineText(cell):
	if cell.fieldPos in mines:
		if not cell.uncovered:
			cell.text = "*"

func showAllMinesText():
	for e in mines:
		showMineText(cells[e.y][e.x])
	
func uncoverAllCells():
	get_tree().call_group("cellButtons","uncoverValue",true)

func newGame():
	isGameOver = false
	isWinner = false
	openCells = 0
	generateCells()
	loadAllCells()

func _on_new_game_button_pressed():
	newGame()

func getCell(cellPos : Vector2):
	return cells[cellPos.y][cellPos.x]

func _on_test_listening_button_pressed():
	print(apiConnection.isListening())

func messagePeer(peer : PacketPeerUDP, message : String):
	peer.put_packet(message.to_utf8_buffer())

func _on_remote_command_click_received(peer : PacketPeerUDP, cellPos : Vector2):
	var cell = getCell(cellPos)
	if not cell.uncovered:
		uncoverCell(cell)
		if not cell.flagged:
			pass #todo
		if not isGameOver:
			if not isWinner:
				messagePeer(peer,"RESPONSE_GOOD")
			else:
				messagePeer(peer,"RESPONSE_WINNER")
		else:
			messagePeer(peer,"RESPONSE_GAMEOVER")
	else:
		messagePeer(peer,"RESPONSE_INVALID")
	
