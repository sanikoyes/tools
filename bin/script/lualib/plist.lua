-- See http://xmlsoft.org/xmlreader.html for more examples
local xmlreader = require "xmlreader"
local json = require "lualib.json"

local function load_plist(text)
    local r = assert(xmlreader.from_string(text))

    local function next_tag()
        while r:read() do
            if r:node_type() == "element" then
                return r:name()
            elseif r:node_type() == "end element" then
                return "end"
            end
        end
    end

    local function next_text(tag)
        local result
        while r:read() do
            if r:node_type() == "element" then
                if r:name() ~= tag then
                    break
                end
            elseif r:node_type() == "text" then
                result = r:value()
            elseif r:node_type() == "end element" then
                break
            end
        end
        return result
    end

    local function next_value()
        local tag = next_tag()
        if tag == "end" then
            return
        end

        local loaders = {
            ["plist"] = function()
                return next_value()
            end,
            ["dict"] = function()
                local dict = {}
                while true do
                    local key = next_text("key")
                    if key == nil then
                        break
                    end
                    local value = next_value()
                    dict[key] = value
                end
                return dict
            end,
            ["array"] = function()
                local array = {}
                while true do
                    local value = next_value()
                    if value == nil then
                        break
                    end
                    table.insert(array, value)
                end
                return array
            end,
            ["string"] = function()
                return next_text("string")
            end,
            ["integer"] = function()
                return tonumber(next_text("integer"))
            end,
            ["true"] = function()
                return true
            end,
            ["false"] = function()
                return false
            end,
        }
        local f = assert(loaders[tag], "unknown tag: " .. tag)
        return f()
    end

    local result = next_value()
    r:close()
    return result
end

return {
    decode = load_plist
}
