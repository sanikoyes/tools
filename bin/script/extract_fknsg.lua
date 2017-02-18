-- 放开那三国
local lfs = require "lfs"
local xxtea = require "misc.xxtea"
local zlib = require "zlib"

-- 遍历路径
local function traversal_dir(path, callback)
	for name in lfs.dir(path) do
		local full_path = string.format("%s/%s", path, name)
		local fa = lfs.attributes(full_path)
		if name == "." or name == ".." then
		else
			callback(full_path, fa)
			if fa.mode == "directory" then
				traversal_dir(full_path, callback)
			end
		end
	end
end

local HASH_BITS = {
	0x4, 0x8B, 0xCD, 0xBF, 0xF8, 0, 0x95, 0xF1, 0, 0x5B,
	0x84, 0xD2, 0xE4, 0x2A, 0xBD, 0xB, 0xBE, 0xF5, 0x15,
	0x5C, 0x13, 0x61, 0x41, 0x23, 0xBC, 0xA0, 0x88, 9,
	0xC2, 0x8D, 0x54, 0xC6, 0x98, 0xA1, 6, 0x91, 0x22,
	0x1B, 3, 0xA1, 0xF5, 0x88, 0x74, 0xDA, 0x32, 0xB2,
	0xE5, 0xF0, 0xA8, 0x7A, 0xCD, 0x3B, 0xDC, 0xF, 0x5E,
	0x19, 0xAF, 0x67, 0xA1, 0xF1, 0x74, 0xF6, 0xB8, 0x8C,
	0x98, 0x3E, 0x1E, 0xBA, 0x5A, 0x22, 0x5D, 0x50, 0x2A,
	0x51, 0x2C, 0x5C, 4, 0x91, 0x4D, 0x2D, 0xD, 0x9A, 0x68,
	0x69, 0xA9, 0xC7, 2, 0xD8, 0xAE, 0xA4, 0xCA, 0x23,
	0x9B, 3, 0x2F, 0xB3, 0x42, 0x4D, 0xEE, 0x9C, 0xEE,
	0x4C, 0x6C, 0x19, 0x1D, 0x98, 0xF4, 0x22, 0xAA, 0x43,
	0x4F, 0x37, 0x5D, 0xB7, 0x20, 0x87, 0xFE, 0x22, 0x60,
	0x2D, 0x46, 0xAB, 0x50, 0x61, 0xAE, 0xFE, 0x16, 0x70,
}

local HASH_KEYS = {
	0x70, 0x96, 0xB2, 0x9D, 0xD0, 0x52, 0x19, 0x9A, 0x79,
	0xC6, 0xD9, 0x6C, 0x6B, 0xBD, 0xDC, 0x4C, 0x51, 0x52,
	0xAC, 0xFA, 0x99, 0x5C, 0x65, 0x71, 0x9B, 6, 0x80,
	0x4A, 2, 0x6E, 0x20, 2, 0x40, 0x10, 4, 0x80, 4, 8,
	1, 0x40, 0x99, 0x72, 5, 0x4C, 0x10, 0x56, 0x9E, 0x29,
	0xF0, 0x97, 0x70, 0x4A, 4, 0x5B, 0x87, 0xE0, 0x27,
	0x58, 0xB2, 0x53, 0x53, 0x4D, 0xAF, 0x38, 0xBE, 0xCB,
	0x3E, 0x3F, 0x16, 0x40, 0xAD, 0x2F, 0xB3, 0x33, 0x7C,
	0x43, 0x89, 0x1B, 0xEC, 0xF9, 0x33, 0x5D, 0x44, 0xB6,
	0x38, 0x4B, 0x98, 0x5F, 0xA3, 0xCA, 0xB3, 0x76, 0x18,
	0x63, 0xAF, 0x57, 0xAE, 0x6D, 0x16, 0x45, 0x2E, 0x43,
	0x74, 0x61, 0x76, 0xF0, 0xA4, 0x7F, 0x8C, 0x91, 0x79,
	0xBF, 0x6E, 0x3D, 0x76, 0xA6, 0x88, 0x8E, 7, 0x2C,
	0x12, 0xED, 0x22, 0x86, 0xCE, 0x98, 0xF7, 0x74,
}

