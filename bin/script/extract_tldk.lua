-- 贪婪洞窟资源解密脚本
local ccz = require "misc.ccz"
local lfs = require "lfs"

ccz.set_key(
	0x008A10BC,
	0x253EC10B,
	0xD21B5FAB,
	0x941ABBF9
)

local function decrypt(file)
	local fp = assert(io.open(file, "rb"), "Unable to read file: " .. file)
	local data = fp:read "*all"
	fp:close()
	data = ccz.decompress(data)
	file = file:gsub("%.ccz$", "")
	fp = assert(io.open(file, "wb"), "Unable to write file: " .. file)
	fp:write(data)
	fp:close()
end

for name in lfs.dir("assets") do
	if name:find(".ccz$") then
		name = "assets/" .. name
		print("Decrypting file: " .. name)
		decrypt(name)
	end
end
