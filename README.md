# controlcontexts
 A module for Contextual Control Inputs in Nico.

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

