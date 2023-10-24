local mgl = require("MGL")


local Transform = class("Transform")


Transform.static.up = Vector3(0, 0, 1)
Transform.static.forward = Vector3(1, 0, 0)
Transform.static.right = Vector3(0, 1, 0)


function Transform:initialize(position, rotation, scale)
    self.position = position
    self.rotation = rotation
    self.scale = scale
end


local sin, cos = math.sin, math.cos
function Transform:getForward()
    local rotation = self.rotation
    local cosPitch = cos(rotation[2])
    return Vector3(cos(rotation[3]) * cosPitch, sin(rotation[3]) * cosPitch, -sin(rotation[2]))
end

function Transform:getUp()
    local rotation = self.rotation
    local sinPitch = sin(rotation[2])
    return Vector3(cos(rotation[3]) * sinPitch, sin(rotation[3]) * sinPitch, cos(rotation[2]))
end

function Transform:getRight()
    local rotation = self.rotation
    assert(rotation.x == 0, "Fix roll you moron")
    return Vector3(-sin(rotation[3]), cos(rotation[3]), 0)
end



local function translationMatrix(offset)
    return Matrix4({
        1, 0, 0, offset.x,
        0, 1, 0, offset.y,
        0, 0, 1, offset.z,
        0, 0, 0, 1,
    })
end

local sin, cos = math.sin, math.cos
local function rotationMatrix(rotation)
    local ax, ay, az = rotation.x, rotation.y, rotation.z
    
    local rx = Matrix4({
        1, 0, 0, 0,
        0, cos(ax), -sin(ax), 0,
        0, sin(ax), cos(ax), 0,
        0, 0, 0, 1,
    })

    local ry = Matrix4({
        cos(ay), 0, sin(ay), 0,
        0, 1, 0, 0,
        -sin(ay), 0, cos(ay), 0,
        0, 0, 0, 1,
    })

    local rz = Matrix4({
        cos(az), -sin(az), 0, 0,
        sin(az), cos(az), 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    })

    return rz * ry * rx
end


local function scaleMatrix(scale)
    return Matrix4({
        scale.x, 0, 0, 0,
        0, scale.y, 0, 0,
        0, 0, scale.z, 0,
        0, 0, 0, 1,
    })
end


function Transform:getMatrix()
    return translationMatrix(self.position) * rotationMatrix(self.rotation) * scaleMatrix(self.scale)
end


local acos, sqrt, atan2 = math.acos, math.sqrt, math.atan2
local clamp = math.clamp
function Transform:lookAt(target, worldup)
    worldup = worldup or Vector3(0, 0, 1)

    local forward = mgl.normalize(target - self.position)
    local right = mgl.normalize(mgl.cross(worldup, forward))
    local up = mgl.cross(forward, right)
    
    local x1, x2, x3 = forward[1], forward[2], forward[3]
    local y1, y2, y3 = right[1], right[2], right[3]
    local z1, z2, z3 = up[1], up[2], up[3]

    local pitch = -atan2(x3, z3)
    local yaw = atan2(x2, x1)
    local roll = 0
    assert(worldup[3] - 1 < 0.0001, "Fix roll you moron")

    self.rotation = Vector3(roll, pitch, yaw)
end


return Transform
