#define LUA_LIB
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#define ZLIB_DLL
#include <zlib.h>

/// when define returns true it means that our architecture uses big endian
#define CC_HOST_IS_BIG_ENDIAN (int)(*(unsigned short *)"\0\xff" < 0x100) 
#define CC_SWAP32(i)  ((i & 0x000000ff) << 24 | (i & 0x0000ff00) << 8 | (i & 0x00ff0000) >> 8 | (i & 0xff000000) >> 24)
#define CC_SWAP16(i)  ((i & 0x00ff) << 8 | (i &0xff00) >> 8)   
#define CC_SWAP_INT32_LITTLE_TO_HOST(i) ((CC_HOST_IS_BIG_ENDIAN)? CC_SWAP32(i) : (i) )
#define CC_SWAP_INT16_LITTLE_TO_HOST(i) ((CC_HOST_IS_BIG_ENDIAN)? CC_SWAP16(i) : (i) )
#define CC_SWAP_INT32_BIG_TO_HOST(i)    ((CC_HOST_IS_BIG_ENDIAN)? (i) : CC_SWAP32(i) )
#define CC_SWAP_INT16_BIG_TO_HOST(i)    ((CC_HOST_IS_BIG_ENDIAN)? (i):  CC_SWAP16(i) )

struct CCZHeader {
    unsigned char   sig[4];             /** Signature. Should be 'CCZ!' 4 bytes. */
    unsigned short  compression_type;   /** Should be 0. */
    unsigned short  version;            /** Should be 2 (although version type==1 is also supported). */
    unsigned int    reserved;           /** Reserved for users. */
    unsigned int    len;                /** Size of the uncompressed file. */
};

enum {
    CCZ_COMPRESSION_ZLIB,               /** zlib format. */
    CCZ_COMPRESSION_BZIP2,              /** bzip2 format (not supported yet). */
    CCZ_COMPRESSION_GZIP,               /** gzip format (not supported yet). */
    CCZ_COMPRESSION_NONE,               /** plain (not supported yet). */
};

static unsigned int s_uEncryptedPvrKeyParts[4] = {0,0,0,0};
static unsigned int s_uEncryptionKey[1024];
static int s_bEncryptionKeyIsValid = 0;

static void decodeEncodedPvr(lua_State *L, unsigned int *data, int len) {

    const int enclen = 1024;
    const int securelen = 512;
    const int distance = 64;
    
    // check if key was set
    // make sure to call caw_setkey_part() for all 4 key parts
    if(s_uEncryptedPvrKeyParts[0] == 0 || s_uEncryptedPvrKeyParts[1] == 0 || s_uEncryptedPvrKeyParts[2] == 0 || s_uEncryptedPvrKeyParts[3] == 0)
        luaL_error(L, "CCZ file is encrypted but key part 0 is not set. Did you call ZipUtils::setPvrEncryptionKeyPart(...)?");
    
    // create long key
    if(!s_bEncryptionKeyIsValid)
    {
        unsigned int y, p, e;
        unsigned int rounds = 6;
        unsigned int sum = 0;
        unsigned int z = s_uEncryptionKey[enclen-1];
        
        do
        {
#define DELTA 0x9e3779b9
#define MX (((z>>5^y<<2) + (y>>3^z<<4)) ^ ((sum^y) + (s_uEncryptedPvrKeyParts[(p&3)^e] ^ z)))
            
            sum += DELTA;
            e = (sum >> 2) & 3;
            
            for (p = 0; p < enclen - 1; p++)
            {
                y = s_uEncryptionKey[p + 1];
                z = s_uEncryptionKey[p] += MX;
            }
            
            y = s_uEncryptionKey[0];
            z = s_uEncryptionKey[enclen - 1] += MX;
            
        } while (--rounds);
        
        s_bEncryptionKeyIsValid = 1;
    }
    
    int b = 0;
    int i = 0;
    
    // encrypt first part completely
    for(; i < len && i < securelen; i++)
    {
        data[i] ^= s_uEncryptionKey[b++];
        
        if(b >= enclen)
        {
            b = 0;
        }
    }
    
    // encrypt second section partially
    for(; i < len; i += distance)
    {
        data[i] ^= s_uEncryptionKey[b++];
        
        if(b >= enclen)
        {
            b = 0;
        }
    }
}


