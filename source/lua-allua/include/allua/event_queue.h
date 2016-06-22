#ifndef allua_EVENT_QUEUE_H
#define allua_EVENT_QUEUE_H

#define LUA_LIB
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#define ALLEGRO_NO_MAGIC_MAIN
#include <allegro5/allegro5.h>

typedef ALLEGRO_EVENT_QUEUE *ALLUA_event_queue;

/* Function: allua_register_event_queue
 * Registers Event_queue functionality to the lua state.
 * */
int allua_register_event_queue(lua_State * L);

/* Function: allua_check_event_queue
 * Returns:
 * Pointer to Event_queue instance.
 * */
ALLUA_event_queue allua_check_event_queue(lua_State * L, int index);

/* Function: allua_set_event_callback
 * Each type of event source may have different data in the event
 * This function lets you register a function that fills in that data
 * */
void allua_set_event_callback(ALLEGRO_EVENT_TYPE event,
                              void (*cb) (lua_State * L, ALLEGRO_EVENT * e));

/* vim: set sts=3 sw=3 et: */
#endif
