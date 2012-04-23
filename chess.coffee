###
* Batman Chess
* By github.com/studentIvan
###
class Player
  selectedCell: 0
  isComputer: false
  myTurn: false
  myColor: 'white'
  board: 0
  check: false # шах
  myUnits: []
  variants: []

  setColor: (color) -> @myColor = color
  getColor: -> @myColor
  setBoard: (board) -> @board = board

  startTurn: ->
    @board.calculateAttackPositions()

    @myUnits = []
    @variants = []

    for y in [8..1]
      for x in [1..8]
        if @myColor is @board.cell(x, y).figure.color then @myUnits.push(@board.cell(x, y).figure)

    for unit in @myUnits
      for y in [8..1]
        for x in [1..8]
          if not (y is unit.posY and x is unit.posX)
            offsetX = if x > unit.posX then (x - unit.posX) else ((unit.posX - x)*-1)
            offsetY = if y > unit.posY then (y - unit.posY) else ((unit.posY - y)*-1)
            a1 = unit.checkMovementCorrect(offsetX, offsetY)
            state = a1
            if @isComputer and a1 then console.log(unit, offsetX, offsetY, unit.checkMovementCorrect(offsetX, offsetY))
            # FUCK OFF
            #state = @board.correctTurnPath(unit, @board.cell(x, y), offsetX, offsetY)
            if state then @variants.push({unit: unit, x: offsetX, y: offsetY, i: 0, p: 0})

    if @variants.length is 0
      alert(@board.nextPlayer.getColor() + ' player win')
      return false

    if @isComputer
      return @computerTurn()
    else
      @myTurn = true

  finishTurn: ->
    @myTurn = false

  computerTurn: ->
    targetX = 1
    targetY = 1
    selectedX = 1
    selectedY = 1
    enemyColor = @board.nextPlayer.getColor()

    ###for variant in @variants
      targetCell = @board.cell(variant.unit.posX + variant.x, variant.unit.posY + variant.y)
      variant.i = 110
      if targetCell.attacked[enemyColor] then variant.i -= variant.unit.price
      if targetCell.figure.color is enemyColor then variant.i += targetCell.figure.price

      variant.unit.posX += variant.x
      variant.unit.posY += variant.y

      for y in [8..1]
        for x in [1..8]
          if not (y is variant.unit.posY and x is variant.unit.posX)
            offsetX = if x > variant.unit.posX then (x - variant.unit.posX) else ((variant.unit.posX - x)*-1)
            offsetY = if y > variant.unit.posY then (y - variant.unit.posY) else ((variant.unit.posY - y)*-1)
            if variant.unit.checkAttackCorrect(offsetX, offsetY)
              if @board.scanPath(variant.unit, offsetX, offsetY)
                variant.i += Math.floor(@board.cell(variant.unit.posX, variant.unit.posY).figure.price / 10)

      variant.unit.posX -= variant.x
      variant.unit.posY -= variant.y

    max = -120

    for variant in @variants
      if variant.i > max then max = variant.i

    best = []

    for variant in @variants
      variant.p = if variant.i is max then 100 else Math.floor((variant.i / max) * 100)
      if variant.p is 100 then best.push(variant)

    computerTurn = 0
    if best.length > 1
      z = Math.floor(Math.random() * (best.length + 1)) - 1
      computerTurn = best[if z < 1 then 0 else z]
    else
      computerTurn = best[0]

    console.log(@variants)###

    computerTurn = @variants[0]

    targetX = computerTurn.unit.posX + computerTurn.x
    targetY = computerTurn.unit.posY + computerTurn.y
    selectedX = computerTurn.unit.posX
    selectedY = computerTurn.unit.posY

    {fX: selectedX, fY: selectedY, tX: targetX, tY: targetY}

class AIPlayer extends Player
  isComputer: true

