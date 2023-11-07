local mgl = require("MGL")


local Renderer = class("Renderer")


function Renderer:initialize(canvas)
    self.canvas = canvas
    self.resolution = Vector2(canvas:getWidth(), canvas:getHeight())
    self.imageData = love.image.newImageData(self.resolution.x, self.resolution.y)
    self.depthImageData = love.image.newImageData(self.resolution.x, self.resolution.y, "r16")
    self.image = love.graphics.newImage(self.imageData)
    self.depthImage = love.graphics.newImage(self.depthImageData)

    self.clearColor = Vector3(0, 0, 0)
end


function Renderer:render(camera, models)
    self:_render(camera, models)
    
    love.graphics.setCanvas(self.canvas)
        self.image:replacePixels(self.imageData)
        self.depthImage:replacePixels(self.depthImageData)
        love.graphics.draw(self.image)
        love.graphics.draw(self.depthImage, 0, 0, 0, 0.25, 0.25)
    love.graphics.setCanvas()
end



local abs, sqrt = math.abs, math.sqrt
local function distance(p1, p2)
    local dx, dy = p2[1] - p1[1], p2[2] - p1[2]
    return sqrt(dx * dx + dy * dy)
end

local function distanceToLine(p1, p2, x, y)
    return abs((p2[1] - p1[1]) * (p1[2] - y) - (p1[1] - x) * (p2[2] - p1[2])) / distance(p1, p2)
end

local function lerpTriangle(rp, gp, bp, x, y)
    local rdmax = distanceToLine(gp, bp, rp[1], rp[2])
    local gdmax = distanceToLine(rp, bp, gp[1], gp[2])
    local bdmax = distanceToLine(rp, gp, bp[1], bp[2])

    local rd = distanceToLine(gp, bp, x, y)
    local gd = distanceToLine(rp, bp, x, y)
    local bd = distanceToLine(rp, gp, x, y)

    local r = rd / rdmax
    local g = gd / gdmax
    local b = bd / bdmax

    return r, g, b
end



local p1, p2, p3
local color1, color2, color3
local uv1, uv2, uv3

local x1, x2, x3
local y1, y2, y3

local minX, minY, maxX, maxY
local min, max, floor = math.min, math.max, math.floor

local w1, w2, w3
local position, color, uv = Vector3(0, 0, 0), Vector3(0, 0, 0), Vector2(0, 0)
local depth, currentDepth
local setPixel, getPixel

local function triangle(imageData, depthImageData, v1, v2, v3, w, h)
    p1, p2, p3 = v1[1], v2[1], v3[1]
    c1, c2, c3  = v1[2], v2[2], v3[2]
    uv1, uv2, uv3 = v1[3], v2[3], v3[3]

    x1, x2, x3 = p1[1], p2[1], p3[1]
    y1, y2, y3 = p1[2], p2[2], p3[2]

    -- calculate the bounding box of the triangle
    minX, minY = min(x1, x2, x3), min(y1, y2, y3)
    maxX, maxY = max(x1, x2, x3), max(y1, y2, y3)

    minX, minY = max(minX, 0), max(minY, 0)
    maxX, maxY = min(maxX, w), min(maxY, h)

    minX, minY = floor(minX), floor(minY)
    maxX, maxY = floor(maxX), floor(maxY)

    setPixel, getPixel = imageData.setPixel, imageData.getPixel

    -- iterate over the bounding box
    for y = minY, maxY do
        for x = minX, maxX do
            -- calculate barycentric coordinates
            w1 = ((y2 - y3) * (x - x3) + (x3 - x2) * (y - y3)) / ((y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3))
            w2 = ((y3 - y1) * (x - x3) + (x1 - x3) * (y - y3)) / ((y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3))
            w3 = 1 - w1 - w2
        
            -- if the point is inside the triangle, draw it
            if w1 >= 0 and w2 >= 0 and w3 >= 0 then
                position[3] = w1 * p1[3] + w2 * p2[3] + w3 * p3[3]
                depth = position[3]
                currentDepth = getPixel(depthImageData, x, y)
        
                if depth >= 0 and depth <= 1 and depth <= currentDepth then
                    -- for i=1, 2 do
                    --     position[i] = w1 * p1[i] + w2 * p2[i] + w3 * p3[i]
                    -- end
        
                    for i=1, 3 do
                        color[i] = w1 * c1[i] + w2 * c2[i] + w3 * c3[i]
                    end
        
                    -- for i=1, 2 do
                    --     uv[i] = w1 * uv1[i] + w2 * uv2[i] + w3 * uv3[i]
                    -- end
        
                    setPixel(imageData, x, y, color[1], color[2], color[3], 1)
                    setPixel(depthImageData, x, y, depth, 0, 0, 1)
                end
            end
        end
    end
