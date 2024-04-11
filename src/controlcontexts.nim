import vmath
import nico
import tables


type
  ControlBox* = ref object
    pos*: IVec2
    size*: IVec2

  ControlRadius* = ref object
    center*: IVec2
    radius*: int

  KeyControl*[T] = ref object of RootObj
    key*: Keycode
    lastVal*: bool
    ended: bool
    repeat*: int
    obj*: T
    onPress*: proc(obj: var T)
    onRelease*: proc(obj: var T) 
  KeyHold*[T] = ref object of KeyControl[T]
  KeyDown*[T] = ref object of KeyControl[T]
  KeyUp*[T] = ref object of KeyControl[T]
  KeyRepeat*[T] = ref object of KeyControl[T]

  ButtonControl*[T] = ref object of RootObj
    button*: NicoButton
    player*: int
    onPress*: proc(obj: var T)
    onRelease*: proc(obj: var T)
    repeat*: int
    obj*: T

  ButtonHold*[T] = ref object of ButtonControl[T]
  ButtonDown*[T] = ref object of ButtonControl[T]
  ButtonUp*[T] = ref object of ButtonControl[T]
  ButtonRepeat*[T] = ref object of ButtonControl[T]
  ButtonAny*[T] = ref object of ButtonControl[T]

  MouseButton* = enum
    mbLeft, mbMiddle, mbRight

  MouseControl*[T] = ref object of RootObj
    button*: range[0..2]
    onClick*: proc(obj: var T, pos: IVec2)
    obj*: T
    lastPos*: IVec2
    onMove*: proc(obj: var T, previous: IVec2, current: IVec2)
    repeat*: int
    ended*: bool
    onRelease*: proc(obj: var T, pos: Vec2)
    onWheel*: proc(obj: var T, dir: int, pos: IVec2)

  MouseBtn*[T] = ref object of MouseControl[T]
  MouseBtnP*[T] = ref object of MouseControl[T]
  MouseMove*[T] = ref object of MouseControl[T]
  MouseBtnPr*[T] = ref object of MouseControl[T]
  MouseUp*[T] = ref object of MouseControl[T]
  MouseRel*[T] = ref object of MouseControl[T]
  MouseWheel*[T] = ref object of MouseControl[T]

  ControlContext*[T] = ref object of RootObj
    name*: string
    mouseControls*: seq[MouseControl[T]]
    buttonControls*: seq[ButtonControl[T]]
    keyControls*: seq[KeyControl[T]]

  ContextHandler*[T] = ref object
    global*: ControlContext[T]
    current*: ControlContext[T]
    context*: TableRef[string, ControlContext[T]]


proc newControlRadius*(pos: (int, int), radius: int): ControlRadius =
  ControlRadius(
    center: ivec2(pos[0], pos[1]), 
    radius: radius
  )

proc newControlRadius*(x: int, y: int, radius: int): ControlRadius =
  ControlRadius(
    center: ivec2(x, y), 
    radius: radius
  )

proc newControlRadius*(center: IVec2, radius: int): ControlRadius =
  ControlRadius(center: center, radius: radius)

proc newControlBox*(pos: (int, int), size: (int, int)): ControlBox =
  ControlBox(
    pos: ivec2(pos[0], pos[1]), 
    size: ivec2(size[0], size[1])
  )

proc newControlBox*(x: int, y: int, w: int, h: int): ControlBox =
  ControlBox(
    pos: ivec2(x, y), 
    size: ivec2(w, h)
  )

proc newControlBox*(pos: IVec2, size: IVec2): ControlBox =
  ControlBox(pos: pos, size: size)

proc inside*(v: IVec2, e: ControlBox): bool =
  # Check if the point (x, y) is inside the UI element defined by pos and size.
  let minX = e.pos.x
  let minY = e.pos.y
  let maxX = e.pos.x + e.size.x
  let maxY = e.pos.y + e.size.y
  return v.x >= minX and v.x <= maxX and v.y >= minY and v.y <= maxY

