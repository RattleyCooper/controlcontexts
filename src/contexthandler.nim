import std/[tables]
import nico
import vmath


type
  MouseButton* = enum
    mbLeft, mbMiddle, mbRight

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
    onEnter*: proc(pos: IVec2)
    onExit*: proc(pos: IVec2)

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

  ContextHandler* = object
    current: ControlContext
    context: Table[string, ControlContext]

proc add*(handler: var ContextHandler, context: ControlContext) =
  handler.context[context.name] = context

proc use*(handler: var ContextHandler, name: string) =
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

proc onPress*(context: var ControlContext, button: NicoButton, cb: proc()) =
  context.buttonControls.add(
    ButtonPress(
      button: button,
      onPress: cb
    )
  )

proc onHold*(context: var ControlContext, button: NicoButton, cb: proc()) =
  context.buttonControls.add(
    ButtonHold(
      button: button,
      onPress: cb
    )
  )

proc onRelease*(context: var ControlContext, button: NicoButton, cb: proc()) =
  context.buttonControls.add(
    ButtonRelease(
      button: button,
      onRelease: cb
    )
  )

proc onRepeat*(context: var ControlContext, button: NicoButton, repeat: int = 48, cb: proc()) =
  context.buttonControls.add(
    ButtonRepeat(
      button: button,
      repeat: repeat,
      onPress: cb
    )
  )

proc onAny*(context: var ControlContext, cb: proc()) =
  context.buttonControls.add(
    ButtonAny(
      onPress: cb
    )
  )

proc onMouse*(context: var ControlContext, cb: proc(previous: IVec2, current: IVec2)) =
  context.mouseControls.add(
    MouseMove(
      onMove: cb
    )
  )

proc onMouse*(context: var ControlContext, button: range[0..2], cb: proc(pos: IVec2)) =
  context.mouseControls.add(
    MouseBtn(
      button: button,
      onClick: cb
    )
  )

proc onMouseP*(context: var ControlContext, button: range[0..2], cb: proc(pos: IVec2)) =
  context.mouseControls.add(
    MouseBtnP(
      button: button,
      onClick: cb
    )
  )

proc onMousePr*(context: var ControlContext, button: range[0..2], repeat: int = 48, cb: proc(pos: IVec2)) =
  context.mouseControls.add(
    MouseBtnPr(
      button: button,
      repeat: repeat,
      onClick: cb
    )
  )

if isMainModule:
  var cc = ControlContext(name:"game")

  cc.onPress(pcUp) do():
    echo "Ok!"

  cc.onMouse(0) do(pos: IVec2):
    echo "ok"

  cc.onMousePr(0, 15) do(pos: IVec2):
    echo "cool"

  var c1 = ContextHandler()
  c1.add cc
  c1.use("game")
  c1.process()
