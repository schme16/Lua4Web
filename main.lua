webLib = loadfile("WebServer.lua")

if (webLib) then
	webLib()
	WebServer:run()

	while true do
		WebServer:mainLoop()
	end
else
	print('Failed to load WebServer Library')
	while true do
	end
end




