#ifndef allua_EVENT_SOURCE_H
#define allua_EVENT_SOURCE_H

#define LUA_LIB
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#define ALLEGRO_NO_MAGIC_MAIN
#include <allegro5/allegro5.h>

typedef ALLEGRO_EVENT_SOURCE *ALLUA_event_source;

/* Function: allua_register_event_source
 * Registers event_source functionality to the lua state.
 * */
int allua_register_event_source(lua_State * L);

/* Function: allua_check_event_source
 * Returns:
 * Pointer to event_source instance.
 * */
ALLUA_event_source allua_check_event_source(lua_State * L, int index);
ALLUA_event_source *allua_pushevent_source(lua_State * L,
                                           ALLUA_event_source im);

/* vim: set sts=3 sw=3 et: */
#endif