local function encrypt_hash_header()
  -- memcpy(HASH_BITS, HASH_KEYS, 0x80u);
  -- HASH_BITS[127] = 32;
  -- return 0;
end

--[[

int encrypt_hash_tail(unsigned __int8 *a1, unsigned int a2)
{
  memcpy(HASH_BITS, &HASH_KEYS[95], 128u);
  HASH_BITS[127] = 32;
  return 0;
}

int encrypt_hash_odd(unsigned __int8 *a1, unsigned int a2)
{
  signed int v0; // r2@5
  signed int v2; // [sp+0h] [bp-Ch]@1
  signed int v3; // [sp+4h] [bp-8h]@1

  v3 = 0;
  v2 = 1;
  while ( 1 )
  {
    v0 = v2 > 127 || v3 > 31 ? 0 : 1;
    if ( !v0 )
      break;
    HASH_BITS[v3] = HASH_KEYS[v2];
    v2 += 2;
    ++v3;
  }
  HASH_BITS[127] = v3;
  return 0;
}

int encrypt_hash_even(unsigned __int8 *a1, unsigned int a2)
{
  signed int v0; // r2@5
  signed int v2; // [sp+0h] [bp-Ch]@1
  signed int v3; // [sp+4h] [bp-8h]@1

  v3 = 0;
  v2 = 0;
  while ( 1 )
  {
    v0 = v2 > 127 || v3 > 31 ? 0 : 1;
    if ( !v0 )
      break;
    HASH_BITS[v3] = HASH_KEYS[v2];
    v2 += 2;
    ++v3;
  }
  HASH_BITS[127] = v3;
  return 0;
}

int encrypt_hash_fibonacci(unsigned __int8 *a1, unsigned int a2)
{
  signed int v0; // r2@6
  signed int i; // [sp+4h] [bp-8h]@1

  static const DWORD dword_7201D4[11] = {
	  1, 2, 3, 5, 8, 0xD, 0x15, 0x22, 0x37, 0x59, 0
  };

  for ( i = 0; ; ++i )
  {
    v0 = dword_7201D4[i] <= 127 && i <= 31 && dword_7201D4[i] ? 1 : 0;
    if ( !v0 )
      break;
    HASH_BITS[i] = HASH_KEYS[dword_7201D4[i] ];
  }
  HASH_BITS[127] = i;
  return 0;
}

int encrypt_hash_prime(unsigned __int8 *a1, unsigned int a2)
{
  signed int v0; // r2@6
  signed int i; // [sp+4h] [bp-8h]@1

  static const DWORD dword_720150[33] = {
	2, 3, 5, 7, 0xB, 0xD, 0x11, 0x13, 0x17, 0x1D, 0x1F,
	0x25, 0x29, 0x2B, 0x2F, 0x35, 0x3B, 0x3D, 0x43, 0x47,
	0x49, 0x4F, 0x53, 0x59, 0x5D, 0x61, 0x65, 0x67, 0x6B,
	0x6D, 0x71, 0x77, 0,
  };

  for ( i = 0; ; ++i )
  {
    v0 = dword_720150[i] <= 127 && i <= 31 && dword_720150[i] ? 1 : 0;
    if ( !v0 )
      break;
    HASH_BITS[i] = HASH_KEYS[dword_720150[i] ];
  }
  HASH_BITS[127] = i;
  return 0;
}

int encrypt_hash_odds(unsigned __int8 *a1, unsigned int a2)
{
  signed int v0; // r2@7
  signed int i; // [sp+0h] [bp-Ch]@1
  signed int v3; // [sp+4h] [bp-8h]@1

  v3 = 0;
  for ( i = 0; ; ++i )
  {
    v0 = i > 127 || v3 > 31 ? 0 : 1;
    if ( !v0 )
      break;
    if ( (((unsigned __int8)HASH_KEYS[i] + (unsigned __int8)(HASH_KEYS[i] >> 31)) & 1) - (HASH_KEYS[i] >> 31) == 1 )
      HASH_BITS[v3++] = HASH_KEYS[i];
  }
  HASH_BITS[0] = v3;
  return 0;
}

int encrypt_hash_evens(unsigned __int8 *a1, unsigned int a2)
{
  signed int v0; // r2@7
  signed int i; // [sp+0h] [bp-Ch]@1
  signed int v3; // [sp+4h] [bp-8h]@1

  v3 = 0;
  for ( i = 0; ; ++i )
  {
    v0 = i > 127 || v3 > 31 ? 0 : 1;
    if ( !v0 )
      break;
    if ( !(HASH_KEYS[i] & 1) )
      HASH_BITS[v3++] = HASH_KEYS[i];
  }
  HASH_BITS[127] = v3;
  return 0;
}

int encrypt_hash_tail_odd(unsigned __int8 *a1, unsigned int a2)
{
  signed int v0; // r2@5
  signed int v2; // [sp+0h] [bp-Ch]@1
  signed int v3; // [sp+4h] [bp-8h]@1

  v3 = 0;
  v2 = 127;
  while ( 1 )
  {
    v0 = v2 <= 0 || v3 > 31 ? 0 : 1;
    if ( !v0 )
      break;
    HASH_BITS[v3] = HASH_KEYS[v2];
    v2 -= 2;
    ++v3;
  }
  HASH_BITS[127] = v3;
  return 0;
}

int encrypt_hash_tail_even(unsigned __int8 *a1, unsigned int a2)
{
  signed int v0; // r2@5
  signed int v2; // [sp+0h] [bp-Ch]@1
  signed int v3; // [sp+4h] [bp-8h]@1

  v3 = 0;
  v2 = 126;
  while ( 1 )
  {
    v0 = v2 <= 0 || v3 > 31 ? 0 : 1;
    if ( !v0 )
      break;
    HASH_BITS[v3] = HASH_KEYS[v2];
    v2 -= 2;
    ++v3;
  }
  HASH_BITS[127] = v3;
  return 0;
}

int encrypt_hash_tail_odds(unsigned __int8 *a1, unsigned int a2)
{
  signed int v0; // r2@7
  signed int i; // [sp+0h] [bp-Ch]@1
  signed int v3; // [sp+4h] [bp-8h]@1

  v3 = 0;
  for ( i = 127; ; --i )
  {
    v0 = i <= 0 || v3 > 31 ? 0 : 1;
    if ( !v0 )
      break;
    if ( (((unsigned __int8)HASH_KEYS[i] + (unsigned __int8)(HASH_KEYS[i] >> 31)) & 1) - (HASH_KEYS[i] >> 31) == 1 )
      HASH_BITS[v3++] = HASH_KEYS[i];
  }
  HASH_BITS[127] = v3;
  return 0;
}

int encrypt_hash_tail_evens(unsigned __int8 *a1, unsigned int a2)
{
  signed int v0; // r2@7
  signed int i; // [sp+0h] [bp-Ch]@1
  signed int v3; // [sp+4h] [bp-8h]@1

  v3 = 0;
  for ( i = 127; ; --i )
  {
    v0 = i <= 0 || v3 > 31 ? 0 : 1;
    if ( !v0 )
      break;
    if ( !(HASH_KEYS[i] & 1) )
      HASH_BITS[v3++] = HASH_KEYS[i];
  }
  HASH_BITS[127] = v3;
  return 0;
}

int encrypt_hash_odd_sub(unsigned __int8 *a1, unsigned int a2)
{
  signed int v0; // r2@5
  signed int v2; // [sp+0h] [bp-Ch]@1
  signed int v3; // [sp+4h] [bp-8h]@1

  v3 = 0;
  v2 = 0;
  while ( 1 )
  {
    v0 = v2 > 126 || v3 > 31 ? 0 : 1;
    if ( !v0 )
      break;
    HASH_BITS[v3] = (unsigned __int8)(HASH_KEYS[v2] - HASH_KEYS[v2 + 1]);
    v2 += 2;
    ++v3;
  }
  HASH_BITS[127] = v3;
  return 0;
}

int encrypt_hash_even_sub(unsigned __int8 *a1, unsigned int a2)
{
  signed int v0; // r2@5
  signed int v2; // [sp+0h] [bp-Ch]@1
  signed int v3; // [sp+4h] [bp-8h]@1

  v3 = 0;
  v2 = 1;
  while ( 1 )
  {
    v0 = v2 > 126 || v3 > 31 ? 0 : 1;
    if ( !v0 )
      break;
    HASH_BITS[v3] = (unsigned __int8)(HASH_KEYS[v2] - HASH_KEYS[v2 + 1]);
    v2 += 2;
    ++v3;
  }
  HASH_BITS[127] = v3;
  return 0;
}

int encrypt_hash_odd_add(unsigned __int8 *a1, unsigned int a2)
{
  signed int v0; // r2@5
  signed int v2; // [sp+0h] [bp-Ch]@1
  signed int v3; // [sp+4h] [bp-8h]@1

  v3 = 0;
  v2 = 0;
  while ( 1 )
  {
    v0 = v2 > 126 || v3 > 31 ? 0 : 1;
    if ( !v0 )
      break;
    HASH_BITS[v3] = (unsigned __int8)(HASH_KEYS[v2] + HASH_KEYS[v2 + 1]);
    v2 += 2;
    ++v3;
  }
  HASH_BITS[127] = v3;
  return 0;
}

int encrypt_hash_even_add(unsigned __int8 *a1, unsigned int a2)
{
  signed int v0; // r2@5
  signed int v2; // [sp+0h] [bp-Ch]@1
  signed int v3; // [sp+4h] [bp-8h]@1

  v3 = 0;
  v2 = 1;
  while ( 1 )
  {
    v0 = v2 > 126 || v3 > 31 ? 0 : 1;
    if ( !v0 )
      break;
    HASH_BITS[v3] = (unsigned __int8)(HASH_KEYS[v2] + HASH_KEYS[v2 + 1]);
    v2 += 2;
    ++v3;
  }
  HASH_BITS[127] = v3;
  return 0;
}

typedef int(*HASHER)(unsigned __int8 *, unsigned int);
HASHER HASH_ROUTINES[] = {
	NULL,
	&decrypt_basic,
	&encrypt_hash_header,
	&encrypt_hash_tail,
	&encrypt_hash_odd,
	&encrypt_hash_even,
	&encrypt_hash_fibonacci,
	&encrypt_hash_prime,
	&encrypt_hash_odds,
	&encrypt_hash_evens,
	&encrypt_hash_tail_odd,
	&encrypt_hash_tail_even,
	&encrypt_hash_tail_odds,
	&encrypt_hash_tail_evens,
	&encrypt_hash_odd_sub,
	&encrypt_hash_even_sub,
	&encrypt_hash_odd_add,
	&encrypt_hash_even_add,
};

int decrypt_basic(unsigned __int8 *a1, unsigned int a2)
{
  signed int v2; // r3@2
  signed int v4; // [sp+0h] [bp-2Ch]@1
  unsigned __int8 *v5; // [sp+4h] [bp-28h]@1
  unsigned int v6; // [sp+10h] [bp-1Ch]@5
  unsigned int v7; // [sp+1Ch] [bp-10h]@5

  v5 = a1 + 32;
  v4 = a2 - 32;
  if ( *((DWORD *)a1 + 1) == a2 - 32 )
  {
    if ( a1[9] <= 0xFu )
    {
      HASH_ROUTINES[a1[9] + 2](NULL, NULL);
      v7 = HASH_BITS[127];
      v6 = 0;
      while ( v4 > v6 )
      {
        *v5 ^= HASH_BITS[(v4 % (signed int)v7 + v6) % v7];
        v6 += 2;
        v5 += 2;
      }
      v2 = 0;
    }
    else
    {
      v2 = 3;
    }
  }
  else
  {
    v2 = 3;
  }
  return v2;
}

signed int __fastcall bt_decrypt(unsigned __int8 *a1, unsigned __int32 *a2)
{
  signed int v2; // r3@3
  size_t *v4; // [sp+0h] [bp-1Ch]@1
  unsigned __int8 *dest; // [sp+4h] [bp-18h]@1

  dest = a1;
  v4 = (size_t *)a2;
  if ( *(unsigned int *)a1 == 0xFEFEFEFE )
  {
    if ( (*(&HASH_ROUTINES[a1[8] ]))(a1, *a2) )
    {
      v2 = 0;
    }
    else
    {
      *v4 -= 32;
      memmove(dest, dest + 32, *v4);
      v2 = 1;
    }
  }
  else
  {
    v2 = 0;
  }
  return v2;
}

int _tmain(int argc, _TCHAR* argv[])
{
	//FILE *fp = fopen("D:/Git/tools/bin/script/FKNSG/assets/script/battle/BattleCardUtil.lua", "rb");
	FILE *fp = fopen("D:/Git/tools/bin/script/FKNSG/assets/images/achie/00.png", "rb");
	fseek(fp, SEEK_END, 0);
	long size = ftell(fp);
	fseek(fp, SEEK_SET, 0);

	size = 2739;

	std::string buf;
	buf.resize(size);
	fread(&buf[0], size, 1, fp);

	fclose(fp);

	std::string target;
	target.resize(buf.size());
	//bt_decrypt((unsigned char *) &buf[0], (unsigned int *) &target[0]);
	bt_decrypt((unsigned char *) &buf[0], (unsigned int *) &size);

	fp = fopen("D:/Git/tools/bin/script/FKNSG/assets/images/achie/00.dec.png", "wb+");
	fwrite(&buf[0], buf.size() - 32, 1, fp);
	fclose(fp);


	return 0;
}

]]

