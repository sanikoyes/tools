local lfs = require "lfs"
local alleg = require "liballua"
local json = require "lualib.json"
local amf3 = require "amf3"

alleg.init()
alleg.bitmap.init_image_addon()

-- for k,v in pairs(alleg.display) do print(k,v) end
-- ALLEGRO_MEMORY_BITMAP
alleg.bitmap.set_new_flags(1)
-- ALLEGRO_PIXEL_FORMAT_RGBA_8888
alleg.bitmap.set_new_format(10)

local function export(file_name)
	local fp = assert(io.open(file_name, "rb"), "Unable to open file: " .. file_name)
	local vo = amf3.decode(fp:read "*all")
	fp:close()

	if not vo.list then
		return
	end

	-- width	57
	-- name	Ant10001
	-- hx	1.#QNAN
	-- hy	1.#QNAN
	-- fx	-52
	-- height	56
	-- fw	177
	-- fh	174
	-- _class	ekkorr.starling.texture.SheetVO
	-- x	351
	-- y	2
	-- fy	-60

	local path = file_name:gsub("%.%w+", "")

	local textureFileName = string.format("%s.png", path)
	local bitmap = alleg.bitmap.load(textureFileName)
	if bitmap == nil then
		print("Unable to load texture: " .. textureFileName)
		return
	end
	local cmd = "mkdir " .. path
	print(cmd)
	os.execute(cmd:gsub("/", "\\"))

	for _,info in pairs(vo.list) do
		if info.fw == 0 or info.fh == 0 then
			info.fw = info.width
			info.fh = info.height
		end

		local sub = bitmap:create_sub(info.x, info.y, info.width, info.height)
		local target = alleg.bitmap.create(info.fw, info.fh)
		target:set_target()
		alleg.bitmap.clear_to_color(alleg.color.map_rgba_f(0, 0, 0, 0))

		alleg.bitmap.draw_rotated(sub, 0, 0, -info.fx, -info.fy, 0, 0)

		local writeDir = path .. "/" .. info.name .. ".png"
		print("Save to: " .. writeDir)

		target:save(writeDir)
	end
-- 	os.execute("del " .. file_name:gsub("/", "\\"))
-- 	os.execute("del " .. textureFileName:gsub("/", "\\"))
	collectgarbage()
end

local dir = "endlessfrontier/binary"
for name in lfs.dir(dir) do
	if name:match("%.vo$") then
		local fn = string.format("%s/%s", dir, name)
		print("Export endless-frontier vo spritesheet: " .. fn)
		export(fn)
		os.exit()
	end
end

-- export("endlessfrontier/binary/UI2.vo")
