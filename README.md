# controlcontexts
 A module for Contextual Control Inputs in Nico.

ControlContexts lets you handle game inputs depending on the context of the game. Game controls usually have to be processed depending on a context like if the player is in the main menu, playing the game, or in a pause menu. This lets you handle these inputs easily through the creation of ControlContexts.

You also get a ControlBox and ControlRadius that you can bind mouse inputs to for making things clickable.

## Install

`nimble install https://github.com/RattleyCooper/controlcontexts`

## Example

```nim
import nico
import controlcontexts

# Create control contexts.
var pauseContext = newControlContext("pause_ui")
var gameContext = newControlContext("game")

# Register our contexts with the handler.
var handler = newContextHandler(pauseContext, gameContext)

var gamePaused = false

# Register callback on a ControlBox
var button = newControlBox(0, 0, 10, 10)
button.onMDown(0, gameContext) do(pos: IVec2):
  echo "Button area was clicked"

# Register callback on a ControlRadius
var radiusButton = newControlRadius(10, 10, 5)
radiusButton.onMDown(0, gameContext) do(pos: IVec2):
  echo "Radius button was clicked"

# Register control callbacks within a context.

# When we are in our pause screen context,
# pressing start should switch the context
# to the game context and unpause the game.
pauseContext.onBPress(pcStart) do():
  handler.setContext("game")
  gamePaused = false

# When we're in our game context, pressing
# start should switch the context to pause_ui
# and pause the game.
gameContext.onBPress(pcStart) do():
  handler.setContext("pause_ui")
  gamePaused = true

# Use Keycodes
pauseContext.onKPress(K_RETURN) do(): # same as onKDown
  echo "Enter key pressed!"

gameContext.onKUp(K_HOME) do():
  echo "Take me hooooome"

# Handle mouse events.
gameContext.onMPress(0) do(pos: IVec2):
  echo "Mouse clicked at ", pos.x, ", ", pos.y

gameContext.onMMove() do(prev: IVec2, pos: IVec2):
  echo pos.x, ", ", pos.y

# Global context exists. These execute regardless
# of the current context.
handler.global.onKPress(K_END) do():
  echo "END Pressed!"

# Set our current context
handler.setContext("game")

while true:
  # Process game inputs.
  handler.process()

  if gamePaused: continue

  # Process game
```

