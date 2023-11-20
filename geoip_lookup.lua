
local function http_request(lookup, src)
    local s = core.tcp()
    s:connect("127.0.0.1:6970")
    s:send("GET /?lookup=" .. lookup .. "&ip=" .. src .. " HTTP/1.1\r\n\r\n")
    while true do
        local line = s:receive('*l')
        if not line then break end
        if line == '' then break end
    end
    local res_body = s:receive('*a')
    if res_body == nil then
        return "00"
    end
    return res_body
end

local function lookup_geoip_country(txn)
    country_code = http_request("country", txn.f:src())
    txn:set_var('txn.geoip_country', country_code)
    
end

local function lookup_geoip_continent(txn)
    continent_code = http_request("continent", txn.f:src())
    txn:set_var('txn.geoip_continent', continent_code)
end

local function lookup_geoip_asn(txn)
    asn = http_request("asn", txn.f:src())
    txn:set_var('txn.geoip_asn', asn)
end

local function lookup_geoip_asname(txn)
    asname = http_request("asname", txn.f:src())
    txn:set_var('txn.geoip_asname', asname)
end

core.register_action('lookup_geoip_country', {'tcp-req', 'http-req'}, lookup_geoip_country, 0)
core.register_action('lookup_geoip_continent', {'tcp-req', 'http-req'}, lookup_geoip_continent, 0)
core.register_action('lookup_geoip_asn', {'tcp-req', 'http-req'}, lookup_geoip_asn, 0)
core.register_action('lookup_geoip_asname', {'tcp-req', 'http-req'}, lookup_geoip_asname, 0)
