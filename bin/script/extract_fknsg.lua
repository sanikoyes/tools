-- 放开那三国
local lfs = require "lfs"
-- local xxtea = require "misc.xxtea"
-- local zlib = require "zlib"

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
  for i = 1, 32 do
    HASH_BITS[i] = HASH_KEYS[i]
  end
  HASH_BITS[128] = 32
  return true
end

local function encrypt_hash_tail()
  for i = 1, 32 do
    HASH_BITS[i] = HASH_KEYS[95 + i]
  end
  HASH_BITS[128] = 32
  return true
end

local function encrypt_hash_odd()
  local v3 = 1
  local v2 = 2

  while true do
    if v2 > 128 or v3 > 32 then
      break
    end
    HASH_BITS[v3] = HASH_KEYS[v2]
    v2 = v2 + 2
    v3 = v3 + 1
  end
  HASH_BITS[128] = v3 - 1
  return true
end

local function encrypt_hash_even()
  local v3 = 1
  local v2 = 1
  while true do
    if v2 > 128 or v3 > 32 then
      break
    end
    HASH_BITS[v3] = HASH_KEYS[v2]
    v2 = v2 + 2
    v3 = v3 + 1
  end
  HASH_BITS[128] = v3 - 1
  return true
end

local function encrypt_hash_fibonacci()
  local secret = {
    1, 2, 3, 5, 8, 0xD, 0x15, 0x22, 0x37, 0x59, 0
  }
  for i = 1, 10 do
    HASH_BITS[i] = HASH_KEYS[secret[i] + 1]
  end
  HASH_BITS[128] = 10
  return true
end

local function encrypt_hash_prime()
  local secret = {
    2, 3, 5, 7, 0xB, 0xD, 0x11, 0x13, 0x17, 0x1D, 0x1F,
    0x25, 0x29, 0x2B, 0x2F, 0x35, 0x3B, 0x3D, 0x43, 0x47,
    0x49, 0x4F, 0x53, 0x59, 0x5D, 0x61, 0x65, 0x67, 0x6B,
    0x6D, 0x71, 0x77, 0,
  }
  for i = 1, 32 do
    HASH_BITS[i] = HASH_KEYS[secret[i] + 1]
  end
  HASH_BITS[128] = 32
  return true
end

local function encrypt_hash_odds()
  local v3 = 1
  for i = 1, math.huge do
    if i > 128 or v3 > 32 then
      break
    end
    if HASH_KEYS[i] & 1 == 1 then
      HASH_BITS[v3] = HASH_KEYS[i]
      v3 = v3 + 1
    end
  end
  HASH_BITS[128] = v3 - 1
  return true
end

local function encrypt_hash_evens()
  local v3 = 1
  for i = 1, math.huge do
    if i > 128 or v3 > 32 then
      break
    end
    if HASH_KEYS[i] & 1 == 0 then
      HASH_BITS[v3] = HASH_KEYS[i]
      v3 = v3 + 1
    end
  end
  HASH_BITS[128] = v3 - 1
  return true
end

local function encrypt_hash_tail_odd()
  local v3 = 1
  local v2 = 128
  while true do
    if v2 <= 1 or v3 >= 32 then
      break
    end
    HASH_BITS[v3] = HASH_KEYS[v2]
    v2 = v2 - 2
    v3 = v3 + 1
  end
  HASH_BITS[128] = v3
  return true
end

local function encrypt_hash_tail_even()
  local v3 = 1
  local v2 = 127
  while true do
    if v2 <= 1 or v3 >= 32 then
      break
    end
    HASH_BITS[v3] = HASH_KEYS[v2]
    v2 = v2 - 2
    v3 = v3 + 1
  end
  HASH_BITS[128] = v3
  return true
end

local function encrypt_hash_tail_odds()
  local v3 = 1
  for i = 128, 1, -1 do
    if v3 > 32 then
      break
    end
    if HASH_KEYS[i] & 1 == 1 then
      HASH_BITS[v3] = HASH_KEYS[i]
      v3 = v3 + 1
    end
  end
  HASH_BITS[128] = v3 - 1
  return true
end

