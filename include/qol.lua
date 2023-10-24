do -- ========================== INSPECT/PRINTTABLE ==========================
    inspect = require("inspect")
    printtable = function(x) print(inspect(x)) end
    printTable = printtable
end


do -- ========================== STRINGS ==========================
    function string.lines(s)
        local i = 0
        return function()
            if s == "" then return end
            local endPos = s:find("\n")
            if not endPos then
                local s2 = s
                s = ""
                return i + 1, s2
            end
            local r = s:sub(1, endPos-1)
            s = s:sub(endPos + 1)
            i = i + 1
            return i, r
        end
    end
    
    function string.strip(s)
        s = string.gsub(s, "^%c+", "")
        s = string.gsub(s, "%c+$", "")
        return s
    end

    function string.replace(str, find, rep)
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

    function string.zfill(s, l, symb)
        s = s .. ""
        symb = symb or " "
        local spaces = math.max(l - #s, 0)
        return string.rep(symb, spaces) .. s
    end

    function string.left(s, n)
        if n < 1 then return "" end
        return string.sub(s, 1, n)
    end
    function string.right(s, n)
        if n < 1 then return "" end
        return string.sub(s, #s+1-n, #s)
    end

    function string.dropext(s)
        local ext = ""
        local dot
        while not dot do
            local c = s:sub(#s, #s)
            dot = c == "."
            ext = (dot and "" or c) .. ext
            s = s:sub(1, #s - 1)
        end
        return s, ext
    end
end


do -- ========================== TABLES ==========================     
    function table.values(t)
        local r = {}
        for _, v in pairs(t) do table.insert(r, v) end
        return r
    end
    
    
    function table.set(...)
        return table.makeset({...})
    end
    
    ---@param tbl table
    ---@return table
    function table.setFrom(tbl)
        local r = {}
        for i, v in pairs(tbl) do r[v] = true end
        return r
    end
end


do -- ========================== LOVE2D ==========================
    local shader = love.graphics.newShader([[vec4 effect(vec4 col, Image i, vec2 tx, vec2 px) { return vec4(0.0,0.0,0.0,0.0); }]])
    local ShaderMeta = getmetatable(shader)
    shader:release()
    function ShaderMeta:renderWith(func)
        local prev_shader = love.graphics.getShader()
        love.graphics.setShader(self)
            func()
        love.graphics.setShader(prev_shader)
    end
    local old_ShaderMetaSend = ShaderMeta.send
    function ShaderMeta:send(name, ...)
        if self:hasUniform(name) then
            old_ShaderMetaSend(self, name, ...)
        end -- TODO: Debug?
        return self
    end

    local canvas = love.graphics.newCanvas(1, 1)
    local CanvasMeta = getmetatable(canvas)
    canvas:release()
    function CanvasMeta:renderTo(func)
        local prev_canvas = love.graphics.getCanvas()
        love.graphics.setCanvas(self)
            func()
        love.graphics.setCanvas(prev_canvas)
    end

    local time_start = love.timer.getTime()
    local old_love_timer_getTime = love.timer.getTime
    love.timer.getCurTime = old_love_timer_getTime
    function love.timer.getTime()
        return old_love_timer_getTime() - time_start
    end
end
