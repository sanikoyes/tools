local tscn = require "script.lualib.tscn"
local utils = require "script.lualib.utils"

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


return {
    parse_gdscene = parse_gdscene,
}
