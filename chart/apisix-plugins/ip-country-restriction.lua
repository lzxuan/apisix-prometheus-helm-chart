local require = require
local ipairs = ipairs
local core = require "apisix.core"
local maxminddb = require "apisix.plugins.maxminddb"


local cache = core.lrucache.new({ttl = 300, count = 1024})


local plugin_name = "ip-country-restriction"


local schema = {
    type = "object",
    properties = {
        rules = {
            type = "array",
            items = {
                type = "object",
                properties = {
                    ip_list = {
                        type = "array",
                        items = {anyOf = core.schema.ip_def},
                        minItems = 1,
                        uniqueItems = true,
                    },
                    country_list = {
                        type = "array",
                        items = {type = "string", pattern = "^[A-Z]{2}$"},
                        minItems = 1,
                        uniqueItems = true,
                    },
                    allowed = {
                        type = "boolean",
                    },
                },
                oneOf = {
                    {required = {"ip_list", "allowed"}},
                    {required = {"country_list", "allowed"}},
                },
            },
            minItems = 1,
            uniqueItems = true,
        },
        default_allowed = {
            type = "boolean",
        },
        blocked_body = {
            type = "string",
            default = "Forbidden",
        },
    },
    required = {"rules", "default_allowed"},
}


local _M = {
    version = 0.1,
    priority = 3001,
    name = plugin_name,
    schema = schema,
}


function _M.check_schema(conf)
    local ok, err = core.schema.check(schema, conf)

    if not ok then
        return false, err
    end

    -- We still need this as it is too complex to filter out all invalid IPv6
    -- via regex.
    for _, rule in ipairs(conf.rules) do
        if rule.ip_list then
            for _, cidr in ipairs(rule.ip_list) do
                if not core.ip.validate_cidr_or_ip(cidr) then
                    return false, "invalid ip address: " .. cidr
                end
            end
        end
    end

    return true
end


local function to_set(list)
    local set = {}
    for _, l in ipairs(list) do
        set[l] = true
    end
    return set
end


function _M.access(conf, ctx)
    local allowed = conf.default_allowed
    local remote_addr = ctx.var.remote_addr

    for _, rule in ipairs(conf.rules) do
        if rule.ip_list then
            local matcher = cache(rule.ip_list, nil, core.ip.create_ip_matcher,
                                  rule.ip_list)
            if matcher:match(remote_addr) then
                allowed = rule.allowed
                break
            end

        elseif rule.country_list then
            local country = maxminddb.get_country(remote_addr)
            if country then
                local country_set = cache(rule.country_list, nil, to_set,
                                          rule.country_list)
                if country_set[country] then
                    allowed = rule.allowed
                    break
                end
            end
        end
    end

    if not allowed then
        return 403, conf.blocked_body
    end
end


return _M
