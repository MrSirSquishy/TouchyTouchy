# TouchyTouchy
Simple API for Figura that can be used to make arms reach out and touch blocks/entities


## How to use:

In your main script file, put this:
```lua
local TT = require("TouchyTouchy")
```
^ this will activate Touchy Touchy in that script file

Now you can copy-paste this function to create a new Touchy object for one of your arms(or similar)
```lua
--replace each nil with the value/parmater you want to use, or leave as nil to use default values :)
--parenthesis are default values for reference
TT.new(
nil, --arm
nil, --(false)isRight
nil, --(vec(0,0,0))pos
nil, --(10)armLength
nil, --(2)ticksUntilTouch
nil, --(0.2)armSpeed
nil, --(-45)maxAngleBack
nil, --(180)maxAngleFront
nil, --(vec(0, -1, 0))crouchShift
nil, --(0.5)movementInfluence
nil  --(0.1)speedToTouchEntity
)
```

### Paramters explained:

- arm: The arm to apply the TT to
- isRight: Defaults to `nil`, set true if the arm is on the right side. Or provide a vector3 to set the raycast vector
- pos: Defaults to `vec(0,0,0)`, the position of the arm in the model
- armLength: Defaults to `10`, the length of the arm in the model in pixels
- ticksUntilTouch: Defaults to `2`, how many ticks it'll wait before actually touching.
- armSpeed: Defaults to `0.2`, how fast the arm will move.
- maxAngleBack: Defaults to `-45`, the maximum angle the arm can rotate back.
- maxAngleFront: Defaults to `180`, the maximum angle the arm can rotate front.
- crouchShift: Defaults to `vec(0, -1, 0)`, the amount the arm will shift when crouching.
- movementInfluence: Defaults to `0.5`, how much the touch point will move with the player(higher values drag on walls more, lower values will stay behind more)
- speedToTouchEntity: Defaults to `0.1`, how fast the player should be moving before it starts checking for entities to touch
