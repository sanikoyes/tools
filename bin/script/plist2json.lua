-- See http://xmlsoft.org/xmlreader.html for more examples
local xmlreader = require "xmlreader"
local json = require "lualib.json"

local function load_plist(path)
    local fp = assert(io.open(path, "rb"), "unable to open file: " .. path)
    local r = assert(xmlreader.from_string(fp:read "*all"))
    fp:close()

    -- <!DOCTYPE plist>
    assert(r:read())
    -- <plist version="1.0">
    assert(r:read())
    assert(r:node_type() == "element")
    assert(r:name() == "plist")

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
        local loaders = {
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
        -- if tag == "dict" then
        --     local dict = {}
        --     while true do
        --         local key = next_text("key")
        --         if key == nil then
        --             break
        --         end
        --         local value = next_value()
        --         dict[key] = value
        --     end
        --     return dict
        -- elseif tag == "string" then
        --     return next_text("string")
        -- elseif tag == "integer" then
        --     return tonumber(next_text("integer"))
        -- elseif tag == "true" then
        --     return true
        -- elseif tag == "false" then
        --     return false
        -- else
        --     assert(false, "unknow tag: " .. tag)
        -- end
    end

    local result = next_value()
    r:close()
    return result
end

local data = load_plist("ui_function_enchantment.plist")
print(json.encode(data))
