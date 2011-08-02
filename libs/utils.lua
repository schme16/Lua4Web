	utils = {}
	function utils.mkdir(dir)
		local test = os.execute(' mkdir "' ..dir..'"')
		if test == 256 then os.execute(' mkdir -p "' ..dir..'"') end
	end
	
	function utils.exists(filePath)
		local test = io.open(filePath, 'r')
		if test then
			return true
		else 
			return false 
		end
	end
	
	function utils.exists(dir)
		local temp1,temp2,temp3 = os.rename(dir,dir)
		if temp1 == nil then
			return false
		else
			return true
		end
	end
	table.insert(modules,function() print('Utils. Library loaded') end)