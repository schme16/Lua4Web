
master = require("socket")
bind = master.bind
select = master.select
errorMsg = {}
	errorMsg[404] = 'No File Found..... sorry?'

WebServer = {
	_port = 80,
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
  self._server = bind("192.168.1.3", self._port)
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

    local receivingClients, _, error = select(clients, nil, .001)
    if error and error ~= "timeout" then
      print("error = "..tostring(error))
    end

    for i, c in ipairs( receivingClients ) do

      local get, error = c:receive()

      if error then

print("error: "..tostring(error).." on c "..tostring(c))
        table.remove(clients, i)
      else
		
		print(c:getsockname())
	  
		local data = WebServer:serveFiles(string.sub(get,5,string.len(get)-9))
        error, bytesSent = c:send(tostring(data))
        c:close()
        table.remove(clients, i)
      end

    end
end

function WebServer:parseURIVars(get)
	local temp = explode('?', get)
	local vars = {}
	varsTemp = explode('&', tostring(temp[2]))
	for i,v in ipairs(varsTemp) do
		local temp = explode('=', v)
		vars[temp[1]] = temp[2]
	end

	return temp[1], vars
end

function WebServer:serveFiles(rawGet)
	local filePath = ''
	local data
	local docroot = 'www'
	local errorMsg = {}
	local get, vars = WebServer:parseURIVars(rawGet)

	if get == '/' then
		fileHandle = io.open ( docroot..'/index.lp')
		if not(fileHandle) then 
			fileHandle = io.open ( docroot..'/index.html')
			if not(fileHandle) then 
				fileHandle = io.open ( docroot..'/index.htm')
				if not(fileHandle) then data = errorMsg[404]	end
			end
		end
	else
		fileHandle = io.open ( docroot..get,'rb')		
		if not(fileHandle) then data = errorMsg[404]	end
	end

	if fileHandle then data = fileHandle:read("*a") end
	if (fileHandle and get=='/') or  string.sub(get, string.len(get)-4) == '.lp' or string.sub(get, string.len(get)-5) == '.htm' or string.sub(get, string.len(get)-6) == '.html' then
		data = WebServer:postProccess(data,vars)
	end
  return data

end

function WebServer:postProccess(rawData,vars)
	local pageViewable = ''
	local data = ''
	local tempData = explode("[lua]",rawData)
	local codeBlocks = {} 



	-- make environment
	asdasd='poooooo'
	local env = {
		print=function(x) if x==nil then x ='' end pageViewable = pageViewable..tostring(x)  end,
		ipairs=ipairs,
		tostring = tostring,
		error = function() print('there was an errror!') end,
		GET = vars
	}
	local function run(untrusted_code)
		local untrusted_function, message = loadstring(untrusted_code)
		if not untrusted_function then return nil, message end
		setfenv(untrusted_function, env)
		return pcall(untrusted_function)
	end	
	
		
	for i,v in ipairs(tempData) do
		if i ~= 1 then
			local temp = explode('[/lua]', string.sub(v, 5) )
			local runCode,msg = run(temp[1])
			if (runCode) and temp[2] then 
				pageViewable = pageViewable..string.sub(temp[2],6)
			end
			
		else
			pageViewable = pageViewable..v
		end
	end
	
	return tostring(pageViewable..'\n')
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
