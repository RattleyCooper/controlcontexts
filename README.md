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

# Register control callbacks within a context.
pauseContext.onBPress(pcStart) do():
  handler.switchContext("game")

gameContext.onBPress(pcStart) do():
  handler.switchContext("pause_ui")

pauseContext.onKPress(K_RETURN) do():
  echo "Enter key pressed!"

gameContext.onMClick(0) do(pos: IVec2):
  echo "Mouse clicked at ", pos.x, ", ", pos.y

# Global context exists. These execute regardless
# of the current context.
handler.global.onKPress(K_END) do():
  echo "END Pressed!"

# Set our current context
handler.setContext("pause_ui")

while true:
  # Process game inputs.
  handler.process()
```

