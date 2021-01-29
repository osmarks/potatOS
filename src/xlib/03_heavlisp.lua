if not unpack then unpack = table.unpack end
local pprint = require("pprint")
function deepclone(t)
	local res={}
	for i,v in ipairs(t) do
		if type(v)=="table" then
			res[i]=deepclone(v)
		else
			res[i]=v
		end
	end
	return res
end
function tokenize(str)
	local ptr=1
	local tokens={}
	local line=1
	local function isIn(e,s)
		for i=1,#s do
			if s:sub(i,i)==e then return true end
		end
		return false
	end
	local function isInT(e,s)
		for i=1,#s do
			if s[i]==e then return true end
		end
		return false
	end
	local function isNotIdent(c)
		return isIn(c,"()[] \n\t\v\r\f\";'`")
	end
	local function isDigit(c)
		return isIn(c,"0123456789")
	end
	while true do
		local c=str:sub(ptr,ptr)
		if c=="(" then table.insert(tokens,{"(",line=line}) ptr=ptr+1
		elseif c==")" then table.insert(tokens,{")",line=line}) ptr=ptr+1
		elseif c=="[" then table.insert(tokens,{"[",line=line}) ptr=ptr+1
		elseif c=="]" then table.insert(tokens,{"]",line=line}) ptr=ptr+1
		elseif c=="\n" then line=line+1 ptr=ptr+1
		elseif c==" " or c=="\t" or c=="\v" or c=="\f" or c=="\r" or c==";" then ptr=ptr+1 --ignore whitespace. semicolon is treated as whitespace, somewhat.
		elseif c=="/" and str:sub(ptr+1,ptr+1)=="/" then
			ptr=ptr+1
			local nc=str:sub(ptr,ptr)
			while nc~="\n" and ptr<=#str do
				ptr=ptr+1
				nc=str:sub(ptr,ptr)
			end
			line=line+1
			ptr=ptr+1
		elseif c=="," then table.insert(tokens,{",",line=line}) ptr=ptr+1
		elseif c==":" then table.insert(tokens,{"string",str:sub(ptr+1,ptr+1),line=line}) if str:sub(ptr+1,ptr+1)=="\n" then line=line+1 end ptr=ptr+2
		elseif c=="'" then
			local res=""
			ptr=ptr+1
			local nc=str:sub(ptr,ptr)
			while not isNotIdent(nc) and ptr<=#str do
				ptr=ptr+1
				res=res..nc
				nc=str:sub(ptr,ptr)
			end
			table.insert(tokens,{"string",res,line=line})
		elseif c=="\"" then
			local res=""
			ptr=ptr+1
			local nc=str:sub(ptr,ptr)
			while nc~="\"" and ptr<=#str do
				if nc=="\\" then ptr=ptr+1 nc=str:sub(ptr,ptr) end
				if nc=="\n" then line=line+1 end
				res=res..nc
				ptr=ptr+1
				nc=str:sub(ptr,ptr)
			end
			ptr=ptr+1
			table.insert(tokens,{"string",res,line=line})
		elseif c=="`" and str:sub(ptr+1,ptr+1)=="`" then
			local res=""
			ptr=ptr+2
			local nc=str:sub(ptr,ptr+1)
			while nc~="``" and ptr<=#str do
				if nc:sub(1,1)=="\\" then ptr=ptr+1 nc=str:sub(ptr,ptr) end
				if nc:sub(1,1)=="\n" then line=line+1 end
				res=res..nc:sub(1,1)
				ptr=ptr+1
				nc=str:sub(ptr,ptr+1)
			end
			ptr=ptr+2
			table.insert(tokens,{"string",res,line=line})
		elseif isDigit(c) then
			local res=c
			ptr=ptr+1
			local nc=str:sub(ptr,ptr)
			while isDigit(nc) and ptr<=#str do
				ptr=ptr+1
				res=res..nc
				nc=str:sub(ptr,ptr)
			end
			table.insert(tokens,{"number",tonumber(res,10),line=line})
		elseif ptr>#str then break
		elseif not isNotIdent(c) then
			local res=c
			ptr=ptr+1
			local nc=str:sub(ptr,ptr)
			while not isNotIdent(nc) and ptr<=#str do
				ptr=ptr+1
				res=res..nc
				nc=str:sub(ptr,ptr)
			end
			table.insert(tokens,{"identifier",res,line=line})
		else print("no idea what this is: "..c) ptr=ptr+1 end
	end
	table.insert(tokens,{"EOF"})
	return tokens
