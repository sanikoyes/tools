local tscn = require "script.lualib.tscn"
local utils = require "script.lualib.utils"
local matrix32 = require "script.lualib.matrix32"

--------------------------------------------------------------------------------
-- 解析tscn gdscene数据
--------------------------------------------------------------------------------
local function parse_gdscene(text)
    -- local fp = io.open(path, "rb")
    -- local text = fp:read "*all"
    -- fp:close()

    local scene = {
        sub_resources = {},
        ext_resources = {},
        nodes = {},
        root = nil,
    }

    local mt = {}
    function mt:get_children()
        local index = 1
        return function(_, k)
            if k then
                index = index + 1
            end
            local name = self.children[index]
            return scene.nodes[name]
        end
    end

    function mt:get_pos()
        local pos = self:get_property("transform/pos")
        if pos then
            local x,y = table.unpack(pos.props)
            return { x = x, y = y }
        else
            return { x = 0, y = 0 }
        end
    end

    function mt:get_scale()
        local scale = self:get_property("transform/scale")
        if scale then
            local x,y = table.unpack(scale.props)
            return { x = x, y = y }
        else
            return { x = 1, y = 1 }
        end
    end

    function mt:get_rot()
        return self:get_property("transform/rot") or 0
    end

    function mt:get_property(name)
        local prop = self[name]
        if type(prop) == "table" then
            if prop.type == "SubResource" then
                local id = prop.props[1]
                return setmetatable(scene.sub_resources[id], { __index = mt })
            end
        end
        return prop
    end

    function mt:get_transform()
        local pos = self:get_pos()
        local scale = self:get_scale()
        local rot = self:get_rot()
        -- print(self.type, string.format("pos(%f,%f) scale(%f,%f) rot(%f)", pos.x, pos.y, scale.x, scale.y, rot))

        return matrix32.new(
            pos,
            scale,
            math.rad(rot)
        )
    end

    local parse_prims, parse_tags, get_prim
    parse_prims = {
        dict = function(v)
            local dict = {}
            for k,v in pairs(v) do
                k = get_prim(k)
                v = get_prim(v)
                dict[k] = v
            end
            return dict
        end,
        object = function(v)
            for i,prop in pairs(v.props) do
                v.props[i] = get_prim(prop)
            end
            return v
        end,
        boolean = function(v) return v end,
        int = function(v) return v end,
        float = function(v) return v end,
        string = function(v) return v end,
    }
    get_prim = function(v)
        local f = assert(parse_prims[v.type], "Unknown prim type: " .. v.type)
        return f(v.value)
    end

    parse_tags = {
        gd_scene = function(attrs, props)
            for _,attr in pairs(attrs) do
                scene[attr.attr] = get_prim(attr.value)
            end
        end,
        sub_resource = function(attrs, props)
            local res = {}
            for _,attr in pairs(attrs) do
                res[attr.attr] = get_prim(attr.value)
            end
            for k,v in pairs(props) do
                res[k] = get_prim(v)
            end
            scene.sub_resources[res.id] = res
        end,
        node = function(attrs, props)
            local node = {
                children = {},
            }
            setmetatable(node, { __index = mt })

            for _,attr in pairs(attrs) do
                node[attr.attr] = get_prim(attr.value)
            end
            for k,v in pairs(props) do
                node[k] = get_prim(v)
            end
            if node.parent then
                local parent = assert(scene.nodes[node.parent], "Invalid parent path: " .. node.parent)
                node.path = (parent.path == "." and "" or (parent.path .. "/")) .. node.name
                table.insert(parent.children, node.path)
            else
                assert(scene.root == nil, "duplicate root node!")
                scene.root = node
                node.path = node.path or "."
            end
            scene.nodes[node.path] = node
            return node
        end,
    }

    local o = tscn.parse(text)
    for _,info in pairs(o) do
        local type = info.type
        local props = info.props

        local f = assert(parse_tags[type.type], "Unknown tag type: " .. type.type)
        f(type.attrs, info.props)
    end
    return scene
