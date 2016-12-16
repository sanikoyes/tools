-- 贪婪洞窟资源解密脚本
local ccz = require "misc.ccz"
local lfs = require "lfs"

ccz.set_key(
	-- -- 贪婪洞窟
	-- table.unpack {
	-- 0x008A10BC,
	-- 0x253EC10B,
	-- 0xD21B5FAB,
	-- 0x941ABBF9,
	-- }

	-- table.unpack {
	-- 	0xC421EAFA,
	-- 	0x7F32253D,
	-- 	0xD6CA0A19,
	-- 	0x6D8AAE6,
	-- }

	-- 星众棋牌
	-- table.unpack {
	-- 	0x11111111,
	-- 	0x22222222,
	-- 	0x33333333,
	-- 	0x44444444,
	-- }

	-- slots
	table.unpack {
		0xABCDABCD,
		0xABCDABCD,
		0xABCDABCD,
		0xABCDABCD,
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
	local r, data = pcall(ccz.decompress, data)
	if not r then
		print(" >> " .. data)
		return
	end
	file = file:gsub("%.ccz$", "")
	fp = assert(io.open(file, "wb"), "Unable to write file: " .. file)
	fp:write(data)
	fp:close()
end

local function traversalDir(path, callback)
	for name in lfs.dir(path) do
		if name == "." or name == ".." then
		else
			local full = string.format("%s/%s", path, name)
			local fa = lfs.attributes(full)
			if fa.mode == "directory" then
				traversalDir(full, callback)
			else
				callback(full, fa)
			end
		end
	end
end

local dir = "Slot Machine/assets"
traversalDir(dir, function(path, fa)
	if path:find(".ccz$") then
		-- path = dir .. "/" .. path
		print("Decrypting file: " .. path)
		decrypt(path)
	end
end)