local function encrypt_hash_tail_evens()
  local v3 = 1
  for i = 128, 1, -1 do
    if v3 > 32 then
      break
    end
    if HASH_KEYS[i] & 1 == 0 then
      HASH_BITS[v3] = HASH_KEYS[i]
      v3 = v3 + 1
    end
  end
  HASH_BITS[128] = v3 - 1
  return true
end

local function encrypt_hash_odd_sub()
  local v3 = 1
  local v2 = 1
  while true do
    if v2 > 127 or v3 > 32 then
      break
    end
    HASH_BITS[v3] = (HASH_KEYS[v2] - HASH_KEYS[v2 + 1]) % 0x100
    v2 = v2 + 2
    v3 = v3 + 1
  end
  HASH_BITS[128] = v3 - 1
  return true
end

local function encrypt_hash_even_sub()
  local v3 = 1
  local v2 = 2
  while true do
    if v2 > 127 or v3 > 32 then
      break
    end
    HASH_BITS[v3] = (HASH_KEYS[v2] - HASH_KEYS[v2 + 1]) % 0x100
    v2 = v2 + 2
    v3 = v3 + 1
  end
  HASH_BITS[128] = v3 - 1
  return true
end

local function encrypt_hash_odd_add()
  local v3 = 1
  local v2 = 1
  while true do
    if v2 > 127 or v3 > 32 then
      break
    end
    HASH_BITS[v3] = (HASH_KEYS[v2] + HASH_KEYS[v2 + 1]) % 0x100
    v2 = v2 + 2
    v3 = v3 + 1
  end
  HASH_BITS[128] = v3 - 1
  return true
end

local function encrypt_hash_even_add()
  local v3 = 1
  local v2 = 2
  while true do
    if v2 > 127 or v3 > 32 then
      break
    end
    HASH_BITS[v3] = (HASH_KEYS[v2] + HASH_KEYS[v2 + 1]) % 0x100
    v2 = v2 + 2
    v3 = v3 + 1
  end
  HASH_BITS[128] = v3 - 1
  return true
end

local HASH_ROUTINES

local function decrypt_basic(source)
  local len = string.unpack("<I4", source, 5)
  if #source - len ~= 32 then
    return false
  end
  local hash = string.unpack("B", source, 10)
  if hash > 15 then
    return false
  end
  local succ = HASH_ROUTINES[hash + 2 + 1]()

  local hash_len = HASH_BITS[128]
  local hash_idx = 0

  local result = {}
  local offset = 33
  while offset <= #source do

    local index = (len % hash_len + hash_idx) % hash_len

    table.insert(result,
      string.char(string.unpack("B", source, offset) ~ HASH_BITS[index + 1])
    )
    if #source > offset then
      table.insert(result,
        string.char(string.unpack("B", source, offset + 1) + 0)
      )
    end

    hash_idx = hash_idx + 2
    offset = offset + 2
  end
  return succ, table.concat(result)
end

HASH_ROUTINES = {
  false,
  decrypt_basic,
  encrypt_hash_header,
  encrypt_hash_tail,
  encrypt_hash_odd,
  encrypt_hash_even,
  encrypt_hash_fibonacci,
  encrypt_hash_prime,
  encrypt_hash_odds,
  encrypt_hash_evens,
  encrypt_hash_tail_odd,
  encrypt_hash_tail_even,
  encrypt_hash_tail_odds,
  encrypt_hash_tail_evens,
  encrypt_hash_odd_sub,
  encrypt_hash_even_sub,
  encrypt_hash_odd_add,
  encrypt_hash_even_add,
}

local function bt_decrypt(source)
  local sig = string.unpack("<I4", source)
  if sig ~= 0xFEFEFEFE then
    return
  end
  local func = string.unpack("B", source, 9)
  local succ, result = HASH_ROUTINES[func + 1](source)
  if not succ and result then
    print(result)
    os.exit()
  end
  return succ and result or nil
end

local sign = "\xFE\xFE\xFE\xFE"

local decrypt_script = function(path, fa)
  -- if path:find("%.lua$") then
  if fa.mode == "file" then
    local ctx = io.open(path, "rb"):read "*all"
    if ctx:find(sign) == 1 then
      print("Decrypting " .. path)
      ctx = bt_decrypt(ctx)

      if ctx and #ctx > 0 then
        io.open(path, "wb"):write(ctx)
      end
    end
    collectgarbage()
  end
end

traversal_dir("fknsg", decrypt_script)

