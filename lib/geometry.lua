local mgl = require("MGL")
local Model = require("model")

local geometry = {}

local math_rad, math_cos, math_sin = math.rad, math.cos, math.sin
function geometry.buildSoR(sampler, minX, maxX, resolutionX, resolutionY, capped)
    capped = capped or false

    local xy = {}
    local x = minX
    local xStep = (maxX - minX) / resolutionX
    resolutionX = resolutionX + 1
    for i=1, resolutionX do
        local y = sampler(x)
        xy[#xy + 1] = {x, y}
        x = x + xStep
    end

    
    if capped then
        table.insert(xy, 1, {minX - 0.001, 0})
        xy[#xy + 1] = {maxX + 0.001, 0}
        resolutionX = resolutionX + 2
    end

    
    local verts = {}
    local rot = 0
    local yStep = 360 / resolutionY
    for i=1, resolutionY do
        local rotRad = math_rad(rot)
        for j, p in ipairs(xy) do
            local y = p[2]
            local position = Vector3(p[1], 0, 0)
            position[2] = math_cos(rotRad) * y
            position[3] = math_sin(rotRad) * y
            
            local normal
            if not capped or (j > 1 and j < resolutionX) then
                normal = Vector3(0, position[2], position[3])
            else
                normal = Vector3(j == 1 and -1 or 1)
            end
            normal = mgl.normalize(normal)

            verts[#verts + 1] = {position, normal, Vector3(1, 1, 1)}
        end
        rot = rot + yStep
    end

    local faces = {}
    for y = 0, resolutionY - 1 do
        for x = 0, resolutionX - 2 do
            local i1 = x + y * resolutionX
            local i2 = i1 + 1
            local i3 = x + ((y + 1) % resolutionY) * resolutionX
            local i4 = i3 + 1
            i1, i2, i3, i4 = i1 + 1, i2 + 1, i3 + 1, i4 + 1
            faces[#faces + 1] = {i1, i4, i2}
            faces[#faces + 1] = {i1, i3, i4}
        end
    end


    local model = Model(Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(1, 1, 1), verts, faces)
    model:recalculateLighting()
    return model
end


local eps = 0.001
function geometry.buildPlotXY(sampler, min, max, resolution)
    local step = (max - min) / resolution
    local maxI = resolution[1] + 1
    local maxJ = resolution[2] + 1

    local x, y = min[1], min[2]
    local verts = {}
    for j = 1, maxJ do
        x = min[1]
        for i = 1, maxI do
            local z = sampler(x, y)
            local position = Vector3(x, y, z)
            
            local dx, dy = (sampler(x + eps, y) - z) / eps, (sampler(x, y + eps) - z) / eps
            local normal = Vector3(dx, dy, 1 - math.sqrt(dx * dx + dy * dy))
            normal = mgl.normalize(normal)

            verts[#verts + 1] = {position, normal, Vector3(1, 1, 1)}

            x = x + step[1]
        end
        y = y + step[2]
    end

    local faces = {}
    for j = 0, maxJ - 2 do
        for i = 0, maxI - 2 do
            local i1 = i + j * maxI
            local i2 = i1 + 1
            local i3 = i1 + maxI
            local i4 = i3 + 1
            i1, i2, i3, i4 = i1 + 1, i2 + 1, i3 + 1, i4 + 1
            faces[#faces + 1] = {i1, i2, i4}
            faces[#faces + 1] = {i1, i4, i3}
        end
    end


    local model = Model(Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(1, 1, 1), verts, faces)
    model:recalculateLighting()
    return model
end


return geometry