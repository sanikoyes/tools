local lfs = require "lfs"
local alleg = require "liballua"
local json = require "lualib.json"
local plist = require "lualib.plist"

alleg.init()
alleg.bitmap.init_image_addon()

-- for k,v in pairs(alleg.display) do print(k,v) end
-- ALLEGRO_MEMORY_BITMAP
alleg.bitmap.set_new_flags(1)
-- ALLEGRO_PIXEL_FORMAT_RGBA_8888
alleg.bitmap.set_new_format(10)

local function export(file_name)
	local fp = assert(io.open(file_name, "rb"), "Unable to open file: " .. file_name)
	local ret, data = pcall(plist.decode, fp:read "*all")
	if not ret then
		print(data)
		return
	end
	fp:close()
	if not data.metadata then
		return
	end

	local path = file_name:gsub("%.%w+", "")

	local textureFileName = string.format("%s.png", path)
	local bitmap = assert(alleg.bitmap.load(textureFileName), "Unable to load texture: " .. textureFileName)
	local cmd = "mkdir " .. path
	print(cmd)
	os.execute(cmd:gsub("/", "\\"))

	local function parse_size(str)
		local w,h = str:match("(-?%d+),(-?%d+)")
		return {
			w = tonumber(w),
			h = tonumber(h),
		}
	end
	local function parse_pos(str)
		local x,y = str:match("(-?%d+),(-?%d+)")
		return {
			x = tonumber(x),
			y = tonumber(y),
		}
	end
	local function parse_rect(str)
		local x,y,w,h = str:match("{{(-?%d+),(-?%d+)},{(-?%d+),(-?%d+)}}")
		return {
			x = tonumber(x),
			y = tonumber(y),
			w = tonumber(w),
			h = tonumber(h),
		}
	end

	for key,info in pairs(data.frames) do
		local frame = parse_rect(info.frame or info.textureRect)
		-- local offset = parse_pos(info.offset)
		local rotated = (info.rotated ~= nil) and info.rotated or info.textureRotated
		local sourceColorRect = info.sourceColorRect and parse_rect(info.sourceColorRect) or parse_pos(info.spriteOffset)
		local sourceSize = parse_size(info.sourceSize or info.spriteSourceSize)

		if info.spriteOffset then
			local x = (sourceSize.w - frame.w) / 2
			local y = (sourceSize.h - frame.h) / 2
			sourceColorRect.x = x + sourceColorRect.x
			sourceColorRect.y = y + sourceColorRect.y
		end

		if rotated then
			local w = frame.w
			frame.w = frame.h
			frame.h = w
		end

		local sub = bitmap:create_sub(frame.x, frame.y, frame.w, frame.h)
		local target = alleg.bitmap.create(sourceSize.w, sourceSize.h)
		target:set_target()
		alleg.bitmap.clear_to_color(alleg.color.map_rgba_f(0, 0, 0, 0))
		if rotated then
			-- sourceSize.w - frame.w
			alleg.bitmap.draw_rotated(sub,
				-- sx sy dx dy
				0,
				0,
				sourceColorRect.x,
				sourceSize.h - sourceColorRect.y,
				-3.14 / 2,
				0
			)
		else
			alleg.bitmap.draw_rotated(sub, 0, 0, sourceColorRect.x, sourceColorRect.y, 0, 0)
		end
		local writeDir = path .. "/" .. key
		print("Save to: " .. writeDir)
		target:save(writeDir)
	end
	-- print(json.encode(data))
	os.execute("del " .. file_name:gsub("/", "\\"))
	os.execute("del " .. textureFileName:gsub("/", "\\"))
end

local dir = "assets/ResourcesCN"
for name in lfs.dir(dir) do
	if name:match("%.plist$") then
		local fn = string.format("%s/%s", dir, name)
		print("Export texture packer plist: " .. fn)
		export(fn)
		-- os.exit()
	end
end
-- export("ui_function_enchantment.plist")
-- export("backroom.plist")
