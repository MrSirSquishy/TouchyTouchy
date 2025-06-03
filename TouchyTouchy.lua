--[[--------------------------------------------------------------------------------------
 _________  ________  ___  ___  ________  ___  ___      ___    ___ 
|\___   ___\\   __  \|\  \|\  \|\   ____\|\  \|\  \    |\  \  /  /|
\|___ \  \_\ \  \|\  \ \  \\\  \ \  \___|\ \  \\\  \   \ \  \/  / /
     \ \  \ \ \  \\\  \ \  \\\  \ \  \    \ \   __  \   \ \    / / 
      \ \  \ \ \  \\\  \ \  \\\  \ \  \____\ \  \ \  \   \/  /  /  
       \ \__\ \ \_______\ \_______\ \_______\ \__\ \__\__/  / /    
        \|__|  \|_______|\|_______|\|_______|\|__|\|__|\___/ /     
                                                      \|___|/                                                                  
 _________  ________  ___  ___  ________  ___  ___      ___    ___ 
|\___   ___\\   __  \|\  \|\  \|\   ____\|\  \|\  \    |\  \  /  /|
\|___ \  \_\ \  \|\  \ \  \\\  \ \  \___|\ \  \\\  \   \ \  \/  / /
     \ \  \ \ \  \\\  \ \  \\\  \ \  \    \ \   __  \   \ \    / / 
      \ \  \ \ \  \\\  \ \  \\\  \ \  \____\ \  \ \  \   \/  /  /  
       \ \__\ \ \_______\ \_______\ \_______\ \__\ \__\__/  / /    
        \|__|  \|_______|\|_______|\|_______|\|__|\|__|\___/ /     
                                                      \|___|/      
]]--------------------------------------------------------------------------------------3D-ASCII

--Simple API for Figura that can be used to make arms reach out and touch blocks/entities


--! Author: Squishy
--^ Discord tag: @mrsirsquishy

--* Version: 1.0.0
--? Liscense: MIT







local TT = {}

--* CONFIG

--you can provide a list of animations that will stop the TT from moving
TT.stopWhenTheseArePlaying = {
    nil,
    nil,
}



--* CODE

TT.all = {}

local squassets = require("SquAPI_modules.SquAssets")

---@param arm ModelPart The arm to apply the TT to.
---@param isRight? boolean Defaults to `nil`, set true if the arm is on the right side. Or provide a vector3 to set the raycast vector
---@param pos? Vector3 Defaults to `vec(0,0,0)`, the position of the arm in the model
---@param armLength? number Defaults to `10`, the length of the arm in the model in pixels
---@param ticksUntilTouch? number Defaults to `2`, how many ticks it'll wait before actually touching.
---@param armSpeed? number Defaults to `0.2`, how fast the arm will move.
---@param maxAngleBack? number Defaults to `-45`, the maximum angle the arm can rotate back.
---@param maxAngleFront? number Defaults to `180`, the maximum angle the arm can rotate front.
---@param crouchShift? number Defaults to `vec(0, -1, 0)`, the amount the arm will shift when crouching.
---@param movementInfluence? number Defaults to `0.5`, how much the touch point will move with the player(higher values drag on walls more, lower values will stay behind more)
function TT.new(arm, isRight, pos, armLength, ticksUntilTouch, armSpeed, maxAngleBack, maxAngleFront, crouchShift, movementInfluence, speedToTouchEntity)
    local self = {}
    self.arm = arm
    self.pos = pos/16 or vec(0,0,0)
    self.armLength = armLength/16 or 0.625
    self.ticksUntilTouch = ticksUntilTouch or 2
    self.armSpeed = armSpeed or 0.2
    self.movementInfluence = movementInfluence or 0.5
    self.maxAngleBack = (maxAngleBack or -45)
    self.maxAngleFront = (maxAngleFront or 180)
    self.crouchShift = vec(0, crouchShift or -0.5, 0)
    self.speedToTouchEntity = speedToTouchEntity or 0.1

    if isRight then
        if type(isRight) ~= "Vector3" then
            self.isRight = 1
        end
    else
        self.isRight = -1
    end

    local rayVec
    if type(isRight) == "Vector3" then
        rayVec = isRight
    else
        rayVec = vec(10 * self.isRight, -10, -7.5)
    end
    self.raycast = rayVec:clampLength(self.armLength, self.armLength) + self.pos

    self.enabled = true
    self.armRot = vec(0,0,0)
    self.armRotOld = vec(0,0,0)
    self.canTouchTimer = 0
    self.isTouching = false
    self.touchPos = vec(0,0,0)
    self.isEntity = false
    
    self = setmetatable(self, {__index = TT})
    table.insert(TT.all, self)
    return self