proc inside(v: IVec2, circle: ControlRadius): bool =
  # Check if the point (v) is inside the circle defined by its center and radius.
  let distanceSquared = (v.x - circle.center.x) ^ 2 + (v.y - circle.center.y) ^ 2
  let radiusSquared = circle.radius ^ 2
  return distanceSquared <= radiusSquared


proc `[]`*[T](ctx: var ContextHandler[T], name: string): var ControlContext =
  ctx.context[name]

proc process*[T](keyControls: var seq[KeyControl[T]]) =
  for control in keyControls:
    if control of KeyDown[T]:
      let keydown = key(control.key)
      if control.ended and keydown:
        control.ended = false
        control.onPress(control.obj)
      elif not control.ended and not keydown:
        control.ended = true
    elif control of KeyUp[T]:
      if control.lastVal and not key(control.key):
        control.onRelease(control.obj)
        control.lastVal = false
      elif not control.lastVal and key(control.key):
        control.lastVal = true
    elif control of KeyHold[T]:
      if not key(control.key): continue
      control.onPress(control.obj)
    elif control of KeyRepeat[T]:
      if not keypr(control.key, control.repeat): continue
      control.onPress(control.obj)

proc process*[T](buttons: var seq[ButtonControl[T]]) =
  for control in buttons:
    if control of ButtonHold[T]:
      if control.player > -1:
        if not btn(control.button, control.player): continue
      elif not btn(control.button): continue
      control.onPress(control.obj)
    elif control of ButtonDown[T]:
      if control.player > -1:
        if not btnp(control.button, control.player): continue
      if not btnp(control.button): continue
      control.onPress(control.obj)
    elif control of ButtonUp[T]:
      if control.player > -1:
        if not btnup(control.button, control.player): continue
      if not btnup(control.button): continue
      control.onRelease(control.obj)
    elif control of ButtonRepeat[T]:
      if control.player > -1:
        if not btnpr(control.button, control.player, control.repeat): continue
      if not btnpr(control.button, control.repeat): continue
      control.onPress(control.obj)
    elif control of ButtonAny[T]:
      if control.player > -1:
        if not anybtnp(control.player): continue
      if not anybtnp(): continue
      control.onPress(control.obj)

proc process*[T](mouseControls: var seq[MouseControl[T]]) =
  let (x, y) = mouse()
  let mv = ivec2(x, y)
  for control in mouseControls:
    if control of MouseBtn[T]:
      let pressed = mousebtn(control.button)
      if not pressed: continue
      control.onClick(control.obj, mv)
    elif control of MouseUp[T]:
      let down = mousebtn(control.button)
      if not control.ended and not down:
        control.ended = true
        control.onClick(control.obj, mv)
      elif control.ended and down:
        control.ended = false
    elif control of MouseBtnP[T]:
      let pressed = mousebtnp(control.button)
      if not pressed: continue
      control.onClick(control.obj, mv)
    elif control of MouseBtnPr[T]:
      let pressed = mousebtnpr(control.button, control.repeat)
      if not pressed: continue
      control.onClick(control.obj, mv)
    elif control of MouseRel[T]:
      let rel = mouserel()
      if rel[0] == 0.0 and rel[1] == 0.0: continue
      control.onRelease(control.obj, vec2(rel[0], rel[1]))
    elif control of MouseWheel[T]:
      let wd = mousewheel()
      control.onWheel(control.obj, wd, mv)
    elif control of MouseMove[T]:
      if control.lastPos == mv:
        continue
      control.onMove(control.obj, control.lastPos, mv)
      control.lastPos = mv

proc process*[T](handler: var ContextHandler[T]) =
  # Process global context, then current context.
  handler.current.mouseControls.process()
  handler.current.keyControls.process()
  handler.current.buttonControls.process()