local function decrypt(path)
	local ctx = io.open(path, "rb"):read "*all"
	collectgarbage()
end

decrypt("FKNSG/assets/script/battle/BattleCardUtil.lua")

-- local sign = "DHGAMES"
-- local key = "cxxwp5tcPIJ0x90r"

-- local zlib_sign = "DHZAMES"

-- local decrypt_script = function(path, fa)
-- 	if fa.mode == "file" then
-- 	-- if path:find("%.lua$") or path:find("%.png$") then
-- 		local ctx = io.open(path, "rb"):read "*all"
-- 		if ctx:find(sign) == 1 then
-- 			print("Decrypting " .. path)

-- 			ctx = ctx:sub(#sign + 1)
-- 			ctx = xxtea.decrypt(ctx, key)

-- 			if #ctx > 0 then
-- 				-- print(path, #ctx)
-- 				io.open(path, "wb"):write(ctx)
-- 			end

-- 		elseif ctx:find(zlib_sign) == 1 then
-- 			print("Decompressing " .. path)
-- 			ctx = ctx:sub(#zlib_sign + 1)
-- 			local inflate = zlib.inflate()
-- 			ctx = inflate(ctx)

-- 			if #ctx > 0 then
-- 				print(path, #ctx)
-- 				io.open(path, "wb"):write(ctx)
-- 			end
-- 		end
-- 		collectgarbage()
-- 	end
-- end

-- -- traversal_dir("fknsg", decrypt_script)

