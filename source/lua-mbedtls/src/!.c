// #include <lua_mbedtls.h>
// #include <mbedtls/aes.h>

// #define CLASS_NAME "mbedtls_aes_context"

// static l_context(lua_State *L) {

// 	mbedtls_aes_context *ctx = lua_newuserdata(L, sizeof(mbedtls_aes_context));
// 	mbedtls_aes_init(ctx);

// 	luaL_getmetatable(L, CLASS_NAME);
// 	lua_setmetatable(L, -2);

// 	return 1;
// }

// static const luaL_Reg funcs[] = {
// 	{ "context", l_context },
// 	{ NULL, NULL },
// };

// static int l_mbedtls_aes_decrypt(lua_State *L) {

// 	mbedtls_aes_context *ctx = (mbedtls_aes_context *) luaL_checkudata(L, 1, CLASS_NAME);
// 	size_t sinput;
// 	const unsigned char *input = luaL_checklstring(L, 2, &sinput);
// 	if(sinput != 16)
// 		luaL_argerror(L, 2, "input length must be 16 bytes");
// 	unsigned char output[16];
// 	mbedtls_aes_decrypt(ctx, input, output);
// 	lua_pushlstring(L, output, sizeof(output));
// 	return 1;
// }

// static int l_gc(lua_State *L) {

// 	mbedtls_aes_context *ctx = (mbedtls_aes_context *) luaL_checkudata(L, 1, CLASS_NAME);
// 	mbedtls_aes_free(ctx);
// 	return 0;
// }

// static const luaL_Reg methods[] = {
// 	{ "decrypt", l_mbedtls_aes_decrypt },
// 	{ "__gc", l_gc },
// 	{ NULL, NULL },
// };

// LUA_API int luaopen_mbedtls_aes_core(lua_State * const L) {

// 	luaL_newclass(L, CLASS_NAME, methods);

// 	luaL_newlib(L, funcs);
// 	BIND_CONSTANT(MBEDTLS_AES_ENCRYPT);
//     return 1;
// }
