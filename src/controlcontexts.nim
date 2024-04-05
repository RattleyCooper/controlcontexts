import std/[tables]
import nico
import vmath


type
  MouseButton* = enum
    mbLeft, mbMiddle, mbRight

  KeyControl* = ref object of RootObj
    key*: Keycode
  
  KeyHold* = ref object of KeyControl
    onPress*: proc()
  KeyDown* = ref object of KeyControl
    ended: bool
    onPress*: proc()
  KeyUp* = ref object of KeyControl
    lastVal*: bool
    onRelease*: proc()
  KeyRepeat* = ref object of KeyControl
    onPress*: proc()
    repeat*: int

  ButtonControl* = ref object of RootObj
    button*: NicoButton
    player*: int

  ButtonHold* = ref object of ButtonControl
    onPress*: proc()
  ButtonDown* = ref object of ButtonControl
    onPress*: proc()
  ButtonUp* = ref object of ButtonControl
    onRelease*: proc()
  ButtonRepeat* = ref object of ButtonControl
    onPress*: proc()
    repeat*: int
  ButtonAny* = ref object of ButtonControl
    onPress*: proc()

  MouseControl* = ref object of RootObj
    button*: range[0..2]
    onClick*: proc(pos: IVec2)

  MouseBtn* = ref object of MouseControl
  MouseRel* = ref object of MouseControl
    onRelease*: proc(pos: Vec2)

  MouseUp* = ref object of MouseControl
    ended: bool
  MouseBtnP* = ref object of MouseControl
  MouseBtnPr* = ref object of MouseControl
    repeat*: int

  MouseMove* = ref object of MouseControl
    lastPos*: IVec2
    onMove*: proc(previous: IVec2, current: IVec2)

  MouseWheel* = ref object of MouseControl
    onWheel*: proc(dir: int, pos: IVec2)

  ControlContext* = ref object of RootObj
    name*: string
    mouseControls*: seq[MouseControl]
    buttonControls*: seq[ButtonControl]
    keyControls*: seq[KeyControl]

  ContextHandler* = object
    global*: ControlContext
    current*: ControlContext
    context: Table[string, ControlContext]

proc add*(handler: var ContextHandler, context: ControlContext) =
  handler.context[context.name] = context

proc setContext*(handler: var ContextHandler, name: string) =
  handler.current = handler.context[name]

proc process(buttons: var seq[ButtonControl]) =
  for control in buttons:
    if control of ButtonHold:
      let c = control.ButtonHold
      if c.player > -1:
        if not btn(c.button, c.player): continue
      elif not btn(c.button): continue
      c.onPress()
    elif control of ButtonDown:
      let c = control.ButtonDown
      if c.player > -1:
        if not btnp(c.button, c.player): continue
      if not btnp(c.button): continue
      c.onPress()
    elif control of ButtonUp:
      let c = control.ButtonUp
      if c.player > -1:
        if not btnup(c.button, c.player): continue
      if not btnup(c.button): continue
      c.onRelease()
    elif control of ButtonRepeat:
      let c = control.ButtonRepeat
      if c.player > -1:
        if not btnpr(c.button, c.player, c.repeat): continue
      if not btnpr(c.button, c.repeat): continue
      c.onPress()
    elif control of ButtonAny:
      let c = control.ButtonAny
      if c.player > -1:
        if not anybtnp(c.player): continue
      if not anybtnp(): continue
      c.onPress()

proc process(keyControls: var seq[KeyControl]) =
  for control in keyControls:
    if control of KeyDown:
      let c = control.KeyDown
      let keydown = key(c.key)
      if c.ended and keydown:
        c.ended = false
        c.onPress()
      elif not c.ended and not keydown:
        c.ended = true
    elif control of KeyUp:
      let c = control.KeyUp
      if c.lastVal and not key(c.key):
        c.onRelease()
        c.lastVal = false
      elif not c.lastVal and key(c.key):
        c.lastVal = true
    elif control of KeyHold:
      let c = control.KeyHold
      if not key(c.key): continue
      c.onPress()
    elif control of KeyRepeat:
      let c = control.KeyRepeat
      if not keypr(c.key, c.repeat): continue
      c.onPress()

