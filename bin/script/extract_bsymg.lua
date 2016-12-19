-- 不思议迷宫
local lfs = require "lfs"
local xxtea = require "misc.xxtea"

local key = [[// Dump Ref object memory leaks if (__refAllocationList.empty()) { log([memory] All Ref objects successfully cleaned up (no leaks detected).
); } else { log([memory] WARNING: %d Ref objects still active in memory.
, (int)__refAllocationList.size()); for (const auto& ref : __refAllocationList) { CC_ASSERT(ref); const char* type = typeid(*ref).name(); log([memory] LEAK: Ref object %s still active with reference count %d.
, (type ? type : ), ref->getReferenceCount()); }}]]

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

local function xor_decrypt(ctx)
	if ctx:find("\x89PNG") == 1 then
		return
	end
	local tokens = {}
	local n = (#ctx > 200) and 200 or #ctx
	for i = 1, n do
		local xor = string.byte(key, ((i - 1) % #key) + 1)
		local src = string.byte(ctx, i)
		local dst = xor ~ src
		table.insert(tokens, string.char(dst))
	end
	table.insert(tokens, string.sub(ctx, n + 1))
	return table.concat(tokens)
end

local function decrypt_res(path, fa)
	if path:find("%.png$") then

		local ctx = io.open(path, "rb"):read "*all"
		ctx = xor_decrypt(ctx)
		if ctx ~= nil then
			print("Writing " .. path)
			io.open(path, "wb"):write(ctx)
		end
		collectgarbage()
	end
end

traversal_dir("bsymg/assets/res", decrypt_res)
traversal_dir("bsymg/assets/update_res/res", decrypt_res)

local sign = "applicationWillEnterForeground"
local key = "applicationDidEnterBackground"

local decrypt_script = function(path, fa)
	if path:find("%.luac$") then
		local ctx = io.open(path, "rb"):read "*all"
		if ctx:find(sign) == 1 then
			print("Decrypting " .. path)

			ctx = ctx:sub(#sign + 1)
			ctx = xxtea.decrypt(ctx, key)

			io.open(path, "wb"):write(ctx)

			collectgarbage()
		end
	end
end

traversal_dir("bsymg/assets/src", decrypt_script)
traversal_dir("bsymg/assets/update_res/src", decrypt_script)
