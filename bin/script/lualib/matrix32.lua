local meta = {}

function meta:get_element(x, y)
	local elements = self.elements
	local v = elements[x + 1]
	if y == nil then
		return v
	end
	return v[(y == 0) and "x" or "y"]
end

function meta:set_element(x, y, v)
	if type(y) == "table" then
		self.elements[x + 1] = y
	else
		self.elements[x + 1][(y == 0) and "x" or "y"] = v
	end
end

function meta:tdotx(v)
 -- const { return elements[0][0] * v.x + elements[1][0] * v.y; }
 	-- print("tdotx", self:get_element(0, 0), self:get_element(1, 0))
	return self:get_element(0, 0) * v.x + self:get_element(1, 0) * v.y
end

function meta:tdoty(v)
	-- const { return elements[0][1] * v.x + elements[1][1] * v.y; }
 	-- print("tdoty", self:get_element(0, 1), self:get_element(1, 1))
	return self:get_element(0, 1) * v.x + self:get_element(1, 1) * v.y
end

function meta:xform(v)
	-- return Vector2(
	-- 	tdotx(v),
	-- 	tdoty(v)
	-- ) + elements[2];
	local dot = self:basis_xform(v)
	local pos = self:get_element(2)
	return {
		x = dot.x + pos.x,
		y = dot.y + pos.y,
	}
end

function meta:basis_xform(v)
	-- return Vector2(
	-- 	tdotx(v),
	-- 	tdoty(v)
	-- );
	return {
		x = self:tdotx(v),
		y = self:tdoty(v),
	}
end

function meta:translate(translation)
	-- elements[2]+=basis_xform(p_translation);
	local pos = self:get_element(2)
	local v = self:basis_xform(translation)
	pos.x = pos.x + v.x
	pos.y = pos.y + v.y
end

function meta:scale(scale)
	-- elements[0]*=p_scale;
	-- elements[1]*=p_scale;
	-- elements[2]*=p_scale;
	local elements = self.elements
	elements[1].x = elements[1].x * scale.x
	elements[1].y = elements[1].y * scale.y
	elements[2].x = elements[2].x * scale.x
	elements[2].y = elements[2].y * scale.y
	elements[3].x = elements[3].x * scale.x
	elements[3].y = elements[3].y * scale.y
end

function meta:set_rotation(rot)
	-- real_t cr = Math::cos(p_rot);
	-- real_t sr = Math::sin(p_rot);
	-- elements[0][0]=cr;
	-- elements[1][1]=cr;
	-- elements[0][1]=-sr;
	-- elements[1][0]=sr;
	local cr = math.cos(rot)
	local sr = math.sin(rot)
	self:set_element(0, 0, cr)
	self:set_element(1, 1, cr)
	self:set_element(0, 1, -sr)
	self:set_element(1, 0, sr)
end

function meta:set_rotation_and_scale(rot, scale)
	-- elements[0][0]=Math::cos(p_rot)*p_scale.x;
	-- elements[1][1]=Math::cos(p_rot)*p_scale.y;
	-- elements[0][1]=-Math::sin(p_rot)*p_scale.x;
	-- elements[1][0]=Math::sin(p_rot)*p_scale.y;
	self:set_element(0, 0, math.cos(rot) * scale.x)
	self:set_element(1, 1, math.cos(rot) * scale.y)
	self:set_element(0, 1, -math.sin(rot) * scale.x)
	self:set_element(1, 0, math.sin(rot) * scale.y)
end

local function new(pos, scale, rot)
	local elements = {
		{ x = 1, y = 0 },
		{ x = 0, y = 1 },
		{ x = 0, y = 0 },
	}
	local mat = {
		elements = elements,
	}
	setmetatable(mat, { __index = meta })

	mat:set_rotation(rot)
	mat:set_rotation_and_scale(rot, scale)
	mat:set_element(2, pos)

	return mat
end

return {
	new = new,
}

-- local mat = matrix32.new(
-- 	{ x = 0, y = 0 },
-- 	{ x = -1, y = -1 },
-- 	math.rad(0)
-- )

-- local pos = mat:basis_xform { x = 100, y = 100 }
-- print(pos.x, pos.y)
-- os.exit()
