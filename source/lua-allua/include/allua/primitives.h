#ifndef allua_PRIMITIVES_H
#define allua_PRIMITIVES_H

#define LUA_LIB
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#define ALLEGRO_NO_MAGIC_MAIN
#include <allegro5/allegro5.h>

/* Function: allua_register_primitives
 * Registers Primitives functionality to the lua state.
 * */
int allua_register_primitives(lua_State * L);

/* vim: set sts=3 sw=3 et: */
#endif
