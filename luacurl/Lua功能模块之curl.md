作者：糖果

Curl是一个WEB开发常用的工具，直接用官网的翻译

curl是一个开源的命令行工具，也是一个库，用于传输URL语法的工具，支持DICT, FILE, FTP, FTPS, Gopher, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS, POP3, POP3S, RTMP, RTSP, SCP, SFTP, SMB, SMTP, SMTPS, Telnet and TFTP等。

在lua中，curl就是以库的形式存在的，安装过程比较简单：sudo luarocks install luacurl。

另外，curl还是支持代理的方式访问主机，这个很有用，之后会用一个模拟DDOS攻击程序说明他的用处。

这一次，我们用一个和SAE云平台相关的机能，说明pycurl的使用。

简单的说明一下，SAE云平台是国内较早的云开开放平台之一，经过多年的积累，有广大的用户基础，提供便利的开发平台，最近开放了一个实时LOG查询功能。用户可以通过其对外开放的REST API，查询自己运行在云平台上的APP产出的LOG。

文档说明：

接入流程概述：

1.计算取得安全签名 。

2.向指定URL发送HTTP的GET请求，请求之前要根据官网的文档要求，填充HTTP header信息，如果没有准备的填充信息，会被视为无效请求。

3.取得返回的LOG信息，如果需要还可以对，返回LOG进行显示格式化。

技术栈：

依赖关联，此模块使用了几个常用的LUA库：

crypto：加密包，用于sha256运算。

base64:base64格式的转换处理。

crypto,base64在之前的章节有过介绍。

luacurl：HTTP工具包，此处用于向服务器发送HTTP请求。

socket：luasocket是调用socket api的，但此程序只是用于取得系统时间，用作当时间戳。

另外，国内的云风老师，因为觉得luasocket过于大了，不是很喜欢（QQ群里他自己说的...），他又写了一个lsocket，可以在github中找到，lsocket有一个sample,是使用lsocket实现了一个Http Server。

多说一句，Lua的库不像python或是php等语言，Lua的很多库都是第三方个人实现的，需要一个寻找和甄别的过程，使用之前，确认一下也很必要。

下面是具体的代码：



```lua
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
```


在云平台上可以运行，python,php,python的脚本。目前是不支持lua的，以后是否支持不得而知。

因为将一个系统，分解成不同的子系统，一部分的功能是用lua实现，一部分的功能是用python实现，而系统之间的通信使用RPC通信，由lua端向python发送RPC，服务器端再接收RPC接收，必然会产生LOG。我们就在log端将实时的log取出，分析执行过程，这就是这段代码的意义。

关于Pycurl使用代理的案例，之后单起一篇说明，另外会将C实现代码的关键截取出来说明上层LUA与底层代码的功能。



PS:转载到其它平台请注明作者姓名及原文链接。
