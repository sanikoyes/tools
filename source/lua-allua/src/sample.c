#include "../include/allua/sample.h"
#include "../include/allua/sample_id.h"
#include "../include/allua/sample_instance.h"
#include <stdio.h>

#define SAMPLE_STRING "sample"

/* Common handlers
 * */
/*static ALLUA_sample tosample (lua_State *L, int index)//, int *gc_allowed)
{
  struct ALLUA_sample_s *pi = (struct ALLUA_sample_s*)lua_touserdata(L, index);
  if (pi == NULL) luaL_typerror(L, index, SAMPLE_STRING);
//  if(gc_allowed)
//  	*gc_allowed = pi->gc_allowed;
  return pi->sample;
}
*/
ALLUA_sample allua_check_sample(lua_State * L, int index /* int *gc_allowed */ )
{
   struct ALLUA_sample_s *pi;
   ALLUA_sample im;
   luaL_checktype(L, index, LUA_TUSERDATA);
   pi = (struct ALLUA_sample_s *)luaL_checkudata(L, index, SAMPLE_STRING);
   if (pi == NULL)
      luaL_typerror(L, index, SAMPLE_STRING);
   im = pi->sample;
   if (!im)
      luaL_error(L, "null sample");
   return im;
}

struct ALLUA_sample_s *allua_pushsample(lua_State * L, ALLUA_sample im,
                                        int gc_allowed)
{
   struct ALLUA_sample_s *pi;
   if (!im) {
      lua_pushnil(L);
      return NULL;
   }
   pi = (struct ALLUA_sample_s *)lua_newuserdata(L,
                                                 sizeof(struct ALLUA_sample_s));
   pi->sample = im;
   pi->gc_allowed = gc_allowed;
   luaL_getmetatable(L, SAMPLE_STRING);
   lua_setmetatable(L, -2);
   return pi;
}

/* Constructor and methods
 * */

static int allua_sample_load(lua_State * L)
{
   const char *filename = luaL_checkstring(L, 1);
   ALLUA_sample sample = al_load_sample(filename);
   if (sample)
      allua_pushsample(L, sample, true);
   else
      lua_pushnil(L);

   return 1;
}

static int allua_sample_save(lua_State * L)
{
   ALLUA_sample sample = allua_check_sample(L, 1);
   const char *filename = luaL_checkstring(L, 2);
   lua_pushboolean(L, al_save_sample(filename, sample));
   return 1;
}

static int allua_sample_play(lua_State * L)
{
   ALLUA_sample spl = allua_check_sample(L, 1);
   float gain = luaL_checknumber(L, 2);
   float pan = luaL_checknumber(L, 3);
   float speed = luaL_checknumber(L, 4);
   int loop = luaL_checkint(L, 5);
   ALLEGRO_SAMPLE_ID ret_id;
   int s = al_play_sample(spl, gain, pan, speed, loop, &ret_id);
   lua_pushboolean(L, s);
   if (s) {
      allua_pushsample_id(L, ret_id);
      return 2;
   }
   return 1;
}

static int allua_sample_stop_samples(lua_State * L)
{
   al_stop_samples();
   return 0;
}

static int allua_sample_create_instance(lua_State * L)
{
   struct ALLUA_sample_s *pi;
   ALLUA_sample sample_data;
   ALLUA_sample_instance instance;

   pi = (struct ALLUA_sample_s *)(lua_touserdata(L, 1));
   if (pi == NULL)
      sample_data = NULL;
   else
      sample_data = allua_check_sample(L, 1);
   instance = al_create_sample_instance(sample_data);
   if (instance) {
      struct ALLUA_sample_instance_s *si_s =
          allua_pushsample_instance(L, instance, true);
      lua_pushvalue(L, 1);
      si_s->sample_ref = luaL_ref(L, LUA_REGISTRYINDEX);
   }
   else {
      lua_pushnil(L);
   }
   return 1;
}

static int allua_sample_get_channels(lua_State * L)
{
   ALLUA_sample sample = allua_check_sample(L, 1);
   lua_pushnumber(L, al_get_sample_channels(sample));
   return 1;
}

static int allua_sample_get_depth(lua_State * L)
{
   ALLUA_sample sample = allua_check_sample(L, 1);
   lua_pushnumber(L, al_get_sample_depth(sample));
   return 1;
}

static int allua_sample_get_frequency(lua_State * L)
{
   ALLUA_sample sample = allua_check_sample(L, 1);
   lua_pushnumber(L, al_get_sample_frequency(sample));
   return 1;
}

static int allua_sample_get_length(lua_State * L)
{
   ALLUA_sample sample = allua_check_sample(L, 1);
   lua_pushnumber(L, al_get_sample_length(sample));
   return 1;
}

static const luaL_Reg allua_sample_methods[] = {
   {"load", allua_sample_load},
   {"save", allua_sample_save},
   {"play", allua_sample_play},
   {"stop_samples", allua_sample_stop_samples},
   {"create_instance", allua_sample_create_instance},
   {"get_channels", allua_sample_get_channels},
   {"get_depth", allua_sample_get_depth},
   {"get_frequency", allua_sample_get_frequency},
   {"get_length", allua_sample_get_length},
   {0, 0}
};

/* GC and meta
 * */
static int allua_sample_gc(lua_State * L)
{
   struct ALLUA_sample_s *pi = (struct ALLUA_sample_s *)lua_touserdata(L, 1);
   if (pi->gc_allowed) {
      ALLUA_sample im = pi->sample;
      printf("goodbye sample (%p)\n", (void *)im);
      if (im)
         al_destroy_sample(im);
   }
   return 0;
}

static int allua_sample_tostring(lua_State * L)
{
   lua_pushfstring(L, "sample: %p", lua_touserdata(L, 1));
   return 1;
}

static const luaL_Reg allua_sample_meta[] = {
   {"__gc", allua_sample_gc},
   {"__tostring", allua_sample_tostring},
   {0, 0}
};

/* Other attributes
 * */
void allua_sample_set_attributes(lua_State * L)
{
}

/* Register
 * */
int allua_register_sample(lua_State * L)
{
   lua_newtable(L);
   luaL_register(L, NULL, allua_sample_methods);        /* create methods table,
                                                           add it to the globals */

   allua_sample_set_attributes(L);

   luaL_newmetatable(L, SAMPLE_STRING); /* create metatable for Image,
                                           add it to the Lua registry */
   luaL_register(L, 0, allua_sample_meta);      /* fill metatable */
   lua_pushliteral(L, "__index");
   lua_pushvalue(L, -3);        /* dup methods table */
   lua_rawset(L, -3);           /* metatable.__index = methods */
   lua_pushliteral(L, "__metatable");
   lua_pushvalue(L, -3);        /* dup methods table */
   lua_rawset(L, -3);           /* hide metatable:
                                   metatable.__metatable = methods */
   lua_pop(L, 1);               /* drop metatable */

   lua_setfield(L, -2, SAMPLE_STRING);

   return 0;                    /* return methods on the stack */
}

/* vim: set sts=3 sw=3 et: */
