-- 冒险与挖矿
local lfs = require "lfs"
local xxtea = require "misc.xxtea"
local zlib = require "zlib"

-- 遍历路径
local function traversal_dir(path, callback)
	for name in lfs.dir(path) do
		local full_path = string.format("%s/%s", path, name)
		local fa = lfs.attributes(full_path)
		if name == "." or name == ".." then
		else
			callback(full_path, fa)
			if fa.mode == "directory" then
				traversal_dir(full_path, callback)
			end
		end
	end
end

local sign = "NzdtbWFh"
local key = "ZW5pbS12ZGE"

local decrypt_script = function(path, fa)
	if path:find("%.lua$") or path:find("%.csv$") then
		local ctx = io.open(path, "rb"):read "*all"
		if ctx:find(sign) == 1 then
			print("Decrypting " .. path)

			ctx = ctx:sub(#sign + 1)
			ctx = xxtea.decrypt(ctx, key)

			if #ctx > 0 then
				print(path, #ctx)
				io.open(path, "wb"):write(ctx)
			end
		elseif path:find("%.csv$") then
			ctx = xxtea.decrypt(ctx, key)
			if #ctx > 0 then
				print(path, #ctx)
				io.open(path, "wb"):write(ctx)
			end
		end
		collectgarbage()
	end
end

traversal_dir("mxywk", decrypt_script)

