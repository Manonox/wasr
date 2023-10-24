local function string_replace(str, find, rep)
    local i = 1
    local s
    local e
    local nstr = ""
    repeat
        s, e = string.find(str, find, i, true)
        if s then
            nstr = nstr .. string.sub(str, i, s - 1) .. rep
            i = e + 1
        end
    until not s
    nstr = nstr .. string.sub(str, i)
    return nstr
end

local PATH_CACHE = {}

--- Converts a path to a require string
---@param path string
---@return string
local function convertpath(p)
    if not PATH_CACHE[p] then
        local newp = string_replace(p, "/", ".")
        -- local dot = false
        -- while not dot do
        --     dot = dot or (newp:sub(#newp, #newp) == ".")
        --     newp = newp:sub(1, #newp - 1)
        -- end
        PATH_CACHE[p] = newp
    end
    return PATH_CACHE[p]
end


rawrequire = require
require = function(p)
    return rawrequire(convertpath(p))
end