end


local function applyMatrix(point, matrix)
    return matrix * Vector4(point, 1)
end


local facevertices = { { }, { }, { } }


local function samplerWhite() return Vector3(1, 1, 1) end
function Renderer:_drawFace()
    local v1, v2, v3 = facevertices[1], facevertices[2], facevertices[3]
    local p1, p2, p3 = v1[1], v2[1], v3[1]
    if p1[3] < -1 and p2[3] < -1 and p3[3] < -1 then return end -- cull faces which are completely behind the camera
    -- FUCK FUCK FUCK FUCK
    -- https://www.scratchapixel.com/lessons/3d-basic-rendering/perspective-and-orthographic-projection-matrix/projection-matrix-GPU-rendering-pipeline-clipping.html

    local resolution = self.resolution
    for i=1, 2 do
        p1[i] = (p1[i] * 0.5 + 0.5) * resolution[i]
        p2[i] = (p2[i] * 0.5 + 0.5) * resolution[i]
        p3[i] = (p3[i] * 0.5 + 0.5) * resolution[i]
    end

    p1[2] = resolution[2] - p1[2]
    p2[2] = resolution[2] - p2[2]
    p3[2] = resolution[2] - p3[2]
    triangle(self.imageData, self.depthImageData, v1, v2, v3, resolution[1] - 1, resolution[2] - 1, samplerWhite)
end


local vertexPositions = {}
local vertexClipSpacePositions = {}
local vertexclipping = {}
local vector00 = Vector2(0, 0)
local vector111 = Vector3(1, 1, 1)
function Renderer:_render(camera, models)
    self:_clear()

    local cameraPosition = camera.transform.position
    local projectionMatrix = camera:getProjectionMatrix()
    local worldToCameraMatrix = camera:getToLocalMatrix()
    local viewMatrix = projectionMatrix * worldToCameraMatrix
    for _, model in ipairs(models) do
        local modelMatrix = model.transform:getMatrix()
        local vertices = model.vertices
        local clipSpaceMatrix = viewMatrix * modelMatrix
        for _, face in ipairs(model.faces) do
            for i, vertexIndex in ipairs(face) do
                local vertexdata = vertices[vertexIndex]
                local position = vertexdata[1]
                vertexPositions[i] = Vector3(applyMatrix(position, modelMatrix))
                local clipSpacePosition = applyMatrix(position, clipSpaceMatrix)
                vertexClipSpacePositions[i] = clipSpacePosition
                local vertex = facevertices[i]
                vertex[2] = vertexdata[2] or vector111
                vertex[3] = vertexdata[3] or vector00
            end
            
            -- Back-face Culling
            local a, b = vertexPositions[1] - vertexPositions[3], vertexPositions[1] - vertexPositions[2]
            local normal = mgl.cross(a, b)
            local cameraToTriangle = vertexPositions[1] - cameraPosition
            local dot = mgl.dot(normal, cameraToTriangle)
            --if dot <= 0 then goto skip end
            
            -- Clipping
            -- for i=1, 3 do
            --     local position = vertexClipSpacePositions[i]
            --     local x, y, z, posW = position[1], position[2], position[3], position[4]
            --     local negW = -posW
            --     vertexclipping[i] = (x < negW or x > posW)
            --         or (y < negW or y > posW)
            --         or (z < negW or z > posW)
            --         or (posW < 0)
            -- end

            for i=1, 3 do
                local clipSpacePosition = vertexClipSpacePositions[i]
                local position = clipSpacePosition / clipSpacePosition[4]
                facevertices[i][1] = position
            end

            self:_drawFace()
            :: skip ::
        end
    end
end


function Renderer:_clear()
    local resolution = self.resolution
    local imageData = self.imageData
    local depthImageData = self.depthImageData
    local setPixel = imageData.setPixel
    local color = self.clearColor
    local r, g, b = color[1], color[2], color[3]
    for x = 0, resolution[1] - 1 do
        for y = 0, resolution[2] - 1 do
            setPixel(imageData, x, y, r, g, b, 1)
            setPixel(depthImageData, x, y, 1, 0, 0, 1)
        end
    end
end


return Renderer