proc setContext*[T](handler: var ContextHandler[T], name: string) =
  handler.current = handler.context[name]

proc onKDown*[T](context: var ControlContext[T], key: Keycode, obj: var T, cb: proc(obj: var T)) =
  context.keyControls.add(
    KeyDown[T](
      key: key,
      onPress: cb,
      ended: true,
      obj: obj
    )
  )

proc onKUp*[T](context: var ControlContext[T], key: Keycode, obj: var T, cb: proc(obj: var T)) =
  context.keyControls.add(
    KeyUp[T](
      key: key,
      lastVal: false,
      onRelease: cb,
      obj: obj
    )
  )

proc onKPress*[T](context: var ControlContext[T], key: Keycode, obj: var T, cb: proc(obj: var T)) =
  context.onKDown(key, obj, cb)

proc onKHold*[T](context: var ControlContext[T], key: Keycode, obj: var T, cb: proc(obj: var T)) =
  context.keyControls.add(
    KeyHold[T](
      key: key,
      onPress: cb,
      obj: obj
    )
  )

proc onKRepeat*[T](context: var ControlContext[T], key: Keycode, repeat: int = 48, obj: var T, cb: proc(obj: var T)) =
  context.keyControls.add(
    KeyRepeat[T](
      key: key,
      repeat: repeat,
      onPress: cb,
      obj: obj
    )
  )

proc onBDown*[T](context: var ControlContext[T], button: NicoButton, obj: var T, cb: proc(obj: var T)) =
  context.buttonControls.add(
    ButtonDown[T](
      button: button,
      onPress: cb,
      player: -1,
      obj: obj
    )
  )

proc onBPress*[T](context: var ControlContext[T], button: NicoButton, obj: var T, cb: proc(obj: var T)) =
  context.onBDown(button, obj, cb)

proc onBHold*[T](context: var ControlContext[T], button: NicoButton, obj: var T, cb: proc(obj: var T)) =
  context.buttonControls.add(
    ButtonHold[T](
      button: button,
      onPress: cb,
      player: -1,
      obj: obj
    )
  )

proc onButtonUp*[T](context: var ControlContext[T], button: NicoButton, obj: var T, cb: proc(obj: var T)) =
  context.buttonControls.add(
    ButtonUp[T](
      button: button,
      onRelease: cb,
      player: -1,
      obj: obj
    )
  )

proc onBRepeat*[T](context: var ControlContext[T], button: NicoButton, repeat: int, obj: var T, cb: proc(obj: var T)) =
  context.buttonControls.add(
    ButtonRepeat[T](
      button: button,
      repeat: repeat,
      onPress: cb,
      player: -1,
      obj: obj
    )
  )

proc onBAny*[T](context: var ControlContext[T], obj: var T, cb: proc(obj: var T)) =
  context.buttonControls.add(
    ButtonAny[T](
      onPress: cb,
      player: -1,
      obj: obj
    )
  )

proc onPBDown*[T](context: var ControlContext[T], button: NicoButton, player: int, obj: var T, cb: proc(obj: var T)) =
  context.buttonControls.add(
    ButtonDown[T](
      button: button,
      onPress: cb,
      player: player,
      obj: obj
    )
  )

proc onPBPress*[T](context: var ControlContext[T], button: NicoButton, player: int, obj: var T, cb: proc(obj: var T)) =
  context.onPBDown(button, player, obj, cb)

proc onPBHold*[T](context: var ControlContext[T], button: NicoButton, player: int, obj: var T, cb: proc(obj: var T)) =
  context.buttonControls.add(
    ButtonHold[T](
      button: button,
      onPress: cb,
      player: player,
      obj: obj
    )
  )

proc onPButtonUp*[T](context: var ControlContext[T], button: NicoButton, player: int, obj: var T, cb: proc(obj: var T)) =
  context.buttonControls.add(
    ButtonUp[T](
      button: button,
      onRelease: cb,
      player: player,
      obj: obj
    )
  )

