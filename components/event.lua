local Event = {}
local Event_static = {}


function Event:initialize()
    self.head = nil
    self.tail = nil
    self.map = {}
end


function Event:add(key, func)
    if func == nil then
        assert(key ~= nil, "invalid argument #1 (expected function or non-nil key)")
        func = key
    end

    assert(func ~= nil, "invalid argument #2 (expected function)")
    assert(key ~= nil, "invalid argument #1 (key cannot be nil)")

    local map = self.map
    local existing_node = map[key]
    if existing_node then
        existing_node.func = func
        return self
    end

    local node = {
        key = key,
        func = func,
        next = nil,
        prev = self.tail,
    }

    map[key] = node
    
    if not self.head then
        self.head = node
        self.tail = node
        return self
    end

    self.tail.next = node
    self.tail = node

    return self
end


function Event:remove(key)
    assert(key ~= nil, "invalid argument #1 (key cannot be nil)")

    local map = self.map
    local node = map[key]
    if not node then return self end
    map[key] = nil
    
    local prev = node.prev
    local next = node.next

    if node.prev then
        node.prev.next = next
    end

    if node.next then
        node.next.prev = prev
    end

    if node == self.head then
        self.head = next
    end

    if node == self.tail then
        self.tail = prev
    end

    return self
end


local table_unpack = table.unpack or unpack
function Event:invoke(...)
    local result
    local node = self.head
    while node do
        local new_result = {node.func(...)}
        local is_empty = next(new_result) == nil
        if not result and not is_empty then
            result = new_result
        end
        node = node.next
    end

    if result then
        return table_unpack(result)
    end
end


function Event:add_oneshot(key, func)
    if func == nil then
        assert(key ~= nil, "invalid argument #1 (expected function or non-nil key)")
        func = key
    end

    func = function(...)
        self:remove(key)
        return func(...)
    end

    self:add(key, func)
end


local Event_instance_mt = {}
Event_instance_mt.__type = "Event"
Event_instance_mt.__index = Event
Event_instance_mt.__call = Event.invoke

local Event_class_mt = {
    __call = function(self, ...)
        return self.new(...)
    end
}

local Event_class = Event_static
function Event_class.new(...)
    local instance = {}
    setmetatable(instance, Event_instance_mt)
    instance:initialize(...)
    return instance
end
Event_class.metatable = Event_instance_mt
setmetatable(Event_class, Event_class_mt)

return Event_class