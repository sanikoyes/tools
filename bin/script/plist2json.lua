-- See http://xmlsoft.org/xmlreader.html for more examples

local plist = require "lualib.plist"
local json = require "lualib.json"

local text = io.open("ui_function_enchantment.plist", "rb"):read("*all")
collectgarbage()
local data = plist.decode(text)
print(json.encode(data))
