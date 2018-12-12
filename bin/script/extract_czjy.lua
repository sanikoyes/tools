-- 苍之纪元
local lfs = require "lfs"
local xxtea = require "misc.xxtea"

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

local key = 'yingliboroom'
local decrypt_res = function(path, fa)
	if path:find("%.png$") then
		local ctx = io.open(path, "rb"):read "*all"
		print("Decrypting " .. path)
		ctx = xxtea.decrypt(ctx, key)
		io.open(path, "wb"):write(ctx)
		collectgarbage()
	end
end

traversal_dir("czjy/assets", decrypt_res)

