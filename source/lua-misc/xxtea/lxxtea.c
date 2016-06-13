#include "xxtea.h"
#define LUA_LIB
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

static int l_xxtea_encrypt(lua_State *L) {

    size_t data_len;
    const char *data = luaL_checklstring(L, 1, &data_len);
    size_t key_len;
    const char *key = luaL_checklstring(L, 2, &key_len);

    xxtea_long ret_length;
    unsigned char *ret = xxtea_encrypt((unsigned char *) data, data_len, (unsigned char *) key, key_len, &ret_length);

    lua_pushlstring(L, (char *) ret, ret_length);
    free(ret);

    return 1;
}

static int l_xxtea_decrypt(lua_State *L) {

    size_t data_len;
    const char *data = luaL_checklstring(L, 1, &data_len);
    size_t key_len;
    const char *key = luaL_checklstring(L, 2, &key_len);

    xxtea_long ret_length;
    unsigned char *ret = xxtea_decrypt((unsigned char *) data, data_len, (unsigned char *) key, key_len, &ret_length);

    lua_pushlstring(L, (char *) ret, ret_length);
    free(ret);

    return 1;
}

static const struct luaL_Reg xxtea_lib[] = {
    { "encrypt", l_xxtea_encrypt },
    { "decrypt", l_xxtea_decrypt },
    { NULL, NULL },
};

LUA_API int luaopen_misc_xxtea(lua_State *L) {
    luaL_newlib(L, xxtea_lib);
    return 1;
}
