	master = require("socket")
	bind = master.bind
	select = master.select
	
	WebServer = {
		_port = 8080,
		_header = 
			[[HTTP/1.1 200 OK
			Date: Fri, 19 Apr 2002 20:37:57 GMT
			Server: Apache/1.3.23 (Darwin) mod_ssl/2.8.7 OpenSSL/0.9.6b
			Cache-Control: max-age=60
			Expires: Fri, 19 Apr 2002 20:38:57 GMT
			Last-Modified: Tue, 16 Apr 2002 02:00:34 GMT
			ETag: "3c57e-1e47-3cbb85c2"
			Accept-Ranges: bytes
		Content-Length: ]].. string.len('1') ..[[
		Connection: close
			]],
	}
	
function WebServer:run()
  self._server = bind("localhost", self._port)
  self._server:settimeout(.01)
  self._clients = {}
  self._sendClients = {}
  print("WebServer running on port "..self._port)
end

function WebServer:lookForNewClients()
  local client = self._server:accept()
  if client then
    client:settimeout(1)
    table.insert(self._clients, client)
  end
end

function WebServer:mainLoop()
local clients = WebServer._clients
    WebServer:lookForNewClients()

    local receivingClients, _, error = select(clients, nil, .01)
    if error and error ~= "timeout" then
      print("error = "..tostring(error))
    end

    for i, c in ipairs( receivingClients) do

      local get, error = c:receive()

      if error then

print("error: "..tostring(error).." on c "..tostring(c))

        table.remove(clients, i)
      else
		local data = WebServer:serveFiles(string.sub(get,5,string.len(get)-9))
        local response = WebServer._header.. [[
		Content-Length: ]].. string.len(data) ..[[
		Connection: close
		]] .. "Content-Type: text/html\n\n" .. data
        error, bytesSent = c:send(response)
        c:close()
        table.remove(clients, i)
      end

    end
end

function WebServer:serveFiles(rawGet)
	local filePath = ''
	local noFile = false
	local data = ''
	local docroot = 'www'
	local errorMsg = {}
	errorMsg[404] = 'No File Found..... sorry?'
	local get, vars = WebServer:parseURIVars(rawGet)
	if get == '/' then
		if love.filesystem.exists(docroot..'/index.lp') then filePath = '/index.lp'
		else
			if love.filesystem.exists(docroot..'/index.html') then filePath = '/index.html'
			else
				if love.filesystem.exists(docroot..'/index.htm') then filePath = '/index.htm'
				else
					noFile = true	
				end
			end
		end
	else
		--print(docroot..get)
		if love.filesystem.exists(docroot..get) then
			filePath = get
		else
			noFile = true	
		end
	end
	
	if not(noFile) then
		if love.filesystem.exists(docroot..filePath) then
			data = love.filesystem.read(docroot..filePath)
		else
			data = errorMsg[404]
		
		end
	else
		data = errorMsg[404]
	end

	if noFile or  string.sub(get, string.len(get)-2) == '.lp' or string.sub(get, string.len(get)-3) == '.htm' or string.sub(get, string.len(get)-4) == '.html' then
		data = WebServer:postProccess(data)
	end
  return data

end

function WebServer:parseURIVars(get)
	local temp = explode('?', get)
	vars = explode('&', tostring(temp[2]))
	print(vars[1])
	return temp[1], temp[2]
end


function WebServer:postProccess(data)
	local tempData = explode('<?lua>',data)
	local pageViewable = ''
	for i,v in pairs(tempData) do
		local f = loadstring(string.sub(v, 6))
		if type(f)=='function' then
			f()
		else
			pageViewable = pageViewable..v
		end
	end
	return data
end









function explode(d,p)
  local t, ll
  t={}
  ll=0
  if(#p == 1) then return {p} end
    while true do
      l=string.find(p,d,ll,true) -- find the next d in the string
      if l~=nil then -- if "not not" found then..
        table.insert(t, string.sub(p,ll,l-1)) -- Save it in our array.
        ll=l+1 -- save just after where we found it for searching next time.
      else
        table.insert(t, string.sub(p,ll)) -- Save what's left in our array.
        break -- Break at end, as it should be, according to the lua manual.
      end
    end
  return t
end
