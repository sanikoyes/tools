#ifndef allua_FONT_H
#define allua_FONT_H

#define LUA_LIB
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#define ALLEGRO_NO_MAGIC_MAIN
#include <allegro5/allegro5.h>
#include <allegro5/allegro_ttf.h>

typedef ALLEGRO_FONT *ALLUA_font;

/* Function: allua_register_font
 * Registers Font functionality to the lua state.
 * */
int allua_register_font(lua_State * L);

/* Function: allua_check_font
 * Returns:
 * Pointer to Font instance.
 * */
ALLUA_font allua_check_font(lua_State * L, int index);

/* vim: set sts=3 sw=3 et: */
#endif
