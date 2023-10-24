local App = class("App")


local ObjParser = require("obj_parser")
local Model = require("model")
local Camera = require("camera")
local Renderer = require("renderer")


function App.static:run(...)
    love.graphics.setDefaultFilter("nearest", "nearest")

    local w, h = love.graphics.getDimensions()

    self.camera = Camera(Vector3(-8, 0, 8), Vector3(0, 0, 0), { aspect = w / h })
    self.camera.transform:lookAt(Vector3(0, 0, 0))
    
    -- local vertices = {
    --     { Vector3(0, -1,  1), Vector3(0, 0, 0), Vector2(0, 0) },
    --     { Vector3(0,  1,  1), Vector3(1, 0, 0), Vector2(1, 0) },
    --     { Vector3(0, -1, -1), Vector3(0, 1, 0), Vector2(0, 1) },
    --     { Vector3(0,  1, -1), Vector3(1, 1, 0), Vector2(1, 1) },
    -- }

    -- local faces = {
    --     { 1, 4, 2 },
    --     { 1, 3, 4 }
    -- }

    local vertices = {
        { Vector3(-1, -1, -1), Vector3(0, 0, 0) },
        { Vector3( 1, -1, -1), Vector3(1, 0, 0) },
        { Vector3(-1,  1, -1), Vector3(0, 1, 0) },
        { Vector3( 1,  1, -1), Vector3(1, 1, 0) },
        { Vector3(-1, -1,  1), Vector3(0, 0, 1) },
        { Vector3( 1, -1,  1), Vector3(1, 0, 1) },
        { Vector3(-1,  1,  1), Vector3(0, 1, 1) },
        { Vector3( 1,  1,  1), Vector3(1, 1, 1) },
    }

    local faces = {
        { 1, 2, 4 }, { 1, 4, 3 }, -- bottom
        { 5, 8, 6 }, { 5, 7, 8 }, -- top
        { 1, 3, 7 }, { 1, 7, 5 }, -- back
        { 2, 8, 4 }, { 2, 6, 8 }, -- front
        { 1, 6, 2 }, { 1, 5, 6 }, -- left
        { 3, 4, 8 }, { 3, 8, 7 }, -- right
    }


    self.model = Model(Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(1, 1, 1), vertices, faces)

    self:initializeCanvas(w, h)
    love.resize:add(bind(self.initializeCanvas, self))

    love.draw:add(bind(self.draw, self))
    love.update:add(bind(self.update, self))
    love.filedropped:add(bind(self.filedropped, self))
end


local dtSamples = {}
local dtSampleIndex = 1
function App.static:draw()
    self:render()
    self:blitCanvas()
    self:drawFPSCounter()
    self:drawConsole()
end

function App.static:update(dt)
    dtSamples[dtSampleIndex] = dt
    dtSampleIndex = dtSampleIndex % 10 + 1
    local t = love.timer.getTime() * 2
    --self.camera.transform.position = Vector3(math.cos(t) * 4, -math.sin(t) * 4, math.sin(t / 1.713) * 2)
    --self.camera.transform.position = Vector3(-4, 4, 3 + math.sin(t) * 2)
    self:moveCamera(dt)
    self.model.transform.position = Vector3(0, 0, 0) -- math.sin(t * 0.8) * 0.5
    self.model.transform.rotation = Vector3(0, 0, 0) -- t * 0.3
end

local function isDownInt(k)
    return love.keyboard.isDown(k) and 1 or 0
end
function App.static:moveCamera(dt)
    local transform = self.camera.transform
    local w, a, s, d = isDownInt("w"), isDownInt("a"), isDownInt("s"), isDownInt("d")
    local i, j, k, l = isDownInt("i"), isDownInt("j"), isDownInt("k"), isDownInt("l")
    local space, ctrl = isDownInt("space"), isDownInt("lctrl")
    
    local f, r, u = w - s, d - a, space - ctrl
    local ry, rp = l - j, k - i

    f, r, u, ry, rp = f * dt, r * dt, u * dt, ry * dt, rp * dt
    local fV = f * transform:getForward()
    local rV = r * transform:getRight()
    local uV = u * transform:getUp()
    transform.position = transform.position + (fV + rV + uV) * 2 * (1 + 7 * isDownInt("lshift"))
    transform.rotation = transform.rotation + Vector3(0, rp, ry) * 2
end


function App.static:render()
    self.renderer:render(self.camera, { self.model })
end

function App.static:blitCanvas()
    local w, h = love.graphics.getDimensions()
    love.graphics.draw(self.canvas, 0, 0, 0, w / self.resolution[1], h / self.resolution[2])
end

function App.static:drawFPSCounter()
    local dt = 0
    local count = #dtSamples
    for i=1, count do
        dt = dt + dtSamples[i]
    end
    dt = dt / count
    love.graphics.print("FPS: " .. math.floor(1 / dt))
end

function App.static:drawConsole()
    
end


function App.static:initializeCanvas(w, h)
    w, h = 200 * w / h, 200
    w, h = math.floor(w), math.floor(h)
    self.resolution = Vector2(w, h)
    self.canvas = love.graphics.newCanvas(w, h)
    self.renderer = Renderer(self.canvas)
    self.camera.aspect = w / h
end


function App.static:filedropped(f)
    local s = f:read()
    local models = ObjParser(s):parse()
    local _, model = next(models)
    if model then
        self.model = model
    end
end


return App