end

function into_ast(tokens)
	local ptr=1
	local function expect(token)
		if tokens[ptr][1]~=token then
			error("expected "..token..", got "..tokens[ptr][1])
		end
		return tokens[ptr]
	end
	local function expect2(token)
		if tokens[ptr][2]~=token then
			error("expected "..token..", got "..tokens[ptr][2] and tokens[ptr][2] or tokens[ptr][1])
		end
		return tokens[ptr]
	end
	local function combinator_and(p,p2)
		return function()
			local bk=ptr
			local r1,r2=p(),p2()
			if not (r1 and r2) then
				ptr=bk
				return false
			end
			return {r1,r2}
		end
	end
	local function combinator_or(p,p2)
		return function()
			local bk=ptr
			local r1=p()
			if not r1 then
				local r2=p2()
				if not r2 then
					ptr=bk
					return false
				end
				return r2
			end
			return r1
		end
	end
	local function any_amount(p)
		return function()
			local res={}
			while true do
				local bk=ptr
				local tmp=p()
				if (tmp==nil) or tmp==false or tokens[bk][1]=="EOF" then ptr=bk break end
				table.insert(res,tmp)
			end
			return res
		end
	end
	local function any_eof(p)
		return function()
			local res={}
			while true do
				local bk=ptr
				local tmp=p()
				if (tmp==nil) or tmp==false or tokens[bk][1]=="EOF" then
					if tokens[bk][1]~="EOF" then
						print("line "..tokens[bk].line..": some syntax error occured.")
						os.exit(1)
					end
					ptr=bk
					break
				end
				table.insert(res,tmp)
			end
			return res
		end
	end
	local function more_than_one(p)
		return function()
			local bk=ptr
			local r1=p()
			if not r1 or tokens[bk][1]=="EOF" then ptr=bk return false end
			local res={r1}
			while true do
				local bk=ptr
				local tmp=p()
				if (tmp==nil) or tmp==false or tokens[bk][1]=="EOF" then ptr=bk break end
				table.insert(res,tmp)
			end
			return res
		end
	end
	local function number()
		return function()
			if tokens[ptr][1]=="number" then ptr=ptr+1 return {"number",tokens[ptr-1][2],line=tokens[ptr-1].line} end
			return false
		end
	end
	local function string()
		return function()
			if tokens[ptr][1]=="string" then ptr=ptr+1 return {"string",tokens[ptr-1][2],line=tokens[ptr-1].line} end
			return false
		end
	end
	local function symbol(x)
		return function()
			if tokens[ptr][1]==x then ptr=ptr+1 return tokens[ptr-1] end
			return false
		end
	end
	local function literal()
		return combinator_or(number(),string())
	end
	local expression,lambda
	function statement()
		return combinator_or(combinator_or(expression(),lambda()),symbol("identifier"))
	end
	expression=function()
		return combinator_or(literal(),function()
			local res={"expression"}
			local tmp=symbol("(")() 
			if not tmp then return false end
			res.line=tmp.line
			res[2]=more_than_one(statement())()
			if not symbol(")")() then return false end
			return res
		end)
	end
	lambda=function()
		return combinator_or(literal(),function()
			local res={"lambda"}
			local tmp=symbol("[")() 
			if not tmp then return false end
			res.line=tmp.line
			res[2]=more_than_one(statement())()
			if not symbol("]")() then return false end
			return res
		end)
	end
	return any_eof(statement())()
end

