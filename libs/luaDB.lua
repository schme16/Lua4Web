--[[
Copyright (c) 2011 Shane Gadsby https://github.com/schme16/Lua4Web || http://shanegadsby.info || http://opengaming.biz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

Except as contained in this notice, the name(s) of the above copyright holders
shall not be used in advertising or otherwise to promote the sale, use or
other dealings in this Software without prior written authorization.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]--

database = {}
database.__index = database
local databaseStore = 'database'
local debugState = true
function debugPrint(...)
	if debugState then
		print(...)
	end
end
--initializes the database, this is called by Lua4Web's module initializer
function databaseInit()
	print('Lua Database Engine Started!')
	if not utils.exists(databaseStore) then utils.mkdir(databaseStore) end
end

--Creates a database, only if there isn't one already with that name; returns the created database
function database:createDatabase(dbName, passphrase)
	if not os.rename(databaseStore..'/'..dbName,databaseStore..'/'..dbName) then 
		utils.mkdir(databaseStore..'/'..dbName)
		return setmetatable({passphrase = passphrase, dbName = dbName}, database)
	else
		return self:selectDatabase(dbName, passphrase)
	end

	
end

--Selects and returns a database, if it exists; does not create one
function database:selectDatabase(dbName, passphrase)
	if not(os.rename(databaseStore..'/'..dbName,databaseStore..'/'..dbName)) then
		debugPrint('Database does not exist or passphrase is incorrect')
		return false
	else
		return setmetatable({passphrase = passphrase, dbName = dbName}, database)
	end
end

--creates a table, only if it doens't; exists, returns the created table or calls the table select function if there is already a table with that name
function database:createTable(tableName)
	local tableFullName = tostring(databaseStore)..'/'..tostring(self.dbName)..'/'..tostring(tableName)..'.db'
	if not (utils.exists(tableFullName)) then 
		local tableVar,err = io.open(tostring(databaseStore)..'/'..tostring(self.dbName)..'/'..tostring(tableName)..'.db', 'w')
		tableVar:write(self:encrypt({}))
		tableVar:close()
		return true
	else
		debugPrint('Table exists!')
		return false
	end

end

--selects a table, only if it exists, returns the table or false
function database:selectTable(tableName)
	local tableFullName = tostring(databaseStore)..'/'..tostring(self.dbName)..'/'..tostring(tableName)..'.db'
	if (utils.exists(tableFullName)) then 
		local tableVar,err = io.open(tableFullName, 'rb')
		local data = self:decrypt(tableVar:read('*a'))
		tableVar:close()
		return data, true
	else
		debugPrint('Failed to select table, please check table exists!') 
		return false
	end
end

--inserts a new row into the given table
function database:createRow(tableName, data)
	local temp = self:selectTable(tableName) or {}
	--print(json.encode(temp))
	local tableFullName = tostring(databaseStore)..'/'..tostring(self.dbName)..'/'..tostring(tableName)..'.db'
	local tableVar,err = io.open(tableFullName, 'w+')
	--print(#temp)
	table.insert(temp, data)
	--print(#temp)
	tableVar:write(self:encrypt(temp))
	--tableVar:close()
end

--returns a row based on given table and row index
function database:selectRow(tableName, index)
	local temp = self:selectTable(tableName)
	return temp[index]
end




--This encrypts the data before writting it
function database:encrypt(data)
	return(string.crypt(
		json.encode(data),
		self.passphrase,
		0))
		
end

--This decrypts the data and returns the original table
function database:decrypt(data)
	local tempVar = string.crypt(data,self.passphrase,1)
	return json.decode(tempVar)
	--if not test then print('Wrong Passphrase') return false else return(test) end
end















if modules then table.insert(modules, databaseInit )  end








