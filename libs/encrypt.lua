function string.crypt(string,key,mode)
	local new_string = ""
	local pass = 0 
	for c_key = 1, #key do 
		pass = pass + string.byte(string.sub(key,c_key,c_key))
	end 
	if pass > 255 then
			pass =  math.floor(pass / (pass/255 +1))
	end
	if mode == 0 then 
			for encrypt = 1,#string do 
			add_byte = string.byte(string.sub(string,encrypt,encrypt)) 
			if add_byte + pass > 255 then 
					add_byte = add_byte + pass - 255
			else
					add_byte = add_byte + pass
			end

			add_string = string.char(add_byte) 
			new_string = new_string..add_string
			end 
	elseif mode == 1 then 
			for decrypt = 1,#string do 
			add_byte = string.byte(string.sub(string,decrypt,decrypt)) 
			if add_byte - pass  < 0 then 
					add_byte = 255 + add_byte-pass 
			else
					add_byte = add_byte - pass
			end

			add_string = string.char(add_byte) 
			new_string = new_string..add_string
			end 
	end 
	string = nil 
	return new_string
end