proc process(mouseControls: var seq[MouseControl]) =
  let (x, y) = mouse()
  let mv = ivec2(x, y)
  for control in mouseControls:
    if control of MouseBtn:
      let c = control.MouseBtn
      let pressed = mousebtn(c.button)
      if not pressed: continue
      c.onClick(mv)
    elif control of MouseUp:
      let c = control.MouseUp
      let down = mousebtn(c.button)
      if not c.ended and not down:
        c.ended = true
        c.onClick(mv)
      elif c.ended and down:
        c.ended = false
    elif control of MouseBtnP:
      let c = control.MouseBtnP
      let pressed = mousebtnp(c.button)
      if not pressed: continue
      c.onClick(mv)

    elif control of MouseBtnPr:
      let c = control.MouseBtnPr
      let pressed = mousebtnpr(c.button, c.repeat)
      if not pressed: continue
      c.onClick(mv)

    elif control of MouseRel:
      let c = control.MouseRel
      let rel = mouserel()
      if rel[0] == 0.0 and rel[1] == 0.0: continue
      c.onRelease(vec2(rel[0], rel[1]))

    elif control of MouseWheel:
      let c = control.MouseWheel
      let wd = mousewheel()
      c.onWheel(wd, mv)

    elif control of MouseMove:
      let c = control.MouseMove
      if c.lastPos == mv:
        continue
      c.onMove(c.lastPos, mv)
      c.lastPos = mv

proc process*(handler: var ContextHandler) =
  # Process global context, then current context.
  handler.global.buttonControls.process()
  handler.global.keyControls.process()
  handler.global.mouseControls.process()
  
  handler.current.buttonControls.process()
  handler.current.keyControls.process()
  handler.current.mouseControls.process()


proc onKDown*(context: var ControlContext, key: Keycode, cb: proc()) =
  context.keyControls.add(
    KeyDown(
      key: key,
      onPress: cb,
      ended: true
    )
  )

proc onKUp*(context: var ControlContext, key: Keycode, cb: proc()) =
  context.keyControls.add(
    KeyUp(
      key: key,
      lastVal: false,
      onRelease: cb
    )
  )

proc onKPress*(context: var ControlContext, key: Keycode, cb: proc()) =
  context.onKDown(key, cb)

proc onKHold*(context: var ControlContext, key: Keycode, cb: proc()) =
  context.keyControls.add(
    KeyHold(
      key: key,
      onPress: cb
    )
  )

proc onKRepeat*(context: var ControlContext, key: Keycode, repeat: int = 48, cb: proc()) =
  context.keyControls.add(
    KeyRepeat(
      key: key,
      repeat: repeat,
      onPress: cb
    )
  )

proc onBDown*(context: var ControlContext, button: NicoButton, cb: proc()) =
  context.buttonControls.add(
    ButtonDown(
      button: button,
      onPress: cb,
      player: -1
    )
  )

proc onBPress*(context: var ControlContext, button: NicoButton, cb: proc()) =
  context.onBDown(button, cb)

proc onBHold*(context: var ControlContext, button: NicoButton, cb: proc()) =
  context.buttonControls.add(
    ButtonHold(
      button: button,
      onPress: cb,
      player: -1
    )
  )

proc onButtonUp*(context: var ControlContext, button: NicoButton, cb: proc()) =
  context.buttonControls.add(
    ButtonUp(
      button: button,
      onRelease: cb,
      player: -1
    )
  )

proc onBRepeat*(context: var ControlContext, button: NicoButton, repeat: int, cb: proc()) =
  context.buttonControls.add(
    ButtonRepeat(
      button: button,
      repeat: repeat,
      onPress: cb,
      player: -1
    )
  )

proc onBAny*(context: var ControlContext, cb: proc()) =
  context.buttonControls.add(
    ButtonAny(
      onPress: cb,
      player: -1
    )
  )

proc onPBDown*(context: var ControlContext, button: NicoButton, player: int, cb: proc()) =
  context.buttonControls.add(
    ButtonDown(
      button: button,
      onPress: cb,
      player: player
    )
  )

proc onPBPress*(context: var ControlContext, button: NicoButton, player: int, cb: proc()) =
  context.onPBDown(button, player, cb)

proc onPBHold*(context: var ControlContext, button: NicoButton, player: int, cb: proc()) =
  context.buttonControls.add(
    ButtonHold(
      button: button,
      onPress: cb,
      player: player
    )
  )

proc onPButtonUp*(context: var ControlContext, button: NicoButton, player: int, cb: proc()) =
  context.buttonControls.add(
    ButtonUp(
      button: button,
      onRelease: cb,
      player: player
    )
  )

