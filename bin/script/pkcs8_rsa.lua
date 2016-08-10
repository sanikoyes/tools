local core_entropy = require "mbedtls.entropy.core"
local core_ctr_drbg = require "mbedtls.ctr_drbg.core"
local core_pk = require "mbedtls.pk.core"
local core_md = require "mbedtls.md.core"
local core_base64 = require "mbedtls.base64.core"

local entropy = core_entropy.context()
local ctr_drbg = core_ctr_drbg.context()
local pk = core_pk.context()

assert(ctr_drbg:seed(entropy, "mbedtls_pk_sign") == 0)
assert(pk:parse_key([[-----BEGIN PRIVATE KEY-----
MIICdgIBADANBgkqhkiG9w0BAQEFAASCAmAwggJcAgEAAoGBAO0m9rBaOFCEj4nc
ScPeC+6H63XMHhs4xb08lR2TbthAPKIZV3jZB0cuh91M3XJcpdhlHUGbLhbWlmG5
xKgN1Lt8Z+QoebfNEyyKM06I9YeDSykwRyEjhhOUgLjeIVV3NI8T/awhl+tb/0yy
ld+5aoXJKxOx/pzqolzoDRs0omEzAgMBAAECgYBGzwt5PHb0E6CIGS4tPW9ymULE
uV2D4z+ncR9U5WCDUSrJe6eSfbqellYazYiRTPh31DkYDa2FRC1CoKUHSJnrjeNR
2TMw0WUBFvNcqYe2qOJZg3iOhyUDhIChhQiWWC9VrzAvqSU6tuyKGMy5rAWbfTne
EnL7NHsTgRRDC+0JAQJBAPlRGW6T4TnRBtbOpRcMU+jdCyJAK3zwuRO13alhexDL
q105D1osg2uP1d3+XvTQudwCGo1qRfBSp/W72fynz5kCQQDzgmLyxGzO1rugtJNM
LQTqsRGg8ZUoUPmsEVGbmnHwRzd2OGHWbT1JuIEEb+ivrZV3PfeEObv7fDAT6qIh
yiarAkAcd4ka2iG+U0KfpkqtXgf6r7qEt6T/iBDp0js0CuBdY5P2efxpxGlhD7RQ
u6ml9Gs0Vr0nZnoD3bw1z7QtKBAJAkBiqBjesqZCxs0NtxtWaYbsbwDta/M6elQt
WnbtzA0NhEz8IKvC7E9AZvgejBiB1JoRzZFSiPGYWiBAcXduqTAxAkEAqG24ePhj
esKoF1Us2ViqgJC7zDd96v+LI5eausw3TfKjO4jj5oMoQiyc+hZFxHYlkyZRfA6X
EraF1Rdgngf65w==
-----END PRIVATE KEY-----]] .. '\0', "") == 0)

local md = core_md.context()
assert(md:setup("SHA1", 0) == 0)

assert(md:starts() == 0)
assert(md:update("userID%3D82%26productID%3D1%26productName%3D%E5%85%83%E5%AE%9D%26productDesc%3D%E8%B4%AD%E4%B9%B0100%E5%85%83%E5%AE%9D%26money%3D100%26roleID%3D1%26roleName%3D%E6%B5%8B%E8%AF%95%E8%A7%92%E8%89%B2%E5%90%8D%26serverID%3D10%26serverName%3D%E6%B5%8B%E8%AF%95%26extension%3D1470127680912%26notifyUrl%3Dhttp%3A%2F%2F192.168.1.250%3A8100%2Fu8server%2Fpay%2Fgame7513a2c235647e3213538c6eb329eec9") == 0)
local r, hash = md:finish()
assert(r == 0)
-- print(hash:gsub(".", function(c) return string.format("%02X", string.byte(c)) end))

local r, sign = pk:sign(core_md.MBEDTLS_MD_SHA1, hash, ctr_drbg)
assert(r == 0)
-- print(sign:gsub(".", function(c) return string.format("%02X", string.byte(c)) end))
-- print(core_base64.encode(sign))
assert(core_base64.encode(sign) == "LUEzoht7ehPELct3f7+tQNJXry3HoH0Yme0GMRoN36/8UiMYNmGUq9XcTPLp2IGOIrUtsztnHeRz2XRfYSKrLQjVk6QCmj/NzvdQ1ZXVGDW8jcyIz8Br+yzyRet7Xbm5bjPZsISTauCXWtB7/2TTxZObDwb7+EQ8VnWKvn8bhaA=")