function interpret(ast,imports)
	local namespace_stack={{}}
	local cline=1
	local function top() return namespace_stack[#namespace_stack] end
	local function instantiate(k,v)
		local t=top()
		t[k]={v}
	end
	local function set(k,v)
		local t=top()
		if not t[k] then
			instantiate(k,v)
		else
			t[k][1]=v
		end
	end
	local function throwerror(reason)
		print("line "..cline..":  "..reason)
		os.exit(1)
	end
	local function get(k)
		local t=top()
		if t[k] then
			return t[k][1]
		end
		throwerror("could not find variable "..k)
	end
	
	local function clone()
		namespace_stack[#namespace_stack+1]=deepclone(top())
	end
	local function discard()
		namespace_stack[#namespace_stack]=nil
	end
	local function to(...)
		local res={}
		local a={...}
		for i,v in ipairs(a) do
			if type(v)=="table" then
				local res2={}
				for i2,v2 in ipairs(v) do
					res2[i2]=to(v2)
				end
				table.insert(res,{type="list",value=res2})
			else
				table.insert(res,{type=({
					["nil"]="nil",
					["string"]="string",
					["number"]="number",
					["boolean"]="bool",
					["table"]="list",
					["function"]="function",
				})[type(v)],value=v})
			end
		end
		return unpack(res)
	end
	local function from(...)
		local res={}
		local a={...}
		for i,v in ipairs(a) do
			if v.type=="list" then
				local res2={}
				for i2,v2 in ipairs(v.value) do
					res2[i2]=from(v2)
				end
				table.insert(res,res2)
			else
				table.insert(res,v.value)
			end
		end
		return unpack(res)
	end
	local raw
	raw={
		["+"]=function(x,y)
			if x and y then
				if x.type=="number" and y.type=="number" then
					return {type="number",value=x.value+y.value}
				end
				if (x.type=="string" and (y.type=="string" or y.type=="number" or y.type=="bool")) or (y.type=="string" and (x.type=="string" or x.type=="number" or x.type=="bool"))  then
					return {type="string",value=x.value..y.value}
				end
			end
			return throwerror("types incompatible: "..(x and x.type or "nil")..", "..(y and y.type or "nil"))
		end,
		["*"]=function(x,y)
			if x and y and x.type=="number" and y.type=="number" then
				return {type="number",value=x.value*y.value}
			end
			throwerror("types incompatible: "..(x and x.type or "nil")..", "..(y and y.type or "nil"))
		end,
		["negate"]=function(x)
			if x and x.type=="number" then
				return {type="number",value=-(x.value)}
			end
			throwerror("types incompatible: "..(args[1] and args[1].type or "nil"))
		end,
		["at"]=function(x,y)
			if x and x.type=="list" and y and (y.type=="number" or y.type=="string") then
				if x.value[y.value] then
					return x.value[y.value]
				end
				throwerror("attempt to get out of bounds index "..y.value)
			end
			if x and x.type=="string" and y and y.type=="number" then
				if #x.value>=(y.value+1) and (y.value+1)>=1 then
					return {type="string",value=x.value:sub(y.value+1,y.value+1)}
				end
				throwerror("attempt to get out of bounds index "..y.value)
			end
			throwerror("types incompatible: "..(x and x.type or "nil")..", "..(y and y.type or "nil"))
		end,
		["keys"]=function(x)
			if x and x.type=="list" then
				local res={type="list",value={}}
				for i,v in pairs(x.value) do
					table.insert(res.value,to(i))
				end
				return res
			end
			throwerror("types incompatible: "..(x and x.type or "nil"))
		end,
		["/"]=function(x,y)
			if x and y and x.type=="number" and y.type=="number" then
				return {type="number",value=x.value/y.value}
			end
			throwerror("types incompatible: "..(x and x.type or nil)..", "..y and y.type or nil)
		end,
		["=="]=function(x,y)
			if x.type~=y.type then return {type="bool",value=false} end
			return {type="bool",value=x.value==y.value}
		end,
		["len"]=function(x)
			if x.type=="list" or x.type=="string" then
				return {type="number",value=#x.value}
			end
		end,
		["seti"]=function(x,y,z)
			if x and x.type=="list" and y and (y.type=="number" or y.type=="string") and z then
				x.value[y.value]=z
			end
			throwerror("types incompatible: "..(x and x.type or "nil")..", "..(y and y.type or "nil")..", "..(z and z.type or "nil"))
		end,
		["if"]=function(x,y,z)
			if x and x.value~=0 and x.value~=false then
				if y and y.type=="function" then
					return y.value()
				end
			else
				if x and z and z.type=="function" then
					return z.value()
				end
			end
			return throwerror("types incompatible: "..(x and x.type or "nil")..", "..(y and y.type or "nil")..", "..(z and z.type or "nil"))
		end,
		["print"]=function(...)
			local tmp={}
			local args={...}
			for i=1,#args do
				if args[i].type=="string" or args[i].type=="number" or args[i].type=="bool" then
					tmp[#tmp+1]=args[i].value
				end
				if args[i].type=="error" then
					tmp[#tmp+1]="error: "..args[i].value
				end
				if args[i].type=="list" then
					tmp[#tmp+1]="(list, length: "..#args[i].value..")"
				end
				if args[i].type=="function" then
					tmp[#tmp+1]="(function)"
				end
			end
			print(unpack(tmp))
			return {type="bool",value=true}
		end,
		["type"]=function(x)
			if x then return {type="string",value=x.type} end
			throwerror("types incompatible: nil")
		end,
		["<"]=function(x,y)
			if x and y and x.type=="number" and y.type=="number" then
				return {type="bool",value=(x.value<y.value)}
			end
			throwerror("types incompatible: "..(x and x.type or nil)..", "..y and y.type or nil)
		end,
		["newvar"]=function(...)
			local args={...}
			if args[1] and args[1].type=="string" then
				if args[3] and args[3].type=="bool" and args[3].value==true then
					local tmp=top()
					discard()
					instantiate(args[1].value,args[2])
					namespace_stack[#namespace_stack+1]=tmp
					instantiate(args[1].value,args[2])
				else
					instantiate(args[1].value,args[2]) 
				end
				return {type="bool",value=true}
			end
			return throwerror("types incompatible: "..(args[1] and args[1].type or "nil"))
		end,
		["var"]=function(...)
			local args={...}
			if args[1] and args[1].type=="string" then set(args[1].value,args[2]) return {type="bool",value=true} end
			return throwerror("types incompatible: "..(args[1] and args[1].type or "nil"))
		end,
		["extern"]=function(x,y)
			if x and x.type=="string" then
				local namespace=""
				if y and y.type=="string" then
					namespace=y.value.."_"
				end
				local f=io.open(x.value,"r")
				if not f then
					return {type="bool",value=false}
				end
				local i=f:read("*a")
				f:close()
				local xp=interpret(into_ast(tokenize(i)),imports).exports
				if xp then
					for k,v in pairs(xp) do
						instantiate(namespace..k,{type="function",value=v})
					end
					return {type="bool",value=true}
				end
			end
			return {type="bool",value=false}
		end,
	}
	for i,v in pairs(raw) do
		set(i,{type="function",value=v})
	end
	for i,v in pairs(imports or {}) do
		set("lua_"..i,{type="function",value=function(...)
			return to(v(from(...)))
		end})
	end
	instantiate("true",{type="bool",value=true})
	instantiate("false",{type="bool",value=false})
	local function exec(node)
		local nodet=node[1]
		cline=node.line
		if nodet=="string" then return {type="string",value=node[2]} end
		if nodet=="number" then return {type="number",value=node[2]} end
		if nodet=="identifier" then
			local r=get(node[2])
			if not r then
				return {type="error",value="not found"}
			else
				return r
			end
		end
		if nodet=="expression" then
			local vl=node[2]
			local to_call=nil
			local list_res={}
			for i,v in ipairs(vl) do
				local evr=exec(v)
				if i==1 and evr.type=="function" then
					to_call=evr
				else
					table.insert(list_res,evr)
				end
			end
			if to_call then
				local m=to_call.value(unpack(list_res))
				--print(m)
				return m
			else
				return {type="list",value=list_res}
			end
		end
		if nodet=="lambda" then
			local vl=node[2]
			local to_call=nil
			local list_res={}
			for i,v in ipairs(vl) do
				table.insert(list_res,v)
			end
			local cscope=top()
			return {type="function",value=function(...)
				local a={...}
				clone()
				for i,v in pairs(cscope) do
					if not namespace_stack[#namespace_stack][i] then namespace_stack[#namespace_stack][i]=v end
				end
				for i=1,#a do
					instantiate("arg"..i,a[i])
				end
				instantiate("argc",#a)
				local retval=nil
				for i,v in ipairs(list_res) do
					retval=exec(v)
				end
				if not retval then
					return throwerror("functions cannot have no return value")
				end
				discard()
				return retval
			end}
		end
		print("oh apio oh "..nodet)
	end
	local rv=nil
	for i=1,#ast do
		rv=exec(ast[i])
	end
	local exports={}
	local lua_exports={throwerror=throwerror}
	if rv and rv.type=="list" then
		if rv.value[1] and rv.value[1].value=="exports" then
			for i=2,#rv.value,2 do
				if rv.value[i] and rv.value[i].type=="string" then
					if rv.value[i+1] and rv.value[i+1].type=="function" then
						exports[rv.value[i].value]=rv.value[i+1].value
						lua_exports[rv.value[i].value]=function(...) return from(rv.value[i+1].value(to(...))) end
					end
				end
			end
		end
	end
	
	return {returned=rv,exports=exports,lua_exports=lua_exports}
end
local function run(x,lua)
	return interpret(into_ast(tokenize(x)),lua)
end
return {run=run}