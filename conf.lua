function love.conf(t)
	t.title = "Love Web Server"
	t.author = "Shane Gadsby"
	t.email = "schme16@gmail.com"
	t.console = true
	t.modules.joystick = false   -- Enable the joystick module (boolean)
	t.modules.physics = false    -- Enable the physics module (boolean)
	--t.modules.images = false       -- Enable vertical sync (boolean)
	--t.modules.graphics = false       -- Enable vertical sync (boolean)
	t.screen.vsync = false       -- Enable vertical sync (boolean)
	t.screen.fsaa = 0           -- The number of FSAA-buffers (number)
	t.screen.width = 480       -- The window height (number)
	t.screen.height = 320       -- The window height (number)
end