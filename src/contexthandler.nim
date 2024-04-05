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
  KeyPress* = ref object of KeyControl
    onPress*: proc()
  KeyRelease* = ref object of KeyControl
    lastVal*: bool
    onRelease*: proc()
  KeyRepeat* = ref object of KeyControl
    onPress*: proc()
    repeat*: int

  ButtonControl* = ref object of RootObj
    button*: NicoButton

  ButtonHold* = ref object of ButtonControl
    onPress*: proc()
  ButtonPress* = ref object of ButtonControl
    onPress*: proc()
  ButtonRelease* = ref object of ButtonControl
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

  MouseBtnP* = ref object of MouseControl
  MouseBtnPr* = ref object of MouseControl
    repeat*: int

  MouseMove* = ref object of MouseControl
    lastPos*: IVec2
    onMove*: proc(previous: IVec2, current: IVec2)

  MouseWheel* = ref object of MouseControl
    onWheelUp*: proc(pos: IVec2)
    onWheelDown*: proc(pos: IVec2)

  ControlContext* = ref object of RootObj
    name*: string
    mouseControls*: seq[MouseControl]
    buttonControls*: seq[ButtonControl]
    keyControls*: seq[KeyControl]

  ContextHandler* = object
    current: ControlContext
    context: Table[string, ControlContext]

proc add*(handler: var ContextHandler, context: ControlContext) =
  handler.context[context.name] = context

proc setContext*(handler: var ContextHandler, name: string) =
  handler.current = handler.context[name]

proc process*(handler: var ContextHandler) =
  let (x, y) = mouse()
  let mv = ivec2(x, y)
  let buttonControls = handler.context[handler.current.name].buttonControls
  for control in buttonControls:
    if control of ButtonHold:
      let c = control.ButtonHold
      if not btn(c.button): continue
      c.onPress()
    elif control of ButtonPress:
      let c = control.ButtonPress
      if not btnp(c.button): continue
      c.onPress()
    elif control of ButtonRelease:
      let c = control.ButtonRelease
      if not btnup(c.button): continue
      c.onRelease()
    elif control of ButtonRepeat:
      let c = control.ButtonRepeat
      if not btnpr(c.button, c.repeat): continue
      c.onPress()
    elif control of ButtonAny:
      let c = control.ButtonAny
      if not anybtnp(): continue
      c.onPress()

  let keyControls = handler.context[handler.current.name].keyControls
  for control in keyControls:
    if control of KeyPress:
      let c = control.KeyPress
      if not keyp(c.key): continue
      c.onPress()
    elif control of KeyRelease:
      let c = control.KeyRelease
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

  let mouseControls = handler.context[handler.current.name].mouseControls
  for control in mouseControls:
    if control of MouseBtn:
      let c = control.MouseBtn
      let pressed = mousebtn(c.button)
      if not pressed: continue
      c.onClick(mv)

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
      case mousewheel():
      of -1:
        c.onWheelDown(mv)
      of 1:
        c.onWheelUp(mv)
      else:
        discard

    elif control of MouseMove:
      let c = control.MouseMove
      if c.lastPos == mv:
        continue
      c.onMove(c.lastPos, mv)
      c.lastPos = mv


proc onKPress*(context: var ControlContext, key: Keycode, cb: proc()) =
  context.keyControls.add(
    KeyPress(
      key: key,
      onPress: cb
    )
  )

proc onKHold*(context: var ControlContext, key: Keycode, cb: proc()) =
  context.keyControls.add(
    KeyHold(
      key: key,
      onPress: cb
    )
  )

proc onKRelease*(context: var ControlContext, key: Keycode, cb: proc()) =
  context.keyControls.add(
    KeyRelease(
      key: key,
      lastVal: false,
      onRelease: cb
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

proc onBPress*(context: var ControlContext, button: NicoButton, cb: proc()) =
  context.buttonControls.add(
    ButtonPress(
      button: button,
      onPress: cb
    )
  )

proc onBHold*(context: var ControlContext, button: NicoButton, cb: proc()) =
  context.buttonControls.add(
    ButtonHold(
      button: button,
      onPress: cb
    )
  )

proc onBRelease*(context: var ControlContext, button: NicoButton, cb: proc()) =
  context.buttonControls.add(
    ButtonRelease(
      button: button,
      onRelease: cb
    )
  )

proc onBRepeat*(context: var ControlContext, button: NicoButton, repeat: int = 48, cb: proc()) =
  context.buttonControls.add(
    ButtonRepeat(
      button: button,
      repeat: repeat,
      onPress: cb
    )
  )

proc onBAny*(context: var ControlContext, cb: proc()) =
  context.buttonControls.add(
    ButtonAny(
      onPress: cb
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

proc onMClick*(context: var ControlContext, button: range[0..2], cb: proc(pos: IVec2)) =
  context.mouseControls.add(
    MouseBtnP(
      button: button,
      onClick: cb
    )
  )

proc onMRepeat*(context: var ControlContext, button: range[0..2], repeat: int = 48, cb: proc(pos: IVec2)) =
  context.mouseControls.add(
    MouseBtnPr(
      button: button,
      repeat: repeat,
      onClick: cb
    )
  )

if isMainModule:
  var cc = ControlContext(name:"game")

  cc.onKRelease(K_RETURN) do():
    echo "Enter pressed!"

  cc.onBPress(pcUp) do():
    echo "Ok!"

  cc.onMHold(0) do(pos: IVec2):
    echo "ok"

  cc.onMRepeat(0, 15) do(pos: IVec2):
    echo "cool"

  var c1 = ContextHandler()
  c1.add cc
  c1.setContext("game")
  c1.process()
