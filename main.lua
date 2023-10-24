-- ========= Hiii, Hellooooo :) ========= --


-- Adding paths
do
    local folders = {
        "class",
        "components",
        "lib",
    }

    local cfolders = {
        "class",
        "components",
    }

    for _, s in ipairs(folders) do
        love.filesystem.setRequirePath((love.filesystem.getRequirePath() or "") ..
            ";" .. s .. "/?/init.lua" ..
            ";" .. s .. "/?.lua")
    end

    for _, s in ipairs(folders) do
        love.filesystem.setCRequirePath((love.filesystem.getCRequirePath() or "") .. ";lib/?.dll")
    end
end


--- Runs a function on all files[and dirs] in a folder [recursively]
---@param dir string
---@param func function
---@param recursive boolean
---@param dirfunc function
local function loadfolder(dir, func, recursive, dirfunc)
    dirfunc = dirfunc or nilfunc
    for _, file in pairs(love.filesystem.getDirectoryItems(dir)) do
        local path = dir .. "/" .. file
        local info = love.filesystem.getInfo(path)
        if info.type == "file" then
            func(path)
        elseif info.type == "directory" then
            dirfunc(path)
            if recursive then
                loadfolder(path, func, recursive, dirfunc)
            end
        end
        -- Ignoring symlinks (for now)
    end
end

-- Loading includes
do
    loadfolder("include", dofile, true)
end


class = require("middleclass")

function love.load(...)
    require("app"):run(...)
end
