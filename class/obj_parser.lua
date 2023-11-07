local Model = require("model")
local mgl = require("MGL")

local ObjParser = class("ObjParser")

function ObjParser:initialize(text)
    self.text = text
    
    self.o = nil
    self.v = { }
    self.vt = { }
    self.vn = { }
    self.f = { }

    self.models = { }
end


local function parseVector3(args)
    return Vector3(tonumber(args[1]), tonumber(args[2]), tonumber(args[3]))
end

local function parseVector2(args)
    return Vector2(tonumber(args[1]), tonumber(args[2]))
end

local function parseSlashTriplet(s)
    local split = string.split(s, "/")
    return { tonumber(split[1]), tonumber(split[2]), tonumber(split[3]) }
end

local function parseSlashTripletTriplet(args)
    return { parseSlashTriplet(args[1]), parseSlashTriplet(args[2]), parseSlashTriplet(args[3]) }
end

ObjParser.static.commands = {
    o = function(self, args)
        if self.o then
            self:finalizeModel()
            self:clearData()
        end
        self.o = args[1]
    end,

    v = function(self, args)
        local t = self.v
        t[#t + 1] = parseVector3(args)
    end,

    vn = function(self, args)
        local t = self.vn
        t[#t + 1] = parseVector3(args)
    end,

    vt = function(self, args)
        local t = self.vt
        t[#t + 1] = parseVector2(args)
    end,

    f = function(self, args)
        local t = self.f
        t[#t + 1] = parseSlashTripletTriplet(args)
    end
}

local table_remove = table.remove
function ObjParser:parse()
    local commands = self.class.static.commands
    for _, line in string.lines(self.text) do
        if #line < 2 then goto cont end
        if line:sub(1, 1) == "#" then goto cont end

        local split = string.split(line, " ")
        local commandId = split[1]
        table_remove(split, 1)
        local args = split

        local command = commands[commandId]
        if command then
            command(self, args)
        end

        ::cont::
    end
    
    self:finalizeModel()
    self:clearData()
    return self.models
end


function ObjParser:finalizeModel()
    local vertices, faces = self:normalizeModel()
    self.models[self.o] = Model(
        Vector3(0, 0, 0),
        Vector3(0, 0, 0),
        Vector3(1, 1, 1),
        vertices, faces
    )
end


local sun = Vector3(-0.5, -0.5, -1)
sun = -mgl.normalize(sun)
-- todo: actually normalize models, lol
function ObjParser:normalizeModel()
    local vertices, faces = { }, { }
    
    local vn = self.vn
    for i, v in ipairs(self.v) do
        local n = vn[i]
        local lightness = n and ((mgl.dot(n, sun) * 0.5 + 0.5) * 0.9 + 0.1) or math.random()
        vertices[#vertices + 1] = { v, n or Vector3(0, 0, 0), Vector3(lightness, lightness, lightness) }
    end

    for _, f in ipairs(self.f) do
        faces[#faces + 1] = { f[1][1], f[2][1], f[3][1] }
    end
    return vertices, faces
end


function ObjParser:clearData()
    self.o = nil
    self.v = { }
    self.vt = { }
    self.vn = { }
    self.f = { }
end


return ObjParser
