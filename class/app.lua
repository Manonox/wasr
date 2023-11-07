local App = class("App")

local geometry = require("geometry")
local Console = require("console")

local ObjParser = require("obj_parser")
local Model = require("model")
local Camera = require("camera")
local Renderer = require("renderer")


local w, h = love.graphics.getDimensions()
function App.static:run(...)
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.keyboard.setKeyRepeat(true)

    local w, h = love.graphics.getDimensions()

    self.console = Console()
    self:setupConsole()

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
        { Vector3(-1, -1, -1), Vector3(0, 0, 0), Vector3(0, 0, 0) },
        { Vector3( 1, -1, -1), Vector3(0, 0, 0), Vector3(1, 0, 0) },
        { Vector3(-1,  1, -1), Vector3(0, 0, 0), Vector3(0, 1, 0) },
        { Vector3( 1,  1, -1), Vector3(0, 0, 0), Vector3(1, 1, 0) },
        { Vector3(-1, -1,  1), Vector3(0, 0, 0), Vector3(0, 0, 1) },
        { Vector3( 1, -1,  1), Vector3(0, 0, 0), Vector3(1, 0, 1) },
        { Vector3(-1,  1,  1), Vector3(0, 0, 0), Vector3(0, 1, 1) },
        { Vector3( 1,  1,  1), Vector3(0, 0, 0), Vector3(1, 1, 1) },
    }

    local faces = {
        { 1, 4, 2 }, { 1, 3, 4 }, -- bottom
        { 5, 6, 8 }, { 5, 8, 7 }, -- top
        { 1, 7, 3 }, { 1, 5, 7 }, -- back
        { 2, 4, 8 }, { 2, 8, 6 }, -- front
        { 1, 2, 6 }, { 1, 6, 5 }, -- left
        { 3, 8, 4 }, { 3, 7, 8 }, -- right
    }


    self.model = Model(Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(1, 1, 1), vertices, faces)

    self:initializeCanvas(w, h)
    love.resize:add(bind(self.initializeCanvas, self))

    love.draw:add(bind(self.draw, self))
    love.update:add(bind(self.update, self))
    love.filedropped:add(bind(self.filedropped, self))

    love.keypressed:add(bind(self.keypressed, self))
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
    self:moveCamera(dt)
    dtSamples[dtSampleIndex] = dt
    dtSampleIndex = dtSampleIndex % 10 + 1


    local t = love.timer.getTime() * 2
    --self.camera.transform.position = Vector3(math.cos(t) * 4, -math.sin(t) * 4, math.sin(t / 1.713) * 2)
    --self.camera.transform.position = Vector3(-4, 4, 3 + math.sin(t) * 2)
    --self.model.transform.position = Vector3(0, 0, 0) -- math.sin(t * 0.8) * 0.5
    --self.model.transform.rotation = Vector3(0, 0, t * 0.5)
end

local function isDownInt(k)
    return love.keyboard.isDown(k) and 1 or 0
end
function App.static:moveCamera(dt)
    if self.console.active then return end
    local camera = self.horizon_mode and self.horizon_camera or self.camera

    local transform = camera.transform
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
    if self.horizon_mode then
        self:renderHorizonMode()
        return
    end

    self.renderer:render(self.camera, { self.model })
end

local horizon_image = love.graphics.newImage(love.image.newImageData(w, h))
function App.static:blitCanvas()
    local w, h = love.graphics.getDimensions()
    if self.horizon_mode then
        horizon_image:replacePixels(self.horizon_imagedata)
        love.graphics.draw(horizon_image, 0, 0)
        return
    end

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
    self.console:draw()
end

function App.static:keypressed(key, _, echo)
    if echo then return end
    if key == "`" then
        self.console.active = not self.console.active
    end
end


function App.static:initializeCanvas(w, h)
    w, h = 200 * w / h, 200
    w, h = math.floor(w), math.floor(h)
    self.resolution = Vector2(w, h)
    self.canvas = love.graphics.newCanvas(w, h)
    self.renderer = Renderer(self.canvas)
    self.renderer.clearColor = Vector3(0.05, 0.07, 0.1)
    self.camera.aspect = w / h
end


function App.static:filedropped(f)
    local fname = f:getFilename()

    if fname:find("obj") then
        local s = f:read()
        local models = ObjParser(s):parse()
        local _, model = next(models)
        if model then
            self.model = model
        end
    end

    if fname:find("png") or fname:find("jpg") then
		local data = f:read("data")
		local imageData = love.image.newImageData(data)
        self.model.texture = imageData
    end
end


local function applyMatrix(point, matrix)
    return matrix * Vector4(point, 1)
end

local math_floor = math.floor
function App.static:renderHorizonMode()
    love.graphics.setColor(1, 1, 1)
    self.horizon_imagedata:mapPixel(function() return 0, 0, 0, 1 end)
    local w, h = love.graphics.getDimensions()
    local bufferX, bufferY = {}, {}
    for i=0, w do bufferY[i] = h end

    local camera = self.horizon_camera
    local sampler = self.horizon_sampler

    local viewMatrix = camera:getViewMatrix()
    local transformedSampler = function(x, y)
        local z = sampler(x, y)
        local v = Vector3(x, y, z)
        v = applyMatrix(v, viewMatrix)
        v = v / v[4]

        v[1] = (v[1] + 1) / 2 * w
        v[2] = (v[2] + 1) / 2 * h

        return math_floor(v[1]), math_floor(v[2])
    end

    for y=6, -6, -0.1 do
        for x=-6, 6, 0.01 do
            local tx, ty = transformedSampler(x, y)
            if tx >= 0 and ty >= 0 and tx < w and ty < h then
                local by = bufferY[tx]
                if ty < by then
                    bufferY[tx] = ty
                    self.horizon_imagedata:setPixel(tx, ty, 1, 1, 1, 1)
                end
            end
        end
    end