proc onPBRepeat*(context: var ControlContext, button: NicoButton, player: int, repeat: int, cb: proc()) =
  context.buttonControls.add(
    ButtonRepeat(
      button: button,
      repeat: repeat,
      onPress: cb,
      player: player
    )
  )

proc onPBAny*(context: var ControlContext, player: int, cb: proc()) =
  context.buttonControls.add(
    ButtonAny(
      onPress: cb,
      player: player
    )
  )

proc onMMove*(context: var ControlContext, cb: proc(previous: IVec2, current: IVec2)) =
  context.mouseControls.add(
    MouseMove(
      onMove: cb
    )
  )

proc onMHold*(context: var ControlContext, button: range[0..2], cb: proc(pos: IVec2)) =
  context.mouseControls.add(
    MouseBtn(
      button: button,
      onClick: cb
    )
  )

proc onMPress*(context: var ControlContext, button: range[0..2], cb: proc(pos: IVec2)) =
  context.mouseControls.add(
    MouseBtnP(
      button: button,
      onClick: cb
    )
  )

proc onMDown*(context: var ControlContext, button: range[0..2], cb: proc(pos: IVec2)) =
  context.onMPress(button, cb)

proc onMUp*(context: var ControlContext, button: range[0..2], cb: proc(pos: IVec2)) =
  context.mouseControls.add(
    MouseUp(
      ended: true,
      onClick: cb
    )
  )

proc onMRelease*(context: var ControlContext, cb: proc(pos: Vec2)) =
  context.mouseControls.add(
    MouseRel(
      onRelease: cb
    )
  )

proc onMRepeat*(context: var ControlContext, button: range[0..2], repeat: int, cb: proc(pos: IVec2)) =
  context.mouseControls.add(
    MouseBtnPr(
      button: button,
      repeat: repeat,
      onClick: cb
    )
  )

proc onMWheel*(context: var ControlContext, cb: proc(dir: int, pos: IVec2)) =
  context.mouseControls.add(
    MouseWheel(
      onWheel: cb
    )
  )

proc newContextHandler*(controls: varargs[ControlContext]): ContextHandler =
  result = ContextHandler(
    global: ControlContext(name: "_global")
  )
  for i, ctx in controls:
    result.context[ctx.name] = ctx
    if i == 0:
      result.current = ctx

proc newControlContext*(name: string): ControlContext =
  result = ControlContext(name: name)

if isMainModule:
  const orgName = "rcoop"
  const appName = "contexthandler"

  var gameContext = newControlContext("game")
  var pauseContext = newControlContext("pause_ui")
  var ctxhnd = newContextHandler(gameContext, pauseContext)
  
  var gamePaused = false

  ctxhnd.global.onKUp(K_RETURN) do():
    echo "Enter key up!"

  ctxhnd.global.onKHold(K_DELETE) do():
    echo "Delete key held"

  gameContext.onBDown(pcUp) do():
    echo "Up!"

  pauseContext.onMWheel() do(dir: int, pos: IVec2):
    if dir == -1:
      echo "wheel down at ", pos.x, ", ", pos.y
    elif dir == 1:
      echo "wheel up at ", pos.x, ", ", pos.y

  pauseContext.onMHold(0) do(pos: IVec2):
    echo "Mouse hold"

  gameContext.onMPress(0) do(pos: IVec2):
    echo "Mouse click"

  gameContext.onMUp(0) do(pos: IVec2):
    echo "mouse up"

  gameContext.onKUp(K_HOME) do():
    echo "Take me hooooome"

  gameContext.onKDown(K_INSERT) do():
    echo "Insert key pressed"

  gameContext.onMRepeat(0, 15) do(pos: IVec2):
    echo "Mouse repeat"

  gameContext.onMMove() do(prev: IVec2, pos: IVec2):
    echo pos.x, ", ", pos.y

  # onBPress / onBDown are the same
  gameContext.onBPress(pcStart) do():
    ctxhnd.setContext "pause_ui"
    gamePaused = true
    echo "game paused"
  
  pauseContext.onBDown(pcStart) do():
    ctxhnd.setContext "game"
    gamePaused = false
    echo "game resuming"

  ctxhnd.setContext("game")
  
  proc gameInit() =
    discard

  proc gameUpdate(dt: float32) =
    ctxhnd.process() # let handler process inputs

    if gamePaused: return

    # Process game

  proc gameDraw() =
    cls()

  nico.init(orgName, appName)

  nico.createWindow(
    appName, 
    100, 80,
    6, 
    false
  )
  nico.run(gameInit, gameUpdate, gameDraw)
