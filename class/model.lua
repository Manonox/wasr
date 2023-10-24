local Transform = require("transform")
local Model = class("Model")


function Model:initialize(position, rotation, scale, vertices, faces)
    self.transform = Transform(position, rotation, scale)
    self.vertices = vertices
    self.faces = faces
end


return Model
