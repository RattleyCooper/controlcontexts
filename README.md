# controlcontexts
 A module for Contextual Control Inputs in Nico.

ControlContexts lets you handle game inputs depending on the context of the game. Game controls usually have to be processed depending on a context like if the player is in the main menu, playing the game, or in a pause menu. This lets you handle these inputs easily through the creation of ControlContexts.

You also get a ControlBox and ControlRadius that you can bind to mouse inputs on a specific context, to make things clickable.

## Install

`nimble install https://github.com/RattleyCooper/controlcontexts`

## Example

```nim
import nico
import controlcontexts

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
```

