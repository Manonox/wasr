local Transform = require("transform")
local Camera = class("Camera")
local mgl = require("MGL")

function Camera:initialize(position, rotation, settings)
    settings = settings or {}

    self.transform = Transform(position, rotation, Vector3(1, 1, 1))
    self.fov = settings.fov or 80
    self.znear = settings.znear or 0.1
    self.zfar = settings.zfar or 100
    self.aspect = settings.aspect or 1
    self.ortho = settings.ortho or false
    self.orthoSize = settings.orthoSize or 2
end


function Camera:getProjectionMatrix()
    local f, n = self.zfar, self.znear
    local fsubn = f - n

    if self.ortho then
        local h = self.orthoSize
        local w = h * self.aspect
        local l, r, t, b = -w, w, -h, h
        return Matrix4({
            0, 1 / w, 0, -(r+l)/(r-l),
            0, 0, -1 / h, (t+b)/(t-b),
            -2/fsubn, 0, 0, (f+n)/fsubn,
            0, 0, 0, 1
        })
    end

    -- local up = Transform.up
    -- local forward = Transform.forward
    -- local right = Transform.right

    local sy = 1 / math.tan(self.fov / 2 * math.pi / 180)
    local sx = sy / self.aspect

    return Matrix4({
        0, sx, 0, 0,
        0, 0, sy, 0,
        f/fsubn, 0, 0, -f*n/fsubn,
        1, 0, 0, 0,
    })
end


function Camera:getToLocalMatrix()
    return mgl.inverse(self.transform:getMatrix())
end

function Camera:getViewMatrix()
    return self:getProjectionMatrix() * self:getToLocalMatrix()
end


return Camera
