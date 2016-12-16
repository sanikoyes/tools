-- 不思议迷宫
local lfs = require "lfs"

local key = table.concat {
	"// Dump Ref object memory leaks if (__refAllocationList.empty())",
	" { log([memory] All Ref objects successfully cleaned up (no leak",
	"s detected).\n",
	"); } else { log([memory] WARNING: %d Ref objects still active in",
	" memory.\n",
	", (int)__refAllocationList.size()); for (const auto& ref : __ref",
	"AllocationList) { CC_ASSERT(ref); const char* type = typeid(*ref",
	").name(); log([memory] LEAK: Ref object %s still active with ref",
	"erence count %d.\n",
	", (type ? type : ), ref->getReferenceCount()); }}",
}
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

traversal_dir("../..", function(path, fa)
	if path:find("%.png$") then

		local ctx = io.open(path, "rb"):read "*all"
		ctx = xor_decrypt(ctx)
		if ctx ~= nil then
			print("Writing " .. path)
			io.open(path, "wb"):write(ctx)
		end
		collectgarbage()
	end
end)
