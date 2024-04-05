# controlcontexts
 A module for Contextual Control Inputs in Nico.

## Example

```nim
import nico
import controlcontexts


let pauseContext = ControlContext(name:"pause_ui")
let gameContext = ControlContext(name: "game")

let handler = ContextHandler()

# Register control callbacks within a context.
pauseContext.onBPress(pcStart) do():
  handler.switchContext("game")

gameContext.onBPress(pcStart) do():
  handler.switchContext("pause_ui")

pauseContext.onKPress(K_RETURN) do():
  echo "Enter key pressed!"

gameContext.onMClick(0) do(pos: IVec2):
  echo "Mouse clicked at ", pos.x, ", ", pos.y

# Register our contexts with the handler.
handler.add pauseContext
handler.add gameContext

# Set our current context
handler.setContext("pause_ui")

while true:
  # Process game inputs.
  handler.process()

```

