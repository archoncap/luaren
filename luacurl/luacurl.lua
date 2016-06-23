local crypto = require("crypto")
local hmac = require("crypto.hmac")
local curl = require("luacurl")
local socket = require("socket")
require('base64')

ALOG = {}
TIME_STAMP = nil
LOG_PATH = nil
SAE_LOG_HOST = 'g.sae.sina.com.cn'
SAE_ACCESSKEY = 'XXXXXXXX'
SAE_SECRETKEY = 'XXXXXXXXXXXXXXXXXXXXXXXXX'

function ALOG.request()
    local auth_info = ALOG.get_sec_token()
    local header_info = {
         'Host: '..SAE_LOG_HOST,
         'Accept: text/plain',
         'x-sae-accesskey: '..SAE_ACCESSKEY,
         'x-sae-timestamp: '..TIME_STAMP,
         'Authorization: '..auth_info
     }

    local url = 'http://'..SAE_LOG_HOST..LOG_PATH
    local c = curl.new()
    c:setopt(curl.OPT_URL, url)
    c:setopt(curl.OPT_HEADER, false)
    c:setopt(curl.OPT_HTTPHEADER,       table.concat(header_info,"\n"))
    local t = {}
    c:setopt(curl.OPT_WRITEFUNCTION, function(param, buf)
    table.insert(t, buf)
    return #buf
    end)

    assert(c:perform())
    return table.concat(t)
end

function ALOG.get_sec_token()
    local header = {
     'GET',
     LOG_PATH,
     'x-sae-accesskey:'..SAE_ACCESSKEY,
     'x-sae-timestamp:'..TIME_STAMP,
    }

    data_str = table.concat(header, '\n')
    local ret = 'SAEV1_HMAC_SHA256 '..to_base64(hmac.digest("sha256", data_str,SAE_SECRETKEY,rawequal))
    return ret
end

function ALOG.get_log_info(service, date, ident, fop, format)

    LOG_PATH = '/log/'..service..'/'..date..'/'..ident..'.log'..'?'..fop
    TIME_STAMP = math.ceil(socket.gettime())
    local log_info = ALOG.request()
    return log_info
end

local service = 'http'
local date = '2015-07-31'
local ident='1-access'
local meta = ALOG.get_log_info(service, date, ident, 'head/0/1', true)
print(meta)
return meta
