master = require("socket")
bind = master.bind
select = master.select
errorMsg = {}
	errorMsg[404] = 'No File Found..... sorry?'
	errorMsg[200] = ''

WebServer = {
	largeFileList = {},
	_port = 80,
	_header = [[

]],
	_timeout =  0.0001,
}

modules = {}

function WebServer:init()
  WebServer._server = bind("*", WebServer._port)
  if not(WebServer._server) then print('Port: '..WebServer._port..' Unavailable') return end
  WebServer._server:settimeout(WebServer._timeout)
  WebServer._clients = {}
  WebServer._sendClients = {}
  print("WebServer running on port "..WebServer._port)
end

function WebServer:lookForNewClients()
  local client = self._server:accept()
  if client then
    client:settimeout(self._timeout)
    table.insert(self._clients, client)
  end
end

function WebServer:run()
	local clients = WebServer._clients
	WebServer:lookForNewClients()

	local receivingClients, _, err = select(clients, nil,WebServer._timeout)
	if err and err ~= "timeout" then
	  print("error = "..tostring(err))
	end

	for i, c in ipairs( receivingClients ) do
		local get, err = clientRead(c, '*a')

		if err then
			table.remove(clients, i)
		else
			local data = WebServer:serveFiles(string.sub(get,5,string.len(get)-9))
			if not(data) then data = ' Oops, there was an error!' end
			data = WebServer:_header(data, '')..data
			bytesSent, err,index = c:send(data,1)
			table.insert( WebServer.largeFileList ,{b = bytesSent, e = err, i = index, c = c, d = data})
			table.remove(clients, i)

			
			
		end
	end
	WebServer:largeFileDispatch()
end

function WebServer:_header(data, get)
	local status = 200
	local header = 
[[
	
]]

for i,v in ipairs(errorMsg) do
	if data == v then
		status = i
	end
end

	header = header..
[[	HTTP/1.1 ]]..status..[[ OK
	Date: ]]..os.date('%a, %d %b %Y %H:%M:%S')..[[ GMT +10
	Server: Lua4Web Rev3 (Cross-Platform)  (x86 Arch)
	Last-Modified: ]]..os.date('%a, %d %b %Y %H:%M:%S')..[[ GMT +10
	Accept-Ranges: bytes
	Content-Length: ]]..(string.len(data)/8)..[[
	
	Connection: keep-alive

]] return header
--Content-Type: text/html; charset=UTF-8
end

function WebServer:largeFileDispatch()
	for i,v in ipairs(WebServer.largeFileList) do
		if v.e ~= 'timeout' or not(v.i) then 
			v.c:close() table.remove(WebServer.largeFileList,i)
		else
			v.b, v.e,v.i = v.c:send(v.d,v.i+1)
		end

	end
end

function WebServer:parseURIVars(headers)
	local headerList = {}
	local test = 1
	local index = 1
	
	--this finds post data
	for i = 0, string.len(headers) do
		local test = (string.find(headers, '\n\r'))
		if not (test) then break end
		index = test
	end
	
	

	--Coalate POST
	post = {}
		
	local tempPost = tostring(string.gsub(string.sub(tostring(headers),index+3),'+', ' '))

	varsTemp = explode('&', tempPost)
	for i,v in ipairs(varsTemp) do
		local temp = explode('=', v)
		post[temp[1]] =  url_decode(tostring(temp[2]))
	end

	
	--Coalate GET
	local get = {}
	local tempString = string.sub(headers,2, string.find(headers, '\n')-11)
	if tempString == '?' then tempString = '' end
	local tempGet = explode('?', tempString)
	
	varsTemp = explode('&', tostring(tempGet[2]))
	for i,v in ipairs(varsTemp) do
		local temp = explode('=', v)
		get[temp[1]] = url_decode(tostring(temp[2]))
	end
	
	
	--print(get)
	return tempGet[1], {get = get, post = post}
	
end

function WebServer:serveFiles(rawGet)
	local filePath = ''
	local data
	local docroot = 'www'
	local errorMsg = {}
	--print(rawGet)
	local get, vars = WebServer:parseURIVars(rawGet)
	if get == '/'  or get == '' then
		fileHandle = io.open ( docroot..'/index.lp')
		get = docroot..'/index.lp'
		if not(fileHandle) then 
			fileHandle = io.open ( docroot..'/index.html')
			get = docroot..'/index.html'
			if not(fileHandle) then 
				fileHandle = io.open ( docroot..'/index.htm')
				get = docroot..'/index.htm'
				if not(fileHandle) then data = errorMsg[404]	end
			end
		end
	else
	docroot = docroot..'/'
		fileHandle = io.open ( docroot..get,'rb')		
		if not(fileHandle) then data = errorMsg[404]	end
	end

	if fileHandle then data = fileHandle:read("*a") end
	if (fileHandle and get=='/') or
		string.sub(get, string.len(get)-2) == '.lp' or
		string.sub(get, string.len(get)-3) == '.htm' or
		string.sub(get, string.len(get)-4) == '.html' then
			data = tostring(WebServer:postProccess(data,vars))
			
	elseif get=='/' and not(fileHandle) then
		data = 'No Index file found, but one was requested.'
	elseif not(get=='/') and not(fileHandle) then
		data = 'Data could not be read from file; Please check that file is not locked or encrypted!'
	end
  return data

end

function WebServer:postProccess(rawData,vars)
	local pageViewable = ''
	local data = ''
	local tempData = explode("[lua]",tostring(rawData))
	local codeBlocks = {} 



	-- make environment, including only that which is either necessary or safe
	local env = {
		print=function(x) if x==nil then x ='' end pageViewable = pageViewable..tostring(x)  end,
		error = function(...) print(...) end,
		errorTable = function(tableVar) print(json.encode(tableVar)) end,
		ipairs=ipairs,
		tostring = tostring,
		GET = vars.get,
		POST = vars.post,
		DB = database,
		json = json,
		string = string,
	}
	local function run(untrusted_code)
		local untrusted_function, message = loadstring(untrusted_code)
		if not untrusted_function then print( message) return false end
		setfenv(untrusted_function, env)
		local temp, err = pcall(untrusted_function)
		if err == nil then
		else
			print(err)
		end
		return true
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





function url_decode(str)
  str = string.gsub (str, "+", " ")
  str = string.gsub (str, "%%(%x%x)",
      function(h) return string.char(tonumber(h,16)) end)
  str = string.gsub (str, "\r\n", "\n")
  return str
end

function clientRead(client, pattern, prefix)

	local data, emsg, partial = client:receive(pattern, prefix)

	if data then
		return data
	end
	if partial and #partial > 0 then
		return partial
	end
	
	return false, emsg

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









table.insert(modules, WebServer.init )