proc onPBRepeat*[T](context: var ControlContext[T], button: NicoButton, player: int, repeat: int, obj: var T, cb: proc(obj: var T)) =
  context.buttonControls.add(
    ButtonRepeat[T](
      button: button,
      repeat: repeat,
      onPress: cb,
      player: player,
      obj: obj
    )
  )

proc onPBAny*[T](context: var ControlContext[T], player: int, obj: var T, cb: proc(obj: var T)) =
  context.buttonControls.add(
    ButtonAny[T](
      onPress: cb,
      player: player,
      obj: obj
    )
  )

proc onMWheel*[T](context: var ControlContext[T], obj: var T, cb: proc(obj: var T, dir: int, pos: IVec2)) =
  context.mouseControls.add(
    MouseWheel[T](
      onWheel: cb,
      obj: obj
    )
  )

proc onMMove*[T](context: var ControlContext[T], obj: var T, cb: proc(obj: var T, previous: IVec2, current: IVec2)) =
  context.mouseControls.add(
    MouseMove[T](
      lastPos: ivec2(0, 0),
      onMove: cb,
      obj: obj
    )
  )

proc onMHold*[T](context: var ControlContext[T], button: range[0..2], obj: var T, cb: proc(obj: var T, pos: IVec2)) =
  context.mouseControls.add(
    MouseBtn[T](
      button: button,
      onClick: cb,
      obj: obj
    )
  )

proc onMPress*[T](context: var ControlContext[T], button: range[0..2], obj: var T, cb: proc(obj: var T, pos: IVec2)) =
  context.mouseControls.add(
    MouseBtnP[T](
      button: button,
      onClick: cb,
      obj: obj
    )
  )

proc onMDown*[T](context: var ControlContext[T], button: range[0..2], obj: var T, cb: proc(obj: var T, pos: IVec2)) =
  context.onMPress(button, obj, cb)

proc onMDown*[T](e: ControlBox, button: range[0..2], c: var ControlContext[T], obj: var T, cb: proc(obj: var T, pos: IVec2)) =
  c.onMDown(button, obj) do(obj: var T, pos: IVec2):
    if pos.inside(e):
      cb(obj, pos)

proc onMDown*[T](context: var ControlContext[T], button: range[0..2], cb: proc(obj: var T, pos: IVec2)) =
  context.onMPress(button, cb)

proc onMDown*[T](e: ControlBox, button: range[0..2], c: var ControlContext[T], cb: proc(obj: var T, pos: IVec2)) =
  c.onMDown(button) do(obj: var T, pos: IVec2):
    if pos.inside(e):
      cb(obj, pos)

proc onMUp*[T](context: var ControlContext[T], button: range[0..2], obj: var T, cb: proc(obj: var T, pos: IVec2)) =
  context.mouseControls.add(
    MouseUp[T](
      ended: true,
      onClick: cb,
      obj: obj
    )
  )

proc onMRelease*[T](context: var ControlContext[T], obj: var T, cb: proc(obj: var T, pos: Vec2)) =
  context.mouseControls.add(
    MouseRel[T](
      onRelease: cb,
      obj: obj
    )
  )

proc onMRepeat*[T](context: var ControlContext[T], button: range[0..2], repeat: int, obj: var T, cb: proc(obj: var T, pos: IVec2)) =
  context.mouseControls.add(
    MouseBtnPr[T](
      button: button,
      repeat: repeat,
      onClick: cb,
      obj: obj
    )
  )

proc newControlContext*[T](name: string): ControlContext[T] =
  result = ControlContext[T](name: name)

proc newContextHandler*[T](controls: varargs[ControlContext[T]]): ContextHandler[T] =
  result = ContextHandler[T](
    global: newControlContext[T]("global"),
    context: newTable[string, ControlContext[T]]()
  )
  for i, ctx in controls:
    result.context[ctx.name] = ctx
    if i == 0:
      result.current = ctx

