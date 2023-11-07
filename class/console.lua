local Event = require("event")

local Console = class("Console")


function Console:initialize(capacity)
    capacity = capacity or 100

    self.active = false

    self.commands = {}
    self.onCommand = Event()
    self.onCommand:add(function(cmd, args, s)
        self:push("> " .. s)
    end)

    self.history = {}
    self.history_capacity = capacity
    self.history_index = 1

    self.executed_lines = {}
    self.executed_index = 0

    self.scroll = 0
    self.visible_line_count = 16

    self.input = ""

    love.textinput:add(bind(self.textinput, self))
    love.keypressed:add(bind(self.keypressed, self))
end


function Console:addCommand(key, func)
    self.commands[key] = func
end


function Console:push(...)
    local s = table.concat({...}, " ")
    self.history[self.history_index] = s
    self.history_index = self.history_index % self.history_capacity + 1
end


function Console:draw()
    if not self.active then return end
    local w, h = love.graphics.getDimensions()

    local visible_line_count = self.visible_line_count
    love.graphics.setColor(0.2, 0.2, 0.2, 0.3)
    love.graphics.rectangle("fill", 0, 0, w, 5 + visible_line_count * 16 + 24)
    love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
    love.graphics.rectangle("fill", 0, 5 + visible_line_count * 16, w, 24)

    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    local history = self.history
    local history_index = self.history_index
    local current_visible_line_count = math.min(visible_line_count, #self.history)
    local index = (history_index + self.history_capacity - 1 - self.scroll) % self.history_capacity
    local i = 1
    while i <= current_visible_line_count and index ~= history_index do
        local line = history[index]
        local yi = current_visible_line_count - i
        love.graphics.print(line, 5, 5 + yi * 16)

        i = i + 1
        index = (index + self.history_capacity - 1) % self.history_capacity
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(self.input, 5, 5 + visible_line_count * 16 + 6)
end


function Console:run(s)
    local args = string.split(s, " ")
    local command = args[1]
    table.remove(args, 1)
    self.onCommand:invoke(command, args, s)

    local commandFunc = self.commands[command]
    if not commandFunc then
        self:push("unknown command.")
        return
    end

    commandFunc(args)
end


function Console:textinput(c)
    if not self.active then return end
    if c == "`" then return end
    self.executed_index = 0
    self.input = self.input .. c
end


function Console:keypressed(key)
    if not self.active then return end

    if key == "return" and #self.input > 0 then
        self:run(self.input)

        if self.executed_index ~= 1 then
            table.insert(self.executed_lines, 1, self.input)
        end

        self.executed_index = 0

        self.input = ""
        return
    end
    
    if key == "backspace" then
        self.input = self.input:sub(1, #self.input - 1)
    end

    if key == "up" then
        if love.keyboard.isDown("lctrl") then
            self.scroll = math.min(self.scroll + 1, math.max(#self.history - self.visible_line_count, 0))
        else
            if self.executed_index == 0 then
                self.executed_lines[0] = self.input
            end
            
            self.executed_index = math.min(self.executed_index + 1, #self.executed_lines)
            self.input = self.executed_lines[self.executed_index]
        end
    end

    if key == "down" then
        if love.keyboard.isDown("lctrl") then
            self.scroll = math.max(self.scroll - 1, 0)
        elseif self.executed_index > 0 then
            self.executed_index = math.max(self.executed_index - 1, 0)
            self.input = self.executed_lines[self.executed_index] or ""
        end
    end
end


return Console
