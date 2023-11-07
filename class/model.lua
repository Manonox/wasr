local Transform = require("transform")
local mgl = require("MGL")

local Model = class("Model")


function Model:initialize(position, rotation, scale, vertices, faces)
    self.transform = Transform(position, rotation, scale)
    self.vertices = vertices
    self.faces = faces
end


local sun = Vector3(-0.5, -0.5, -1)
sun = -mgl.normalize(sun)
function Model:recalculateLighting()
    local verts = self.vertices
    for i, v in ipairs(verts) do
        local n = v[2]
        local lightness = n and ((mgl.dot(n, sun) * 0.5 + 0.5) * 0.9 + 0.1) or math.random()
        verts[i][3] = Vector3(lightness, lightness, lightness)
    end
end


function Model:export(name)
    local s = "# WASR: Whole Ass Software Renderer\n# Made by Manonox\no " .. name .. "\n"
    
    for _, v in ipairs(self.vertices) do
        local p = v[1]
        s = s .. "v " .. p[1] .. " " .. p[2] .. " " .. p[3] .. "\n"
    end

    for _, v in ipairs(self.vertices) do
        local n = v[2]
        s = s .. "vn " .. n[1] .. " " .. n[2] .. " " .. n[3] .. "\n"
    end

    for _, v in ipairs(self.vertices) do
        local uv = v[3]
        s = s .. "vt " .. uv[1] .. " " .. uv[2] .. "\n"
    end

    for _, f in ipairs(self.faces) do
        s = s .. "f " .. f[1].."/"..f[1].."/"..f[1] .. " " .. f[2].."/"..f[2].."/"..f[2] .. " "  .. f[3].."/"..f[3].."/"..f[3] .. "\n"
    end

    local file = io.open(love.filesystem.getWorkingDirectory() .. "/models/" .. name .. ".obj", "w")
    file:write(s)
    file:close()
end


return Model