end


App.static.consoleCommands = {
    exec = function(self, args)
        local path = "scripts/" .. args[1] .. ".txt"
        if not love.filesystem.getInfo(path, "file") then
            self.console:push("couldn't find file '" .. fname .. "'")
            return
        end
        
        local data = love.filesystem.read(path)
        for _, line in string.lines(data) do
            self.console:run(line)
        end
    end,

    move = function(self, args)
        local x,y,z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
        if not x or not y or not z then
            self.console:push("invalid arguments, expected x,y,z components")
            return
        end

        local position = self.model.transform.position
        position[1] = position[1] + x
        position[2] = position[2] + y
        position[3] = position[3] + z
    end,

    rotate = function(self, args)
        local x,y,z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
        if not x or not y or not z then
            self.console:push("invalid arguments, expected x,y,z components")
            return
        end

        local rotation = self.model.transform.rotation
        rotation[1] = rotation[1] + math.rad(x)
        rotation[2] = rotation[2] + math.rad(y)
        rotation[3] = rotation[3] + math.rad(z)
    end,

    scale = function(self, args)
        local x,y,z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
        if not x then
            self.console:push("invalid arguments, expected x,y,z components")
            return
        end
        
        if not y or not z then y, z = x, x end

        local scale = self.model.transform.scale
        scale[1] = scale[1] * x
        scale[2] = scale[2] * y
        scale[3] = scale[3] * z
    end,

    flip = function(self, args)
        local planeLookup = {yz=1,xz=2,xy=3}
        local axis = planeLookup[args[1] or ""]
        if not axis then
            self.console:push("invalid argument #1, expected yz/xz/xy")
            return
        end
        
        local scale = self.model.transform.scale
        scale[axis] = -scale[axis]
    end,

    solid_of_revolution = function(self, args)
        if not args[1] then
            self.console:push("invalid argument #1, expected function taking x (f.e. \"sin(x)\")")
            return
        end

        local func = loadstring("return (" .. args[1] .. ")")
        if not func then
            self.console:push("invalid argument #1, expected function taking x (f.e. \"sin(x)\")")
            return
        end

        local env = {}
        setmetatable(env, {__index = math})
        setfenv(func, env)
        local sampler = function(x)
            env.x = x
            return func()
        end

        local minX, maxX = tonumber(args[2]), tonumber(args[3])
        if not minX or not maxX then
            self.console:push("invalid argument #2/#3, expected bounds (min X and max X)")
            return
        end

        local resolutionX, resolutionY = tonumber(args[4]), tonumber(args[5])
        if not resolutionX or not resolutionY then
            self.console:push("invalid argument #4/#5, expected solid's resolution (segment count along X and along axis of rotation)")
            return
        end

        
        local capped = args[6] == "capped"
        self.model = geometry.buildSoR(sampler, minX, maxX, resolutionX, resolutionY, capped)
    end,

    plotxy = function(self, args)
        if not args[1] then
            self.console:push("invalid argument #1, expected function taking x and y (f.e. \"sin(x) + cos(y)\")")
            return
        end

        local func = loadstring("return (" .. args[1] .. ")")
        if not func then
            self.console:push("invalid argument #1, expected function taking x and y (f.e. \"sin(x) + cos(y)\")")
            return
        end

        local env = {}
        setmetatable(env, {__index = math})
        setfenv(func, env)
        local sampler = function(x, y)
            env.x, env.y = x, y
            return func()
        end

        local minX, maxX = tonumber(args[2]), tonumber(args[3])
        if not minX or not maxX then
            self.console:push("invalid argument #2/#3, expected bounds for X")
            return
        end

        local minY, maxY = tonumber(args[4]), tonumber(args[5])
        if not minX or not maxX then
            self.console:push("invalid argument #4/#5, expected bounds for Y")
            return
        end

        local resolutionX, resolutionY = tonumber(args[6]), tonumber(args[7])
        if not resolutionX or not resolutionY then
            self.console:push("invalid argument #6/#7, expected XY resolution (segment count along X and along Y)")
            return
        end

        self.model = geometry.buildPlotXY(sampler, Vector2(minX, minY), Vector2(maxX, maxY), Vector2(resolutionX, resolutionY))
    end,


    export = function(self, args)
        local path = args[1]
        if not path then
            self.console:push("invalid argument #1, expected path")
            return
        end

        self.model:export(path)
    end,


    horizon = function(self, args)
        self.horizon_mode = not self.horizon_mode

        if not self.horizon_mode then return end

        if not args[1] then
            self.console:push("invalid argument #1, expected function taking x and y")
            self.horizon_mode = false
            return
        end

        local func = loadstring("return (" .. args[1] .. ")")
        if not func then
            self.console:push("invalid argument #1, expected function taking x and y")
            self.horizon_mode = false
            return
        end

        local env = {}
        setmetatable(env, {__index = math})
        setfenv(func, env)
        local sampler = function(x, y)
            env.x, env.y = x, y
            return func()
        end

        local size = args[2] and tonumber(args[2]) or 4

        self.horizon_sampler = sampler
        self.horizon_imagedata = love.image.newImageData(w, h)
        self.horizon_camera = Camera(Vector3(8, 8, 8), Vector3(0, 0, 0), { aspect = self.camera.aspect, ortho = true, orthoSize = size })
        self.horizon_camera.transform:lookAt(Vector3(0, 0, 0))
    end,
}


function App.static:setupConsole()
    local console = self.console

    for k, v in pairs(self.consoleCommands) do
        console:addCommand(k, bind(v, self))
    end
end


return App