proc onMExit*[T](e: ControlRadius, c: var ControlContext[T], obj: var T, cb: proc(obj: var T, prev: IVec2, pos: IVec2)) =
  c.onMMove(obj) do(obj: var T, prev: IVec2, pos: IVec2):
    if prev.inside(e) and not pos.inside(e):
      cb(obj, prev, pos)

proc onMEnter*[T](e: ControlRadius, c: var ControlContext[T], obj: var T, cb: proc(obj: var T, prev: IVec2, pos: IVec2)) =
  c.onMMove(obj) do(obj: var T, prev: IVec2, pos: IVec2):
    if pos.inside(e) and not prev.inside(e):
      cb(obj, prev, pos)

proc onMDown*[T](e: ControlRadius, button: range[0..2], c: var ControlContext[T], obj: var T, cb: proc(obj: var T, pos: IVec2)) =
  c.onMDown(button, obj) do(obj: var T, pos: IVec2):
    if pos.inside(e):
      cb(obj, pos)

proc onMUp*[T](e: ControlRadius, button: range[0..2], c: var ControlContext[T], obj: var T, cb: proc(obj: var T, pos: IVec2)) =
  c.onMUp(button, obj) do(obj: var T, pos: IVec2):
    if pos.inside(e):
      cb(obj, pos)

proc onMHold*[T](e: ControlRadius, button: range[0..2], c: var ControlContext[T], obj: var T, cb: proc(obj: var T, pos: IVec2)) =
  c.onMHold(button, obj) do(obj: var T, pos: IVec2):
    if pos.inside(e):
      cb(obj, pos)

proc onMRepeat*[T](e: ControlRadius, button: range[0..2], repeat: int, c: var ControlContext[T], obj: var T, cb: proc(obj: var T, pos: IVec2)) =
  c.onMRepeat(button, repeat, obj) do(obj: var T, pos: IVec2):
    if pos.inside(e):
      cb(obj, pos)

proc onMExit*[T](e: ControlBox, c: var ControlContext[T], obj: var T, cb: proc(obj: var T, prev: IVec2, pos: IVec2)) =
  c.onMMove(obj) do(obj: var T, prev: IVec2, pos: IVec2):
    if prev.inside(e) and not pos.inside(e):
      cb(obj, prev, pos)

proc onMEnter*[T](e: ControlBox, c: var ControlContext[T], obj: var T, cb: proc(obj: var T, prev: IVec2, pos: IVec2)) =
  c.onMMove(obj) do(obj: var T, prev: IVec2, pos: IVec2):
    if pos.inside(e) and not prev.inside(e):
      cb(obj, prev, pos)

proc onMUp*[T](e: ControlBox, button: range[0..2], c: var ControlContext[T], obj: var T, cb: proc(obj: var T, pos: IVec2)) =
  c.onMUp(button, obj) do(obj: var T, pos: IVec2):
    if pos.inside(e):
      cb(obj, pos)

proc onMHold*[T](e: ControlBox, button: range[0..2], c: var ControlContext[T], obj: var T, cb: proc(obj: var T, pos: IVec2)) =
  c.onMHold(button, obj) do(obj: var T, pos: IVec2):
    if pos.inside(e):
      cb(obj, pos)

proc onMRepeat*[T](e: ControlBox, button: range[0..2], repeat: int, c: var ControlContext[T], obj: var T, cb: proc(obj: var T, pos: IVec2)) =
  c.onMRepeat(button, repeat, obj) do(obj: var T, pos: IVec2):
    if pos.inside(e):
      cb(obj, pos)