end

--------------------------------------------------------------------------------
-- 将table打包成godot的binary数据
--------------------------------------------------------------------------------
local Type = {
    NIL = 0,
    -- atomic types
    BOOL = 1,
    INT = 2,
    REAL = 3,
    STRING = 4,
    -- math types
    VECTOR2 = 5,
    RECT2 = 6,
    VECTOR3 = 7,
    MATRIX32 = 8,
    PLANE = 9,
    QUAT = 10,
    AABB = 11,
    MATRIX3 = 12,
    TRANSFORM = 13,
    -- misc types
    COLOR = 14,
    IMAGE = 15,
    NODE_PATH = 16,
    _RID = 17,
    OBJECT = 18,
    INPUT_EVENT = 19,
    DICTIONARY = 20,
    ARRAY = 21,
    -- arrays
    RAW_ARRAY = 22,
    INT_ARRAY = 23,
    REAL_ARRAY = 24,
    STRING_ARRAY = 25,
    VECTOR2_ARRAY = 26,
    VECTOR3_ARRAY = 27,
    COLOR_ARRAY = 28,
    VARIANT_MAX = 29,
}

local function encode_variant(v)
    local num_keys = 0
    local function var2type(v)
        local t = type(v)
        if t == "table" then
            local i = 1
            local is_array = true
            for k,_ in pairs(v) do
                if k ~= i then
                    is_array = false
                end
                i = i + 1
                num_keys = num_keys + 1
            end
            if not is_array then
                if num_keys == 2 then
                    if v.x and v.y then
                        return Type.VECTOR2
                    end
                end
            end
            return is_array and Type.ARRAY or Type.DICTIONARY
        elseif t == "boolean" then
            return Type.BOOL
        elseif t == "number" then
            if math.ceil(v) == v then
                return Type.INT
            else
                return Type.REAL
            end
        elseif t == "string" then
            return Type.STRING
        else
            error("Unsupported type: " .. t)
        end
    end

    local function encode_uint16(v)
        return string.pack(v < 0 and "<i2" or "<I2", v)
    end

    local function encode_uint32(v)
        return string.pack(v < 0 and "<i4" or "<I4", v)
    end

    local function encode_uint64(v)
        return string.pack(v < 0 and "<i4" or "<I8", v)
    end

    local function encode_float(v)
        return string.pack("<f", v)
    end

    local function encode_double(v)
        return string.pack("<d", v)
    end

    local function encode_cstring(v)
        return string.pack("z", v)
    end

    local function encode_string(v)
        local s = string.pack("<s4", v)
        -- pad
        while (#s % 4) ~= 0 do
            s = s .. '\0'
        end
        return s
    end

    local buf = ""
    local t = var2type(v)
    buf = buf .. encode_uint32(t)

    if t == Type.NIL then
    elseif t == Type.BOOL then
        buf = buf .. encode_uint32(v and 1 or 0)
    elseif t == Type.INT then
        buf = buf .. encode_uint32(v)
    elseif t == Type.REAL then
        buf = buf .. encode_double(v)
    elseif t == Type.STRING then
        buf = buf .. encode_string(v)
    elseif t == Type.VECTOR2 then
        buf = buf 
            .. encode_float(v.x)
            .. encode_float(v.y)
    elseif t == Type.DICTIONARY then
        local tokens = {}
        table.insert(tokens, encode_uint32(num_keys | 0x80000000))
        for k,v in pairs(v) do
            table.insert(tokens, encode_variant(k))
            table.insert(tokens, encode_variant(v))
        end
        buf = buf .. table.concat(tokens)
    elseif t == Type.ARRAY then
        local tokens = {}
        table.insert(tokens, encode_uint32(num_keys | 0x80000000))
        for _,v in pairs(v) do
            table.insert(tokens, encode_variant(v))
        end
        buf = buf .. table.concat(tokens)
    end
    return buf
end

return {
    parse_gdscene = parse_gdscene,
    encode_variant = encode_variant,
}