end



function TT.dirToAng(normVec)
    local pitch = math.asin(normVec.y)
    local yaw = math.atan2(normVec.x, normVec.z)

    return vec(90 - math.deg(pitch), math.deg(yaw), 0)
end

function TT.rotateVectorBySinCosYaw(v, sinYaw, cosYaw)
    return vec(
        v.x * cosYaw - v.z * sinYaw,
        v.y,
        v.x * sinYaw + v.z * cosYaw
    )
end


function TT:tick()
    self.armRotOld = self.armRot

    local enabled = self.enabled
    if enabled then
        for _, v in pairs(self.stopWhenTheseArePlaying) do
            if v:isPlaying() then
                enabled = false
                break
            end
        end
    end
    if not enabled then
        self.armRot = math.lerpAngle(self.armRot, vec(0,0,0), self.armSpeed)
        self.isTouching = false
        return
    end

    
    local playerPos = player:getPos()
    local yaw = player:getBodyYaw()%360 - 180
    
    local cosYaw = math.rad(yaw)
    local sinYaw = math.sin(cosYaw)
    cosYaw = math.cos(cosYaw)

    local targetRot = vec(0,0,0)
    local speed = self.armSpeed

    local offset = ((player:getPose() == "CROUCHING" and self.crouchShift) or vec(0,0,0))
    local armPos = playerPos + TT.rotateVectorBySinCosYaw(self.pos + offset, sinYaw, cosYaw)

    if not self.isTouching then
        speed = speed/2
        local rayCastPos = playerPos + TT.rotateVectorBySinCosYaw(self.raycast + offset, sinYaw, cosYaw)
        
        local hit, hitPos, side = raycast:block(armPos, rayCastPos)

        if hitPos == rayCastPos and player:getVelocity():length() > self.speedToTouchEntity then
             hit, hitPos = raycast:entity(armPos, rayCastPos, function(x) if x == player then return false else return true end end)
             hitPos = hitPos or rayCastPos
             self.isEntity = true
        else
            self.isEntity = false
        end

        if hitPos == rayCastPos then
            self.canTouchTimer = 0
        else
            self.canTouchTimer = self.canTouchTimer + 1
            if self.canTouchTimer > self.ticksUntilTouch then
                self.isTouching = true
                self.touchPos = rayCastPos
                self.canTouchTimer = 0
            end
        end

    else --isTouching
        local dif = (armPos - self.touchPos)
        dif = dif:normalized() * self.armLength
        self.touchPos = armPos - dif + player:getVelocity()*self.movementInfluence

        local hit, hitPos
        if self.isEntity then
            hit, hitPos = raycast:entity(armPos, self.touchPos, function(x) if x == player then return false else return true end end)
            hitPos = hitPos or self.touchPos
        else
            hit, hitPos = raycast:block(armPos, self.touchPos)
        end
        
        if hitPos == self.touchPos then --breaks when no longer touching
            self.isTouching = false
        end

        targetRot = TT.dirToAng((armPos - hitPos):normalized()) + vec(0, yaw, 0)

        --breaks if off when the arm is angled too far
        local ang = math.shortAngle(0, (targetRot.y) * self.isRight + 90)
        
        if ang < self.maxAngleBack or ang > self.maxAngleFront then
            self.isTouching = false
        end
    end

    self.armRot = math.lerpAngle(self.armRot, targetRot, speed)
end

function TT:render(dt)
    self.arm:setOffsetRot(math.lerpAngle(self.armRotOld, self.armRot, dt))
end







function events.tick()
    for _, v in pairs(TT.all) do
        v:tick()
    end
end

function events.render(dt, context)
    for _, v in pairs(TT.all) do
        v:render(dt)
    end
end


return TT