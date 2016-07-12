-- 以可读方式输出lua值（string/number/table等）
local dump = function(obj)
    local getIndent, quoteStr, wrapKey, wrapVal, dumpObj
    getIndent = function(level)
        return string.rep("\t", level)
    end
    quoteStr = function(str)
        str = str:gsub("\n", "\\n")
        str = str:gsub("\\", "\\\\")
        return '"' .. string.gsub(str, '"', '\\"') .. '"'
    end
    wrapKey = function(val)
        if type(val) == "number" then
            return "[" .. val .. "]"
        elseif type(val) == "string" then
            return "[" .. quoteStr(val) .. "]"
        else
            return "[" .. tostring(val) .. "]"
        end
    end
    wrapVal = function(val, level)
        if type(val) == "table" then
            return dumpObj(val, level)
        elseif type(val) == "number" then
            return tostring(val):gsub("%p+0$", "")
        elseif type(val) == "string" then
            return quoteStr(val)
        else
            return tostring(val)
        end
    end
    dumpObj = function(obj, level)
        if type(obj) ~= "table" then
            return wrapVal(obj)
        end
        local keys = {}
        for k,v in pairs(obj) do
            table.insert(keys, k)
        end
        table.sort(keys, function(left, right)
            if type(left) == type(right) then
              return left < right
            else
              return tostring(left) < tostring(right)
            end
        end)
        level = level + 1
        local tokens = {}
        tokens[#tokens + 1] = "{"
        for _, k in pairs(keys) do
            local v = obj[k]
            tokens[#tokens + 1] = getIndent(level) .. wrapKey(k) .. " = " .. wrapVal(v, level) .. ","
        end
        tokens[#tokens + 1] = getIndent(level - 1) .. "}"
        return table.concat(tokens, "\n")
    end
    return dumpObj(obj, 0)
end


return {
	dump = dump,
}