local uri = "userID%3D82%26productID%3D1%26productName%3D%E5%85%83%E5%AE%9D%26productDesc%3D%E8%B4%AD%E4%B9%B0100%E5%85%83%E5%AE%9D%26money%3D100%26roleID%3D1%26roleName%3D%E6%B5%8B%E8%AF%95%E8%A7%92%E8%89%B2%E5%90%8D%26serverID%3D10%26serverName%3D%E6%B5%8B%E8%AF%95%26extension%3D1470127680912%26notifyUrl%3Dhttp%3A%2F%2F192.168.1.250%3A8100%2Fu8server%2Fpay%2Fgame7513a2c235647e3213538c6eb329eec9"
local function decode_func(c)
	return string.char(tonumber(c, 16))
end

local function decode(str)
	local str = str:gsub('+', ' ')
	return str:gsub("%%(..)", decode_func)
end

print(decode(uri))

local function sign(text)
	assert(md:starts() == 0)
	assert(md:update(text) == 0)
	-- assert(md:update("userID%3D82%26productID%3D1%26productName%3D%E5%85%83%E5%AE%9D%26productDesc%3D%E8%B4%AD%E4%B9%B0100%E5%85%83%E5%AE%9D%26money%3D100%26roleID%3D1%26roleName%3D%E6%B5%8B%E8%AF%95%E8%A7%92%E8%89%B2%E5%90%8D%26serverID%3D10%26serverName%3D%E6%B5%8B%E8%AF%95%26extension%3D1470127680912%26notifyUrl%3Dhttp%3A%2F%2F192.168.1.250%3A8100%2Fu8server%2Fpay%2Fgame7513a2c235647e3213538c6eb329eec9") == 0)
	local r, hash = md:finish()
	assert(r == 0)
	-- print(hash:gsub(".", function(c) return string.format("%02X", string.byte(c)) end))

	local r, sign = pk:sign(core_md.MBEDTLS_MD_SHA1, hash, ctr_drbg)
	assert(r == 0)
	-- print(sign:gsub(".", function(c) return string.format("%02X", string.byte(c)) end))
	-- print(core_base64.encode(sign))
	-- assert(core_base64.encode(sign) == "HBTh4olMVOwVGROyHoup1S6TcieZB+WnJvPuld6sZ+NP4bDlzyibk/EqR8QP44lIm8EqlgmnyVRT/ot4+wPWs94tzAXF1yDimazao0iFHBdjx5YyZKgc6sjOyKOF1xQvdsyRt04lj8XDl+RGaaKmJhNkE/d8/aEOE1vAm4pt31c=")
	return core_base64.encode(sign)
end

local function generate_sign()
	-- userID=82&productID=1&productName=元宝&productDesc=购买100元宝&money=100&roleID=1&roleName=测试角色名&serverID=10&serverName=测试&extension=1470127680912&notifyUrl=http://192.168.1.250:8100/u8server/pay/game7513a2c235647e3213538c6eb329eec9	67
	local params = {
		{ "userID", 82 },
		{ "productID", 1 },
		{ "productName", "元宝" },
		{ "productDesc", "购买100元宝" },
		{ "money", 100 },
		{ "roleID", 1 },
		{ "roleName", "测试角色名" },
		{ "serverID", "10" },
		{ "serverName", "测试" },
		{ "extension", "1470127680912" },
		-- 这里是游戏服务器自己的支付回调地址，可以在下单的时候， 传给u8server。
		-- u8server 支付成功之后， 会优先回调这个地址。 如果不传， 则需要在u8server后台游戏管理中配置游戏服务器的支付回调地址
		-- 如果传notifyUrl，则notifyUrl参与签名
		{ "notifyUrl", "http://192.168.1.250:8100/u8server/pay/game" },
	}

	local tokens = {}
	for _,info in pairs(params) do
		local k,v = table.unpack(info)
		table.insert(tokens, string.format("%s=%s", k, v))
	end

	local function escape(s)
		return (string.gsub(tostring(s), "([^A-Za-z0-9_%.])", function(c)
			return string.format("%%%02X", string.byte(c))
		end))
	end

	local text = escape(table.concat(tokens, "&"))
	-- 附加上U8Server后台创建游戏时生成的AppSecret
	local app_secret = "7513a2c235647e3213538c6eb329eec9"
	local sb = text .. app_secret
	print("The encoded get_order_id sb is " .. sb)

	local t = os.clock()
	for i = 1,1000 do
		sign(sb)
	end
	print(os.clock() - t)


	local sign = sign(sb)
	print("The get_order_id sign is " .. sign)
	return params, sign
end
local _,sign = generate_sign()
print(sign)
