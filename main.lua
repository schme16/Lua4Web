require 'WebServer.lua'

function love.load()
	WebServer:run()
end


function love.update(dt)
	WebServer:mainLoop()

end


function love.draw(dt)
	love.graphics.print("Web Server started on port: "..WebServer._port,135,150)
end







