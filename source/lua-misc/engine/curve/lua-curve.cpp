#include "lua.hpp"
#include "curve_2d.h"

#define CURVE2D_STRING "curve_2d"

static int luaL_typerror(lua_State *L, int index, const char *type) {

   luaL_error(L, "invalid argument %d type '%s' need type '%s'", lua_typename(L, lua_type(L, index)), index, type);
   return 0;
}

static bool luaL_optboolean(lua_State *L, int index, bool def) {

	if(lua_isboolean(L, index))
		return lua_toboolean(L, index) != 0;
	return def;
}

static Curve2D *luaL_tocurve2d(lua_State *L, int index) {

	Curve2D **obj = (Curve2D **) lua_touserdata(L, index);
	return (obj != NULL) ? *obj : NULL;
}

static Curve2D *luaL_checkcurve2d(lua_State *L, int index) {

	Curve2D **obj;
	luaL_checktype(L, index, LUA_TUSERDATA);
	obj = (Curve2D **) luaL_checkudata(L, index, CURVE2D_STRING);
	if(obj == NULL)
		luaL_typerror(L, index, CURVE2D_STRING);
	if(*obj == NULL)
		luaL_error(L, "null Curve2D");
	return *obj;
}

static Curve2D **luaL_pushcurve2d(lua_State *L, Curve2D *curve) {

	if(curve == NULL) {
		lua_pushnil(L);
		return NULL;
	}
	Curve2D **obj = (Curve2D **) lua_newuserdata(L, sizeof(Curve2D **));
	*obj = curve;
	luaL_getmetatable(L, CURVE2D_STRING);
	lua_setmetatable(L, -2);
	return obj;
}

static int l_new(lua_State *L) {

	Curve2D *curve = new Curve2D;
	luaL_pushcurve2d(L, curve);
	return 1;
}

static const luaL_Reg funcs[] = {
	{ "new", l_new },
	{ NULL, NULL },
};

static int l_get_point_count(lua_State *L) {

	Curve2D *curve = luaL_checkcurve2d(L, 1);
	lua_pushinteger(L, curve->get_point_count());
	return 1;
}

static Vector2 luaL_checkvector2(lua_State *L, int index) {

	luaL_checktype(L, index, LUA_TTABLE);
	lua_pushvalue(L, index);
	Vector2 vec;

	lua_getfield(L, -1, "x");
	vec.x = luaL_checknumber(L, -1);
	lua_getfield(L, -2, "y");
	vec.y = luaL_checknumber(L, -1);
	lua_pop(L, 3);
	return vec;
}

static Vector2 luaL_optvector2(lua_State *L, int index, const Vector2& def = Vector2()) {

	if(lua_istable(L, index))
		return luaL_checkvector2(L, index);
	return def;
}

static void luaL_pushvector2(lua_State *L, const Vector2& vec) {

	lua_newtable(L);
	lua_pushnumber(L, vec.x);
	lua_setfield(L, -2, "x");
	lua_pushnumber(L, vec.y);
	lua_setfield(L, -2, "y");
}

static int l_add_point(lua_State *L) {

	Curve2D *curve = luaL_checkcurve2d(L, 1);
	Vector2 pos = luaL_checkvector2(L, 2);
	Vector2 in = luaL_optvector2(L, 3, Vector2());
	Vector2 out = luaL_optvector2(L, 4, Vector2());
	int atpos = luaL_optinteger(L, 5, -1);

	curve->add_point(pos, in, out, atpos);
	return 0;
}

static int l_set_point_pos(lua_State *L) {

	Curve2D *curve = luaL_checkcurve2d(L, 1);
	int index = luaL_checkinteger(L, 2);
	if(index >= curve->get_point_count())
		luaL_error(L, "index out of range: %d/%d", index, curve->get_point_count());
	Vector2 pos = luaL_checkvector2(L, 3);

	curve->set_point_pos(index, pos);
	return 0;
}

static int l_get_point_pos(lua_State *L) {

	Curve2D *curve = luaL_checkcurve2d(L, 1);
	int index = luaL_checkinteger(L, 2);
	if(index >= curve->get_point_count())
		luaL_error(L, "index out of range: %d/%d", index, curve->get_point_count());
	luaL_pushvector2(L, curve->get_point_pos(index));
	return 1;
}

static int l_set_point_in(lua_State *L) {

	Curve2D *curve = luaL_checkcurve2d(L, 1);
	int index = luaL_checkinteger(L, 2);
	if(index >= curve->get_point_count())
		luaL_error(L, "index out of range: %d/%d", index, curve->get_point_count());
	Vector2 in = luaL_checkvector2(L, 3);

	curve->set_point_in(index, in);
	return 0;
}

static int l_get_point_in(lua_State *L) {

	Curve2D *curve = luaL_checkcurve2d(L, 1);
	int index = luaL_checkinteger(L, 2);
	if(index >= curve->get_point_count())
		luaL_error(L, "index out of range: %d/%d", index, curve->get_point_count());
	luaL_pushvector2(L, curve->get_point_in(index));
	return 1;
}

static int l_set_point_out(lua_State *L) {

	Curve2D *curve = luaL_checkcurve2d(L, 1);
	int index = luaL_checkinteger(L, 2);
	if(index >= curve->get_point_count())
		luaL_error(L, "index out of range: %d/%d", index, curve->get_point_count());
	Vector2 out = luaL_checkvector2(L, 3);

	curve->set_point_out(index, out);
	return 0;
}

