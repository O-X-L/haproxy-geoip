-- Source: https://github.com/O-X-L/haproxy-geoip
-- Copyright (C) 2025 OXL IT Services / Rath Pascal (contact+geoip@oxl.at)
-- License: MIT

-- NOTE: the ltrim parameter can be used to remove a prefix - like: 'AS1337' => '1337'

local function http_request(lookup, src, ltrim)
    local s = core.tcp()

    local addr = '127.0.0.1'
    local port = 6970

    local hdrs = {
        [1] = string.format('host: %s:%s', addr, port),
        [2] = 'accept: */*',
        [3] = 'connection: close'
    }

    local req = {
        [1] = 'GET /?lookup=' .. lookup .. '&ip=' .. src .. ' HTTP/1.1',
        [2] = table.concat(hdrs, '\r\n'),
        [3] = '\r\n'
    }

    req = table.concat(req, '\r\n')

    s:connect(addr, port)
    s:send(req)
    while true do
        local line = s:receive('*l')
        if not line then break end
        if line == '' then break end
    end
    local res_body = s:receive('*a')
    if res_body == nil then
        return '-'
    end
    return string.sub(res_body, 1 + ltrim, -1)
end

-- examples for MaxMind:

local function lookup_geoip_country(txn)
    country_code = http_request('country.iso_code', txn.f:src(), 0)
    txn:set_var('txn.geoip_country', country_code)
end

local function lookup_geoip_asn(txn)
    asn = http_request('autonomous_system_number', txn.f:src(), 0)
    txn:set_var('txn.geoip_asn', asn)
end

local function lookup_geoip_asname(txn)
    asname = http_request('autonomous_system_organization', txn.f:src(), 0)
    txn:set_var('txn.geoip_asname', asname)
end

-- examples for IPInfo:

local function lookup_geoip_country(txn)
    country_code = http_request('country_code', txn.f:src(), 0)
    txn:set_var('txn.geoip_country', country_code)
end

local function lookup_geoip_asn(txn)
    asn = http_request('asn', txn.f:src(), 2)
    txn:set_var('txn.geoip_asn', asn)
end

local function lookup_geoip_asname(txn)
    asname = http_request('as_name', txn.f:src(), 0)
    txn:set_var('txn.geoip_asname', asname)
end

-- examples for OXL (https://github.com/O-X-L/geoip-asn):

local function lookup_geoip_country(txn)
    -- NOTE: This is not really the IP's country
    country_code = http_request('organization.country', txn.f:src(), 0)
    txn:set_var('txn.geoip_country', country_code)
end

local function lookup_geoip_asn(txn)
    asn = http_request('asn', txn.f:src(), 2)
    txn:set_var('txn.geoip_asn', asn)
end

local function lookup_geoip_asname(txn)
    asname = http_request('organization.name', txn.f:src(), 0)
    txn:set_var('txn.geoip_asname', asname)
end

-- examples end

core.register_action('lookup_geoip_country', {'tcp-req', 'http-req'}, lookup_geoip_country, 0)
core.register_action('lookup_geoip_asn', {'tcp-req', 'http-req'}, lookup_geoip_asn, 0)
core.register_action('lookup_geoip_asname', {'tcp-req', 'http-req'}, lookup_geoip_asname, 0)
