-- WARNING: UNTESTED!

-- use with: https://raw.githubusercontent.com/anjia0532/lua-resty-maxminddb/master/lib/resty/maxminddb.lua

-- for data schema see:
--   ipinfo: https://github.com/ipinfo/sample-database
--   maxmind: https://github.com/maxmind/MaxMind-DB/tree/main/source-data

local file_geoip_country = '/tmp/country.mmdb'
local file_geoip_city = '/tmp/city.mmdb'
local file_geoip_asn = '/tmp/asn.mmdb'
local query_lang = 'en'

local geoDB_country = require 'maxminddb'
local geoDB_city = require 'maxminddb'
local geoDB_asn = require 'maxminddb'

local function query_db(src, geoDB)
    local res,err = geoDB.lookup(src)
    core.Alert(res)
    if not res then
        return {}
    end
    return res
end

local function query_db_country(src)
    if not geoDB_country.initted() then
        geoDB_country.init(file_geoip_country)
    end
    return query_db(src, geoDB_country)
end

local function query_db_city(src)
    if not geoDB_city.initted() then
        geoDB_city.init(file_geoip_city)
    end
    return query_db(src, geoDB_city)
end

local function query_db_asn(src)
    if not geoDB_asn.initted() then
        geoDB_asn.init(file_geoip_asn)
    end
    return query_db(src, geoDB_asn)
end

local function lookup_geoip_country_base(txn, data)
    -- ipinfo.io
    txn:set_var('txn.geoip_continent', data['country'] or '00')
    -- maxmind
    -- txn:set_var('txn.geoip_continent', data['country']['iso_code'] or '00')
end

local function lookup_geoip_country(txn)
    data = query_db_country(txn.f:src())
    lookup_geoip_country_base(txn, data)
end

local function lookup_geoip_continent_base(txn, data)
    -- ipinfo.io
    txn:set_var('txn.geoip_continent', data['continent'] or '00')
    -- maxmind
    -- txn:set_var('txn.geoip_continent', data['continent']['code'] or '00')
    --   OR
    -- txn:set_var('txn.geoip_continent', data['continent']['names'][query_lang] or '00')
end

local function lookup_geoip_continent(txn)
    data = query_db_country(txn.f:src())
    lookup_geoip_continent_base(txn, data)
end

local function lookup_geoip_city_base(txn, data)
    -- ipinfo.io
    txn:set_var('txn.geoip_city', data['city'] or '-')
    -- maxmind
    -- txn:set_var('txn.geoip_city', data['city']['names'][query_lang] or '-')
end

local function lookup_geoip_city(txn)
    data = query_db_city(txn.f:src())
    lookup_geoip_city_base(txn, data)
end

local function lookup_geoip_country_all(txn)
    data = query_db_country(txn.f:src())
    lookup_geoip_country_base(txn, data)
    lookup_geoip_continent_base(txn, data)
end

local function lookup_geoip_city_all(txn)
    -- p.e. maxmind 'city' database includes all those infos
    data = query_db_city(txn.f:src())
    lookup_geoip_country_base(txn, data)
    lookup_geoip_continent_base(txn, data)
    lookup_geoip_city_base(txn, data)
end

local function lookup_geoip_asn_base(txn, data)
    -- ipinfo
    txn:set_var('txn.geoip_asn', data['asn'] or '0')
    -- maxmind
    -- txn:set_var('txn.geoip_asn', data['autonomous_system_number'] or '0')
end

local function lookup_geoip_asn(txn)
    data = query_db_asn(txn.f:src())
    lookup_geoip_asn_base(txn, data)
end

local function lookup_geoip_asname_base(txn, data)
    -- ipinfo
    txn:set_var('txn.geoip_asname', data['name'] or '-')
    -- maxmind
    -- txn:set_var('txn.geoip_asn', data['autonomous_system_organization'] or '-')
end

local function lookup_geoip_asname(txn)
    data = query_db_asn(txn.f:src())
    lookup_geoip_asname_base(txn, data)
end

core.register_action('lookup_geoip_country', {'tcp-req', 'http-req'}, lookup_geoip_country, 0)
core.register_action('lookup_geoip_continent', {'tcp-req', 'http-req'}, lookup_geoip_continent, 0)
core.register_action('lookup_geoip_city', {'tcp-req', 'http-req'}, lookup_geoip_city, 0)
core.register_action('lookup_geoip_asn', {'tcp-req', 'http-req'}, lookup_geoip_asn, 0)
core.register_action('lookup_geoip_asname', {'tcp-req', 'http-req'}, lookup_geoip_asname, 0)