static unsigned int checksumPvr(const unsigned int *data, int len)
{
    unsigned int cs = 0;
    const int cslen = 128;
    
    len = (len < cslen) ? len : cslen;
    
    for(int i = 0; i < len; i++)
    {
        cs = cs ^ data[i];
    }
    
    return cs;
}

static int inflateCCZBuffer(lua_State *L, const unsigned char *buffer, int bufferLen, unsigned char **out) {


    struct CCZHeader *header = (struct CCZHeader*) buffer;

    // verify header
    if( header->sig[0] == 'C' && header->sig[1] == 'C' && header->sig[2] == 'Z' && header->sig[3] == '!' ) {

        // verify header version
        unsigned int version = CC_SWAP_INT16_BIG_TO_HOST( header->version );
        if( version > 2 ) {

            luaL_error(L, "Unsupported CCZ header format");
            return -1;
        }

        // verify compression format
        if( CC_SWAP_INT16_BIG_TO_HOST(header->compression_type) != CCZ_COMPRESSION_ZLIB ) {

            luaL_error(L, "CCZ Unsupported compression method");
            return -1;
        }

    } else if( header->sig[0] == 'C' && header->sig[1] == 'C' && header->sig[2] == 'Z' && header->sig[3] == 'p' ) {

        // encrypted ccz file
        header = (struct CCZHeader*) buffer;

        // verify header version
        unsigned int version = CC_SWAP_INT16_BIG_TO_HOST( header->version );
        if( version > 0 ) {

            luaL_error(L, "Unsupported CCZ header format");
            return -1;
        }

        // verify compression format
        if( CC_SWAP_INT16_BIG_TO_HOST(header->compression_type) != CCZ_COMPRESSION_ZLIB ) {

            luaL_error(L, "CCZ Unsupported compression method");
            return -1;
        }

        // decrypt
        unsigned int* ints = (unsigned int*)(buffer+12);
        int enclen = (bufferLen-12)/4;

        decodeEncodedPvr(L, ints, enclen);

        // verify checksum in debug mode
        unsigned int calculated = checksumPvr(ints, enclen);
        unsigned int required = CC_SWAP_INT32_BIG_TO_HOST( header->reserved );

        if(calculated != required) {

            luaL_error(L, "Can't decrypt image file. Is the decryption key valid?");
            return -1;
        }

    } else {

        luaL_error(L, "Invalid CCZ file");
        return -1;
    }

    unsigned int len = CC_SWAP_INT32_BIG_TO_HOST( header->len );

    *out = (unsigned char*)malloc( len );
    if(! *out ) {

        luaL_error(L, "CCZ: Failed to allocate memory for texture");
        return -1;
    }

    unsigned long destlen = len;
    size_t source = (size_t) buffer + sizeof(*header);
    int ret = uncompress(*out, &destlen, (Bytef*)source, bufferLen - sizeof(*header) );

    if(ret != Z_OK) {

        luaL_error(L, "CCZ: Failed to uncompress data");
        free( *out );
        *out = NULL;
        return -1;
    }
    return len;
}

static int l_ccz_set_key(lua_State *L) {

    s_uEncryptedPvrKeyParts[0] = luaL_checknumber(L, 1);
    s_uEncryptedPvrKeyParts[1] = luaL_checknumber(L, 2);
    s_uEncryptedPvrKeyParts[2] = luaL_checknumber(L, 3);
    s_uEncryptedPvrKeyParts[3] = luaL_checknumber(L, 4);

    return 0;
}

static int l_ccz_decompress(lua_State *L) {

    int bufferLen;
    const unsigned char *buffer = luaL_checklstring(L, 1, &bufferLen);

    unsigned char *out = NULL;
    int len = inflateCCZBuffer(L, buffer, bufferLen, &out);
    if(out != NULL) {
        lua_pushlstring(L, out, len);
        free(out);
    } else
        lua_pushnil(L);

    return 1;
}

static const struct luaL_Reg lib[] = {
    { "set_key", l_ccz_set_key },
    { "decompress", l_ccz_decompress },
    { NULL, NULL },
};

LUA_API int luaopen_misc_ccz(lua_State *L) {
    luaL_newlib(L, lib);
    return 1;
}
