local lume = require("lume")
local lume_map = {
    math = {
        "clamp",
        "round",
        "sign",
        "lerp"
    },

    table = {
        "randomchoice",
        "weightedchoice",
        "isarray",
        "push",
        delete = "remove",
        "clear",
        "extend",
        "shuffle",
        sortx = "sort",
        "array",
        "each",
        "map",
        "all",
        "any",
        "reduce",
        "unique",
        "filter",
        "reject",
        "merge",
        concatx = "concat",
        "find",
        "match",
        "count",
        "slice",
        "first",
        "last",
        "invert",
        "pick",
        "keys",
        "clone"
    },

    string = {
        "split",
        "trim",
        "wordwrap",
        formatx = "format"
    }
}

lambda = lume.lambda
ripairs = lume.ripairs
uuid = lume.uuid
memoize = lume.memoize
for lib, funcs in pairs(lume_map) do
    for k, lumename in pairs(funcs) do
        if type(k) == "number" then
            k = lumename
        end
        _G[lib][k] = lume[lumename]
    end
end
