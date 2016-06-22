#ifndef allua_DISPLAY_H
#define allua_DISPLAY_H

#define LUA_LIB
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#define ALLEGRO_NO_MAGIC_MAIN
#include <allegro5/allegro5.h>

typedef ALLEGRO_DISPLAY *ALLUA_display;

/* Function: allua_register_display
 * Registers display functionality to the lua state.
 * */
int allua_register_display(lua_State * L);

/* Function: allua_check_display
 * Returns:
 * Pointer to display instance.
 * */
ALLUA_display allua_check_display(lua_State * L, int index);
ALLUA_display *allua_pushdisplay(lua_State * L, ALLUA_display im);

/* vim: set sts=3 sw=3 et: */
#endif
