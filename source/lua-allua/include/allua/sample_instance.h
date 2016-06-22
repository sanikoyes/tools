#ifndef allua_SAMPLE_INSTANCE_H
#define allua_SAMPLE_INSTANCE_H

#define LUA_LIB
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#define ALLEGRO_NO_MAGIC_MAIN
#include <allegro5/allegro5.h>
#include <allegro5/allegro_audio.h>

typedef ALLEGRO_SAMPLE_INSTANCE *ALLUA_sample_instance;

struct ALLUA_sample_instance_s
{
   ALLEGRO_SAMPLE_INSTANCE *sample_instance;
   int gc_allowed;
   int sample_ref;
};

/* Function: allua_register_sample_instance
 * Registers sample_instance functionality to the lua state.
 * */
int allua_register_sample_instance(lua_State * L);

/* Function: allua_check_sample_instance
 * Returns:
 * Pointer to sample_instance instance.
 * */
ALLUA_sample_instance allua_check_sample_instance(lua_State * L,
                                                  int index
                                                  /* int *gc_allowed */ );
struct ALLUA_sample_instance_s *allua_check_sample_instance_s(lua_State * L,
                                                              int index
                                                              /* int *gc_allowed */
                                                              );
struct ALLUA_sample_instance_s *allua_pushsample_instance(lua_State * L,
                                                          ALLUA_sample_instance
                                                          im, int gc_allowed);

/* vim: set sts=3 sw=3 et: */
#endif