static int l_get_point_out(lua_State *L) {

	Curve2D *curve = luaL_checkcurve2d(L, 1);
	int index = luaL_checkinteger(L, 2);
	if(index >= curve->get_point_count())
		luaL_error(L, "index out of range: %d/%d", index, curve->get_point_count());
	luaL_pushvector2(L, curve->get_point_out(index));
	return 1;
}

static int l_remove_point(lua_State *L) {

	Curve2D *curve = luaL_checkcurve2d(L, 1);
	int index = luaL_checkinteger(L, 2);
	if(index >= curve->get_point_count())
		luaL_error(L, "index out of range: %d/%d", index, curve->get_point_count());
	curve->remove_point(index);
	return 0;
}

static int l_interpolate(lua_State *L) {

	Curve2D *curve = luaL_checkcurve2d(L, 1);
	int index = luaL_checkinteger(L, 2);
	float offset = luaL_checknumber(L, 3);

	luaL_pushvector2(L, curve->interpolate(index, offset));
	return 1;
}

static int l_interpolatef(lua_State *L) {

	Curve2D *curve = luaL_checkcurve2d(L, 1);
	float index = luaL_checknumber(L, 2);

	luaL_pushvector2(L, curve->interpolatef(index));
	return 1;
}

static int l_set_bake_interval(lua_State *L) {

	Curve2D *curve = luaL_checkcurve2d(L, 1);
	float distance = luaL_checknumber(L, 2);
	curve->set_bake_interval(distance);
	return 0;
}

static int l_get_bake_interval(lua_State *L) {

	Curve2D *curve = luaL_checkcurve2d(L, 1);
	lua_pushinteger(L, curve->get_bake_interval());
	return 1;
}

static int l_get_baked_length(lua_State *L) {

	Curve2D *curve = luaL_checkcurve2d(L, 1);
	lua_pushnumber(L, curve->get_baked_length());
	return 1;
}

static int l_interpolate_baked(lua_State *L) {

	Curve2D *curve = luaL_checkcurve2d(L, 1);
	float offset = luaL_checknumber(L, 2);
	bool cubic = luaL_optboolean(L, 3, false);
	luaL_pushvector2(L, curve->interpolate_baked(offset, cubic));
	return 1;
}

static int l_get_baked_points(lua_State *L) {

	Curve2D *curve = luaL_checkcurve2d(L, 1);
	Vector2Array points = curve->get_baked_points();
	lua_newtable(L);
	{
		for(int i = 0; i < points.size(); i++) {
			luaL_pushvector2(L, points[i]);
			lua_rawseti(L, -2, i + 1);
		}
	}
	return 1;
}

static int l_tesselate(lua_State *L) {

	Curve2D *curve = luaL_checkcurve2d(L, 1);
	int max_stages = luaL_optinteger(L, 2, 5);
	float tolerance = luaL_optnumber(L, 3, 4);
	Vector2Array points = curve->tesselate(max_stages, tolerance);
	lua_newtable(L);
	{
		for(int i = 0; i < points.size(); i++) {
			luaL_pushvector2(L, points[i]);
			lua_rawseti(L, -2, i + 1);
		}
	}
	return 1;
}

static int l_gc(lua_State *L);
static int l_free(lua_State *L) {

	l_gc(L);
	lua_pushnil(L);
	lua_setmetatable(L, 1);
	return 0;
}

static const luaL_Reg methods[] = {

	{ "get_point_count", l_get_point_count },
	{ "add_point", l_add_point },
	{ "set_point_pos", l_set_point_pos },
	{ "get_point_pos", l_get_point_pos },
	{ "set_point_in", l_set_point_in },
	{ "get_point_in", l_get_point_in },
	{ "set_point_out", l_set_point_out },
	{ "get_point_out", l_get_point_out },
	{ "remove_point", l_remove_point },
	{ "interpolate", l_interpolate },
	{ "interpolatef", l_interpolatef },
	{ "set_bake_interval", l_set_bake_interval },
	{ "get_bake_interval", l_get_bake_interval },
	{ "get_baked_length", l_get_baked_length },
	{ "interpolate_baked", l_interpolate_baked },
	{ "get_baked_points", l_get_baked_points },
	{ "tesselate", l_tesselate },
	{ "free", l_free },
	{ NULL, NULL },
};

static int l_gc(lua_State *L) {

	Curve2D *curve = luaL_tocurve2d(L, 1);
	if(curve != NULL)
		delete curve;
	return 0;
}

static int l_tostring(lua_State *L) {

	Curve2D *curve = luaL_tocurve2d(L, 1);
	lua_pushfstring(L, "Curve2D: %p", lua_touserdata(L, 1));
	return 1;
}

static const luaL_Reg metas[] = {

	{ "__gc", l_gc },
	{ "__tostring", l_tostring },
	{ NULL, NULL },
};

extern "C" int luaopen_curve(lua_State *L) {

	luaL_newmetatable(L, CURVE2D_STRING);
	luaL_setfuncs(L, metas, 0);
	{
		lua_newtable(L);
		luaL_setfuncs(L, methods, 0);
		lua_setfield(L, -2, "__index");
	}
	lua_pop(L, 1);

	lua_newtable(L);
	luaL_setfuncs(L, funcs, 0);
	return 1;
}
