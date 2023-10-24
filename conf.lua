function love.conf(t)
    t.identity = "WASR"

    t.window.title = "Whole-Ass Software Renderer"
    t.window.width = 960
    t.window.height = 540
    t.window.resizable = true

    t.modules.audio     = false
    t.modules.data      = true
    t.modules.event     = true
    t.modules.font      = true
    t.modules.graphics  = true
    t.modules.image     = true
    t.modules.joystick  = false
    t.modules.keyboard  = true
    t.modules.math      = true
    t.modules.mouse     = true
    t.modules.physics   = false
    t.modules.sound     = false
    t.modules.system    = true
    t.modules.thread    = true
    t.modules.timer     = true
    t.modules.touch     = false
    t.modules.video     = true
    t.modules.window    = true
end