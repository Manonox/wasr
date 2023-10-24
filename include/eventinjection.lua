local Event = require("event")


love.update = Event()
love.draw = Event()

for k, v in pairs(love.handlers) do
    love[k] = Event()
end
