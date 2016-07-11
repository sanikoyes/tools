#define LUA_LIB
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

extern int luaopen_curve(lua_State *L);

static const luaL_Reg mods[] = {

	{ "curve", luaopen_curve },
	{ NULL, NULL },
};

LUA_API int luaopen_misc_engine(lua_State *L) {

	lua_newtable(L);

	luaL_Reg *r = &mods;
	while(r->name != NULL) {
		r->func(L);
		lua_setfield(L, -2, r->name);
		r ++;
	}
	return 1;
}