if isMainModule:
  const orgName = "RattleyCooper"
  const appName = "ContextHandler"

  type
    Player = ref object
      name: string
      x, y: int
      box: ControlBox
      ctx: ContextHandler[Player]
      gameCtx: ControlContext[Player]
      pauseCtx: ControlContext[Player]
      pColor: int

  # Create control contexts.
  var pauseContext = newControlContext[Player]("paused")
  var gameContext = newControlContext[Player]("game")

  # Register our contexts with the handler.
  var handler = newContextHandler(pauseContext, gameContext)

  var gamePaused = false

  var player = Player(
    name: "Bob", x: 10, y: 10,
    pColor: 3,
    box: newControlBox(0, 0, 10, 10),
    ctx: handler,
    gameCtx: gameContext,
    pauseCtx: pauseContext
  )

  # Register callback on a ControlBox.  It needs to know
  # which context to use, and which object to pass into
  # the callback.
  # This triggers when a mouse down event occurs within
  # the player's control box.
  player.box.onMDown(0, player.gameCtx, player) do(obj: var Player, pos: IVec2):
    echo "Player was clicked!"
    echo obj.name
    obj.name = "Bill"

  # ControlBox and ControlRadius have unique events.
  player.box.onMEnter(player.gameCtx, player) do(obj: var Player, prev: IVec2, pos: IVec2):
    obj.pColor += 1
  player.box.onMExit(player.gameCtx, player) do(obj: var Player, prev: IVec2, pos: IVec2):
    obj.pColor -= 1

  # Register control callbacks within a context.
  # When we are in our pause screen context,
  # pressing start should switch the context
  # to the game context and unpause the game.
  player.pauseCtx.onBPress(pcStart, player) do(obj: var Player):
    # Since game is paused, switch the control context to game.
    obj.ctx.setContext("game")
    gamePaused = false

  # When we're in our game context, pressing
  # start should switch the context to pause_ui
  # and pause the game.
  player.gameCtx.onBPress(pcStart, player) do(obj: var Player):
    # Since game is running, switch the control context to paused
    obj.ctx.setContext("paused")
    gamePaused = true

  # Move our player and update our control box so we can 
  # capture clicks on the player.
  player.gameCtx.onBHold(pcLeft, player) do(obj: var Player):
    obj.x -= 1
    obj.box.pos.x = obj.x
  player.gameCtx.onBHold(pcRight, player) do(obj: var Player):
    obj.x += 1
    obj.box.pos.x = obj.x    
  player.gameCtx.onBHold(pcUp, player) do(obj: var Player):
    obj.y -= 1
    obj.box.pos.y = obj.y
  player.gameCtx.onBHold(pcDown, player) do(obj: var Player):
    obj.y += 1
    obj.box.pos.y = obj.y

  # Use Keycodes
  player.pauseCtx.onKPress(K_RETURN, player) do(obj: var Player): # same as onKDown
    echo "Enter key pressed!"

  player.gameCtx.onKUp(K_HOME, player) do(obj: var Player):
    echo "Take me hooooome"

  # Handle mouse events.
  player.gameCtx.onMPress(0, player) do(obj: var Player, pos: IVec2):
    echo "Clicked window at ", pos.x, ", ", pos.y

  # Global context exists. These execute regardless
  # of the current context.
  player.ctx.global.onKPress(K_END, player) do(obj: var Player):
    echo "END Pressed!"

  # Set our current control context
  player.ctx.setContext("game")
  
  proc gameInit() =
    setPalette loadPalettePico8()
    discard

  proc gameUpdate(dt: float32) =
    player.ctx.process() # let handler process inputs

    if player.ctx.current.name == "paused": return

    # Process other game things

  proc gameDraw() =
    cls()
    
    setColor(player.pColor)
    pset player.box.pos.x, player.box.pos.y
    pset player.box.pos.x + player.box.size.x, player.box.pos.y + player.box.size.y

  nico.init(orgName, appName)

  nico.createWindow(
    appName, 
    100, 80,
    6, 
    false
  )
  nico.run(gameInit, gameUpdate, gameDraw)
