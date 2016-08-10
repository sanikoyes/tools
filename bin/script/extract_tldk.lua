-- 贪婪洞窟资源解密脚本
local ccz = require "misc.ccz"
local lfs = require "lfs"

ccz.set_key(
	-- 0x008A10BC,
	-- 0x253EC10B,
	-- 0xD21B5FAB,
	-- 0x941ABBF9
	table.unpack {
		0xC421EAFA,
		0x7F32253D,
		0xD6CA0A19,
		0x6D8AAE6,
	}
)

-- .text:007A8A1C                 LDR             R0, =0x8A10BC
-- .text:007A8A20                 LDR             R1, =0x253EC10B
-- .text:007A8A24                 LDR             R2, =0xD21B5FAB
-- .text:007A8A28                 LDR             R3, =0x941ABBF9


-- .text:002542BA                 LDR             R2, =0xD6CA0A19
-- .text:002542BC                 LDR             R1, =0x7F32253D
-- .text:002542BE                 LDR             R3, =0x6D8AAE6
-- .text:002542C0                 LDR             R0, =0xC421EAFA


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

local dir = "pxzg"
for name in lfs.dir(dir) do
	if name:find(".ccz$") then
		name = dir .. "/" .. name
		print("Decrypting file: " .. name)
		decrypt(name)
	end
end
