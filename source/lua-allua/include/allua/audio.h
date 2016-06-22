#ifndef allua_audio_H
#define allua_audio_H

#define LUA_LIB
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#define ALLEGRO_NO_MAGIC_MAIN
#include <allegro5/allegro5.h>

/* Function: allua_register_audio
 * Registers audio functionality to the lua state.
 * */
int allua_register_audio(lua_State * L);

/* vim: set sts=3 sw=3 et: */
#endif
