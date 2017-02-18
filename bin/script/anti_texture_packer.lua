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

	print("filename is : " .. file_name)
	local path = file_name:gsub("%.[%w%.%d]+$", "")
	print("path is : " .. path)

	local textureFileName = string.format("%s.png", path)
	local bitmap = assert(alleg.bitmap.load(textureFileName), "Unable to load texture: " .. textureFileName)
	local cmd = string.format('mkdir "%s"', path)
	print(cmd)
	os.execute(cmd:gsub("/", "\\"))

	local function parse_size(str)
		local w,h = str:match("(-?%d+),%s?(-?%d+)")
		return {
			w = tonumber(w),
			h = tonumber(h),
		}
	end
	local function parse_pos(str)
		local x,y = str:match("(-?%d+),%s?(-?%d+)")
		return {
			x = tonumber(x),
			y = tonumber(y),
		}
	end
	local function parse_rect(str)
		local x,y,w,h = str:match("{{(-?%d+),%s?(-?%d+)},%s?{(-?%d+),%s?(-?%d+)}}")
		return {
			x = tonumber(x),
			y = tonumber(y),
			w = tonumber(w),
			h = tonumber(h),
		}
	end

	local function parse_info(info)
		local patterns = {
			{
				-- {
				--   "frame": "{{1701,3},{84,84}}",
				--   "offset": "{0,0}",
				--   "rotated": false,
				--   "sourceColorRect": "{{0,0},{84,84}}",
				--   "sourceSize": "{84,84}"
				-- }
				keys = { "frame", "offset", "rotated", "sourceColorRect", "sourceSize" },
				parser = function()
					return {
						frame = parse_rect(info.frame),
						offset = parse_pos(info.offset),
						rotated = info.rotated,
						sourceColorRect = parse_rect(info.sourceColorRect),
						sourceSize = parse_size(info.sourceSize),
					}
				end,
			},
			{
				-- {
				--   "aliases": [],
				--   "spriteColorRect": "{{27, 2}, {65, 93}}",
				--   "spriteOffset": "{13, -1}",
				--   "spriteSize": "{65, 93}",
				--   "spriteSourceSize": "{93, 95}",
				--   "spriteTrimmed": true,
				--   "textureRect": "{{962, 1327}, {93, 65}}",
				--   "textureRotated": true
				-- }
				keys = { "spriteColorRect", "spriteOffset", "spriteSize", "spriteSourceSize", "spriteTrimmed", "textureRect", "textureRotated" },
				parser = function()
					return {
						frame = parse_rect(info.textureRect),
						offset = parse_pos(info.spriteOffset),
						rotated = info.textureRotated,
						sourceColorRect = parse_pos(info.spriteColorRect),
						sourceSize = parse_size(info.spriteSourceSize),
					}
				end,
			},
			{
				-- {
				--   "spriteOffset": "{-1,0}",
				--   "spriteSize": "{45,79}",
				--   "spriteSourceSize": "{49,79}",
				--   "textureRect": "{{525,12},{45,79}}",
				--   "textureRotated": true
				-- }
				keys = { "spriteOffset", "spriteSize", "spriteSourceSize", "textureRect", "textureRotated" },
				parser = function()
					return {
						frame = parse_rect(info.textureRect),
						offset = parse_pos(info.spriteOffset),
						rotated = info.textureRotated,
						sourceColorRect = parse_pos(info.spriteOffset),
						sourceSize = parse_size(info.spriteSourceSize),
					}
				end,
			},
		}

		for _,p in pairs(patterns) do
			local match = true
			for _,k in pairs(p.keys) do
				if info[k] == nil then
					match = false
					break
				end
			end
			if match then
				-- print(json.encode(info))
				-- print("Match: " .. json.encode(p.keys))
				return p.parser()
			end
		end
	end

	for key,info in pairs(data.frames) do
		-- if key == "ih_a_coinshower_06.png" then
		-- print(json.encode(info))
		local data = parse_info(info)
		-- print(json.encode(data))
		-- assert(data ~= nil)

		local frame = assert(data.frame)
		local offset = data.offset or { x = 0, y = 0, }
		local rotated = data.rotated
		local sourceColorRect = assert(data.sourceColorRect)
		local sourceSize = assert(data.sourceSize)

		-- 	local x = (sourceSize.w - frame.w) / 2
		-- 	local y = (sourceSize.h - frame.h) / 2
		-- local x = offset.x
		-- local y = offset.y
		-- sourceColorRect.x = sourceColorRect.x - x
		-- sourceColorRect.y = sourceColorRect.y - y

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
			alleg.bitmap.draw_rotated(sub,
				0,
				0,
				sourceColorRect.x,
				sourceColorRect.y,
				0,
				0
			)
		end
		key = key:gsub("%.gif$", ".png")
		local writeDir = path .. "/" .. key
		print("Save to: " .. writeDir)
		if not target:save(writeDir) then
			local subpath = path
			for sub in key:gmatch("([%w%.%d_]+)/") do
				subpath = subpath .. "/" .. sub
				print("Sub directory: " .. path)
				local cmd = string.format('mkdir "%s"', subpath)
				print(cmd)
				os.execute(cmd:gsub("/", "\\"))
				assert(target:save(writeDir), "Unable to save " .. writeDir)
			end
		end
		-- end
	end
	-- print(json.encode(data))
	-- os.execute("del " .. file_name:gsub("/", "\\"))
	-- os.execute("del " .. textureFileName:gsub("/", "\\"))
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

local dir = "mxywk"
traversalDir(dir, function(path, fa)
	if path:match("%.plist$") then
		print("Export texture packer plist: " .. path)
		export(path)
	end
end)

-- local dir = "xjdw/g/brnn/card_show"
-- for name in lfs.dir(dir) do
-- 	if name:match("%.plist$") then
-- 	-- if name:match("fd_t_selector%-hd.plist$") then
-- 		local fn = string.format("%s/%s", dir, name)
-- 		print("Export texture packer plist: " .. fn)
-- 		export(fn)
-- 		-- os.exit()
-- 	end
-- end
-- export("ui_function_enchantment.plist")
-- export("backroom.plist")
