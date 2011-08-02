modules = {}


webLib = loadfile("WebServer.lua")
DBLoad = loadfile("libs/luaDB.lua")
crypto = loadfile( "libs/encrypt.lua")
jsonLoad = loadfile( "libs/json.lua")
utilsLoad = loadfile( "libs/utils.lua")


	if utilsLoad then utilsLoad()  end
	if webLib then webLib()  end
	if jsonLoad then jsonLoad()  end
	
	if DBLoad then DBLoad()  end
	if crypto then crypto() end
	
	for i,v in ipairs(modules) do
		if type(v) == 'function' then v() end
	end

	while true do
		if WebServer then WebServer:run() end
	end