class ChessBoard
  map: {}
  side: 400
  step: 50
  clBlack: '#765'
  clWhite: '#eee'
  alphabet: ['_', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']
  whitePlayer: 0
  blackPlayer: 0
  currentPlayer: 0
  nextPlayer: 0
  slug: 0

  constructor: (side) ->
    boardCanvas = document.getElementById('chess')
    if (@rc = boardCanvas.getContext('2d'))
      if side
        @side = side
        @step = Math.floor(@side/8)
      boardCanvas.height = boardCanvas.width = @side + Math.floor(@side / 10) + 1
      @redraw()
      that = this
      boardCanvas.onclick = (event) ->
        eX = if event.clientX? then event.clientX else event.pageX;
        eY = if event.clientY? then event.clientY else event.pageY;
        cellX = Math.floor((eX - Math.floor(that.side / 10)) / that.step) + 1;
        cellY = ((Math.floor((eY - Math.floor(that.side / 10)) / that.step) + 1) - 9) * -1;
        if (cellX < 1) then cellX = 1 else if (cellX > 8) then cellX = 8
        if (cellY < 1) then cellY = 1 else if (cellY > 8) then cellY = 8
        that.click(cellX, cellY)
      @slug = new Figure('hasNoColor', 0, 0)
    else
      alert('Your browser not support canvas')

  isEmptyCell: (cell) -> cell.figure is @slug

  correctTurnPath: (figure, cell, offsetX, offsetY) ->
    if (figure.checkMovementCorrect(offsetX, offsetY) and @isEmptyCell(cell)) or
    (@nextPlayer.getColor() is cell.figure.color and figure.checkAttackCorrect(offsetX, offsetY))
      if @currentPlayer.check
        if @scanPath(figure, offsetX, offsetY)
          xcell = @cell(figure.posX, figure.posY)
          tmpFigure = xcell.figure
          xcell.figure = @slug
          figure.posX += offsetX
          figure.posY += offsetY
          x2cell = @cell(figure.posX, figure.posY)
          tmp2Figure = x2cell.figure
          x2cell.figure = figure
          figure.posX -= offsetX
          figure.posY -= offsetY
          @calculateAttackPositions()
          r = !@currentPlayer.check
          x2cell.figure = tmp2Figure
          xcell.figure = tmpFigure
          @calculateAttackPositions(false)
          if r then console.info('avoid')
          return r
        else
          return false
      else
        return @scanPath(figure, offsetX, offsetY)
    else
      return false

  scanPath: (figure, offsetX, offsetY) ->
    # алгоритм поиска препядствий
    if figure.canPassThrough
      if figure.debug then console.log('%s can pass through', figure.name)
      return true
    else
      if figure.debug then console.log('start searching algorythm for %s', figure.name)
      targetX = figure.posX + offsetX
      targetY = figure.posY + offsetY
      currentX = figure.posX
      currentY = figure.posY
      while not (currentX is targetX and currentY is targetY)
        if currentX isnt targetX
          if targetX > currentX then currentX++
          if targetX < currentX then currentX--
        if currentY isnt targetY
          if targetY > currentY then currentY++
          if targetY < currentY then currentY--
        if figure.debug then console.log('currentX is %d of %d, currentY is %d of %d', currentX, targetX, currentY, targetY)
        if !@isEmptyCell(@cell(currentX, currentY))
          return (currentX is targetX and currentY is targetY)
      return true

  click: (x, y) ->
    cell = @cell(x, y)

    console.log("%s player click on: x %d, y %d (%s) (%s)",
      @currentPlayer.getColor(), x, y, cell.name, if cell.clear then 'clear' else 'figure')

    selected = @currentPlayer.selectedCell
    if (((selected isnt 0) and (selected.name isnt cell.name)) or @currentPlayer.isComputer)
      figure = selected.figure
      offsetX = if x > figure.posX then (x - figure.posX) else ((figure.posX - x)*-1)
      offsetY = if y > figure.posY then (y - figure.posY) else ((figure.posY - y)*-1)
      if @correctTurnPath(figure, cell, offsetX, offsetY)
        figure.move(offsetX, offsetY)
        @currentPlayer.selectedCell = 0
        @currentPlayer.finishTurn()
        result = @nextPlayer.startTurn()
        tmpPlayer = @currentPlayer
        @currentPlayer = @nextPlayer
        @nextPlayer = tmpPlayer
        if result.tX?
          @currentPlayer.selectedCell = @cell(result.fX, result.fY)
          console.log("%s player click on: x %d, y %d (%s) (%s)",
            @currentPlayer.getColor(), result.fX, result.fY, @currentPlayer.selectedCell.name, 'figure')
          that = this
          callback = -> that.click(result.tX, result.tY)
          setTimeout callback, 1000
      else
        console.log("wrong turn try again")
        @currentPlayer.selectedCell = 0
    else
      if (!cell.clear and (cell.figure.color is @currentPlayer.getColor()))
        @currentPlayer.selectedCell = cell

  cell: (x, y, data) ->
    if data then @map['x' + x + 'y' + y] = data else return @map['x' + x + 'y' + y]

  redraw: ->
    offsetXY = @side / 10
    cellBlack = false
    cursorY = offsetXY
    @rc.font = Math.floor(@step/4) + 'px sans-serif'
    for y in [8..1]
      cursorX = offsetXY
      @rc.strokeText(y, offsetXY - Math.floor(@step/3.2), cursorY + Math.floor(@step/2))
      for x in [1..8]
        if y is 8 then @rc.strokeText(@alphabet[x], cursorX + Math.floor(@step/2), offsetXY - Math.floor(@step/3.2))
        @rc.fillStyle = if cellBlack then @clBlack else @clWhite
        @cell(x, y, {black: cellBlack, name: @alphabet[x] + y,
        clear: true, x: cursorX, y: cursorY, figure: @slug,
        attacked: {'white': false, 'black': false}})
        cellBlack = !cellBlack
        @rc.fillRect(cursorX, cursorY, @step, @step)
        cursorX += @step
      cellBlack = !cellBlack
      cursorY += @step
    @rc.lineWidth = 2
    @rc.strokeStyle = @clBlack
    @rc.strokeRect(offsetXY, offsetXY, @side-4, @side-4)
    #console.log("board redrawed")

  calculateAttackPositions: (lmao) ->
    y = x = 1 #phpStorm bug
    @currentPlayer.check = false
    @nextPlayer.check = false

    for y in [8..1]
      for x in [1..8]
        cell = @cell(x, y)
        cell.attacked['white'] = false
        cell.attacked['black'] = false

    for y in [8..1]
      for x in [1..8]
        cell = @cell(x, y)
        if !@isEmptyCell(cell)
          figure = cell.figure
          for fRy in [8..1]
            for fRx in [1..8]
              if not (fRy is figure.posY and fRx is figure.posX)
                offsetX = if fRx > figure.posX then (fRx - figure.posX) else ((figure.posX - fRx)*-1)
                offsetY = if fRy > figure.posY then (fRy - figure.posY) else ((figure.posY - fRy)*-1)
                debugOffed = false
                if figure.debug
                  figure.debug = false
                  debugOffed = true
                attackState = figure.checkAttackCorrect(offsetX, offsetY)
                if attackState
                  if @scanPath(figure, offsetX, offsetY)
                    c = @cell(fRx, fRy)
                    c.attacked[figure.color] = true
                    if (c.figure.king) and (c.figure.color isnt figure.color)
                      player = if @currentPlayer.getColor() is c.figure.color then @currentPlayer else @nextPlayer
                      player.check = true
                      if lmao? then console.info('check for %s player', player.getColor())
                if debugOffed then figure.debug = true
    true

  place: (figure) ->
    if figure.board is 0 then figure.board = this
    @clearCell(figure.posX, figure.posY)
    @rc.strokeStyle = if figure.color is 'white' then 'black' else 'white'
    @rc.font = @step + 'px sans-serif'
    @rc.fillStyle = figure.color
    cell = @cell(figure.posX, figure.posY);
    @rc.strokeText(figure.symbol(), cell.x, cell.y + @step - (@step / 8))
    @rc.fillText(figure.symbol(), cell.x, cell.y + @step - (@step / 8))
    cell.clear = false
    cell.figure = figure
    true

  clearCell: (x, y) ->
    cell = @cell(x, y)
    @rc.fillStyle = if cell.black then @clBlack else @clWhite
    @rc.fillRect(cell.x, cell.y, @step, @step)
    cell.clear = true
    cell.figure = @slug
    true

  move: (figure, offsetX, offsetY) ->
    @clearCell(figure.posX, figure.posY)
    figure.posX += offsetX
    figure.posY += offsetY
    @place(figure)
    console.info("%s figure %s moved from %s to %s", figure.color, figure.name,
      @alphabet[(figure.posX - offsetX)] + (figure.posY - offsetY).toString(),
      @alphabet[figure.posX] + figure.posY)

  newGame: (whitePlayer, blackPlayer) ->
    if !whitePlayer or !blackPlayer then alert('fatal error')
    console.log("new game started")
    @whitePlayer = whitePlayer
    @whitePlayer.setColor('white')
    @whitePlayer.setBoard(this)
    @blackPlayer = blackPlayer
    @blackPlayer.setColor('black')
    @blackPlayer.setBoard(this)
    @currentPlayer = @whitePlayer
    @nextPlayer = @blackPlayer
    @redraw()

    for x in [1..8]
      @place(new Pawn('black', x, 7))
      @place(new Pawn('white', x, 2))

    @place(new King('black', 5, 8))
    @place(new King('white', 5, 1))
    @place(new Queen('black', 4, 8))
    @place(new Queen('white', 4, 1))
    @place(new Rook('black', 1, 8))
    @place(new Rook('black', 8, 8))
    @place(new Rook('white', 1, 1))
    @place(new Rook('white', 8, 1))
    @place(new Knight('black', 2, 8))
    @place(new Knight('black', 7, 8))
    @place(new Knight('white', 2, 1))
    @place(new Knight('white', 7, 1))
    @place(new Bishop('black', 3, 8))
    @place(new Bishop('black', 6, 8))
    @place(new Bishop('white', 3, 1))
    @place(new Bishop('white', 6, 1))

    @currentPlayer.startTurn()
    true

###
  IR
  inverse relation
  <a,b> = <b,a>

  FF
  full freedom <a,b> (x, y)
  +a e A, -a e A,  +b e A, -b e A

  HF
  half freedom <a,b> (x)
  +a e A, -a e A, +b e A

  ER
  equivalence relation
  a = b
###

class Figure
  price: 0
  posX: 0
  posY: 0
  color: 'black'
  board: 0
  turns: []
  attacks: []
  canPassThrough: false
  debug: false
  king: false

  constructor: (c, x, y) ->
    @color = c
    @posX = x
    @posY = y
    turn.status = true for turn in @turns
    attack.status = true for attack in @attacks

    for turn in @turns
      if turn.IR and turn.x isnt turn.y
        turn.IR = false
        newTurn = {ER:turn.ER, IR:false, FF:turn.FF, HF:turn.HF}
        newTurn.x = turn.y
        newTurn.y = turn.x
        @turns.push(newTurn)

    for attack in @attacks
      if attack.IR and attack.x isnt attack.y
        attack.IR = false
        newAttack = {ER:attack.ER, IR:false, FF:attack.FF, HF:attack.HF}
        newAttack.x = attack.y
        newAttack.y = attack.x
        @attacks.push(newAttack)

  move: (offsetX, offsetY) ->
    if (@board isnt 0)
      @board.move(this, offsetX, offsetY)

  symbol: ->
    return if @color is 'white' then '\u2659' else '\u265F'

  checkAttackCorrect: (offsetX, offsetY) ->
    if @color is 'black'
      offsetX *= -1
      offsetY *= -1

    if @debug then console.log('calling checkAttackCorrect')

    for attack in @attacks
      if attack.status and attack.x isnt 'u'
        if (attack.FF or attack.HF) and Math.abs(offsetX) isnt attack.x
          attack.status = false
          if @debug then console.log("#1 abs offsetX (%d) is not attack.x (%d)", Math.abs(offsetX), attack.x)
        else if (!(attack.FF or attack.HF))
          if offsetX isnt attack.x
            attack.status = false
            if @debug then console.log("#2 offsetX (%d) is not attack.x (%d)", offsetX, attack.x)

      if attack.status and attack.y isnt 'u'
        if attack.FF and Math.abs(offsetY) isnt attack.y
          attack.status = false
          if @debug then console.log("#3 offsetY (%d) is not attack.y (%d)", offsetY, attack.y)
        else if (!(attack.FF or attack.HF))
          if offsetY isnt attack.y
            attack.status = false
            if @debug then console.log("#4 offsetY (%d) is not attack.y (%d)", offsetY, attack.y)

      if attack.status and attack.ER and Math.abs(offsetX) isnt Math.abs(offsetY)
        attack.status = false
        if @debug then console.log("#5 abs offsetX (%d) is not abs offsetY (%d)", Math.abs(offsetX), Math.abs(offsetY))

    status = false
    for attack in @attacks
      if attack.status then status = true else attack.status = true

    return status

  checkMovementCorrect: (offsetX, offsetY) ->
    if @debug then console.log('calling checkMovementCorrect')

    if offsetX is 0 and offsetY is 0
      return true

    if @color is 'black'
      offsetX *= -1
      offsetY *= -1

    for turn in @turns
      if turn.status and turn.x isnt 'u'
        if (turn.FF or turn.HF) and Math.abs(offsetX) isnt turn.x
          turn.status = false
          if @debug then console.log("#1 abs offsetX (%d) is not turn.x (%d)", Math.abs(offsetX), turn.x)
        else if (!(turn.FF or turn.HF))
          if offsetX isnt turn.x
            turn.status = false
            if @debug then console.log("#2 offsetX (%d) is not turn.x (%d)", offsetX, turn.x)

      if turn.status and turn.y isnt 'u'
        if turn.FF and Math.abs(offsetY) isnt turn.y
          turn.status = false
          if @debug then console.log("#3 offsetY (%d) is not turn.y (%d)", offsetY, turn.y)
        else if (!(turn.FF or turn.HF))
          if offsetY isnt turn.y
            turn.status = false
            if @debug then console.log("#4 offsetY (%d) is not turn.y (%d)", offsetY, turn.y)

      if turn.status and turn.ER and Math.abs(offsetX) isnt Math.abs(offsetY)
        turn.status = false
        if @debug then console.log("#5 abs offsetX (%d) is not abs offsetY (%d)", Math.abs(offsetX), Math.abs(offsetY))

    #if @debug then console.log(@turns)

    status = false
    for turn in @turns
      if turn.status then status = true else turn.status = true

    return status

class Pawn extends Figure
  price: 1
  turns: [{x:0, y:1, ER:false, IR:false, FF:false, HF:false}]
  attacks: [{x:1, y:1, ER:true, IR:false, FF:false, HF:true}]
  name: 'pawn'

  symbol: ->
    return if @color is 'white' then '\u2659' else '\u265F'

class Rook extends Figure
  price: 5
  turns: [{x:'u', y:0, ER:false, IR:true, FF:true, HF:false}]
  attacks: [{x:'u', y:0, ER:false, IR:true, FF:true, HF:false}]
  name: 'rook'

  symbol: ->
    return if @color is 'white' then '\u2656' else '\u265C'

class Bishop extends Figure
  price: 3
  turns: [{x:'u', y:'u', ER:true, IR:true, FF:true, HF:false}]
  attacks: [{x:'u', y:'u', ER:true, IR:true, FF:true, HF:false}]
  name: 'bishop'

  symbol: ->
    return if @color is 'white' then '\u2657' else '\u265D'

class King extends Figure
  price: 100
  turns: [{x:1, y:1, ER:true, IR:true, FF:true, HF:false}, {x:0, y:1, ER:false, IR:true, FF:true, HF:false}]
  attacks: [{x:1, y:1, ER:true, IR:true, FF:true, HF:false}, {x:0, y:1, ER:false, IR:true, FF:true, HF:false}]
  name: 'king'
  king: true

  symbol: ->
    return if @color is 'white' then '\u2654' else '\u265A'

class Queen extends Figure
  price: 9
  turns: [{x:'u', y:'u', ER:true, IR:true, FF:true, HF:false}, {x:0, y:'u', ER:false, IR:true, FF:true, HF:false}]
  attacks: [{x:'u', y:'u', ER:true, IR:true, FF:true, HF:false}, {x:0, y:'u', ER:false, IR:true, FF:true, HF:false}]
  name: 'queen'

  symbol: ->
    return if @color is 'white' then '\u2655' else '\u265B'

class Knight extends Figure
  price: 3
  turns: [{x:2, y:1, ER:false, IR:true, FF:true, HF:false}]
  attacks: [{x:2, y:1, ER:false, IR:true, FF:true, HF:false}]
  name: 'knight'
  canPassThrough: true

  symbol: ->
    return if @color is 'white' then '\u2658' else '\u265E'

board = new ChessBoard(Math.floor(document.documentElement.clientHeight/1.25))
#board.newGame(new Player(), new AIPlayer())
board.newGame(new Player(), new Player())