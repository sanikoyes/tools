-- 妖萌战姬
local z = require "zlib"
local lfs = require "lfs"

local function write_tga(path, width, height, pixels)
	local header = string.pack("BBB<I2<I2B<i2<i2<i2<i2BB",
		0,	-- idlength
		0,	-- colourmaptype
		2,	-- datatypecode
		0,	-- colourmaporigin
		0,	-- colourmaplength
		0,	-- colourmapdepth
		0,	-- x_origin
		0,	-- y_origin
		width,	-- width
		height,	-- height
		32, -- bitsperpixel
		0 -- imagedescriptor
	)
	print(" >> Writing : " .. path)
	local fp = io.open(path, "wb")
	fp:write(header)

	local ps = {}

	for y = height - 1, 0, -1 do
		for x = 0, width - 1 do
			local index = (y * width + x) + 1
			local p = pixels[index]
			fp:write(p)
		end
	end
	fp:close()
end

local function decrypt(path)
	local out_path = path:gsub("%.png", ".tga")
	if io.open(out_path, "rb") ~= nil then
		collectgarbage()
		return
	end

	local fp = assert(io.open(path, "rb"), "Unable to open file : " .. path)
	local data = fp:read "*all"
	fp:close()

	local sig, width, height, pal_mode, has_alpha, offset = string.unpack(">c10HHbb", data)
	if sig ~= "img.libla\0" then
		return false
	end
	pal_mode = pal_mode == 1
	has_alpha = has_alpha == 1

	if pal_mode then
		return
	end
	print(string.format("Reading %s\n\t(Width:%4d, Height:%4d, PalMode:%5s HasAlpha:%5s)", path, width, height, pal_mode, has_alpha))

	local palettes = {}
	if pal_mode then
		local r, g, b
		for _ = 1, 256 do
			r, g, b, offset = string.unpack("c1c1c1", data, offset)
			table.insert(palettes, { r = r, g = g, b = b })
		end
	end

	local bpp = (pal_mode and 1 or 3) + (has_alpha and 1 or 0)
	local remain_bytes = #data - offset
	local buffer_bytes = width * height * bpp

	data = data:sub(offset)
	if remain_bytes < buffer_bytes then
		data = assert(z.uncompress(data, buffer_bytes), "Unable to decompress data")
	end

	local pixels = {}
	local count = width * height
	if pal_mode then
		local alpha_offset = #data >> 1
		for i = 0, count - 1 do
			local index = string.unpack("B", data, i + 1)
			local pal = palettes[index + 1]
			local alpha = has_alpha and string.unpack("c1", data, alpha_offset + i) or string.char(255)
			table.insert(pixels, table.concat {
				pal.b, pal.g, pal.r, alpha
			})
		end
	else
		local r, g, b, a
		local offset = 1
		for i = 0, count - 1 do
			if has_alpha then
				r, g, b, a, offset = string.unpack("c1c1c1c1", data, offset)
			else
				r, g, b, offset = string.unpack("c1c1c1", data, offset)
				a = string.char(255)
			end
			table.insert(pixels, table.concat { b, g, r, a })
		end
	end
	write_tga(out_path, width, height, pixels)
end

-- local t = os.clock()
-- decrypt("ymzj/assets/res/activity/xianshi.png")
-- print((os.clock() - t) * 1000)

local function traversalDir(path, callback)
	for name in lfs.dir(path) do
		if name == "." or name == ".." then
		else
			local fullPath = string.format("%s/%s", path, name)
			local fa = lfs.attributes(fullPath)
			if fa.mode == "directory" then
				traversalDir(fullPath, callback)
			else
				callback(fullPath, fa)
			end
		end
	end
end

traversalDir("ymzj", function(path, fa)
	if path:match("%.png$") then
		decrypt(path)
	end
end)
