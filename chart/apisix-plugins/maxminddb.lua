local require = require
local ngx = require "ngx"
local core = require "apisix.core"
local mmdb = require "geoip.mmdb"
local shell = require "resty.shell"


local mmdb_load_database = mmdb.load_database
local shell_run = shell.run
local ngx_update_time = ngx.update_time
local ngx_time = ngx.time
local ngx_timer_at = ngx.timer.at
local ngx_worker_id = ngx.worker.id
local ngx_worker_count = ngx.worker.count


local GEOLITE2_DB_PATH = "/usr/local/share/GeoIP/GeoLite2-Country.mmdb"
local GEOIPUPDATE_PATH = "/usr/local/bin/geoipupdate"
local GEOIPUPDATE_RUN_TIME = 79200 -- everyday 22:00 UTC


local timer_on = false
local maxminddb = nil
local maxminddb_mod_time = nil
local cache = core.lrucache.new({ttl = 3600, count = 102400})


local plugin_name = "maxminddb"


local schema = {
    type = "object",
    properties = {},
}


local _M = {
    version = 0.1,
    priority = 15000,
    name = plugin_name,
    schema = schema,
    scope = "global",
}


function _M.check_schema(conf)
    local ok, err = core.schema.check(schema, conf)

    if not ok then
        return false, err
    end

    return true
end


local function get_maxminddb_mod_time()
    local command = "stat -c %Y " .. GEOLITE2_DB_PATH
    local ok, stdout, stderr, reason, status = shell_run(command)
    if not ok then
        return nil, "Failed to run shell command: " .. command
                    .. ", stdout: " .. stdout .. ", stderr: " .. stderr
                    .. ", reason: " .. reason .. ", status: " .. status
    end

    return stdout
end


local function load_maxminddb()
    local m, err = mmdb_load_database(GEOLITE2_DB_PATH)
    if not m then
        return false, "Failed to load GeoLite2 database: " .. err
    end
    maxminddb = m
    return true
end


local function check_and_load_maxminddb()
    local mod_time, err1 = get_maxminddb_mod_time()
    if not mod_time then
        core.log.crit("Failed to get GeoLite2 database modification time: ",
                      err1)
    end

    if maxminddb_mod_time == mod_time then
        core.log.notice("GeoLite2 database is up-to-date, no need reload.")
        return
    end

    if maxminddb then
        core.log.notice("GeoLite2 database has update, reload.")
    else
        core.log.notice("GeoLite2 database has not been loaded before, load.")
    end

    local ok, err2 = load_maxminddb()
    if not ok then
        core.log.crit("Failed to load GeoLite2 database: ", err2)
        return
    end

    core.log.notice("Successful to load GeoLite2 database.")
    maxminddb_mod_time = mod_time
end


local function get_geoipupdate_delay()
    ngx_update_time()
    local delay = GEOIPUPDATE_RUN_TIME - ngx_time() % 86400
    return delay > 0 and delay or delay + 86400
end


local function run_geoipupdate()
    local command = GEOIPUPDATE_PATH .. " -v"
    local ok, stdout, stderr, reason, status = shell_run(command)
    if not ok then
        return false, "Failed to run shell command: " .. command
                      .. ", stdout: " .. stdout .. ", stderr: " .. stderr
                      .. ", reason: " .. reason .. ", status: " .. status
    end

    -- geoipupdate -v outputs to stderr as of version 4.9.0.
    core.log.notice(stderr)

    return true
end


local function update_maxminddb()
    -- Plugin destroyed, return and stop creating timer for next recursive call.
    if not timer_on then
        return
    end

    -- Create timer for next recursive call.
    local delay = get_geoipupdate_delay()
    local ok1, err1 = ngx_timer_at(delay, update_maxminddb)
    if ok1 then
        core.log.notice("Next maxminddb update in ", delay, "s.")
    else
        core.log.crit("Failed to create timer for next maxminddb update: ",
                      err1)
    end

    -- Check and load maxminddb after 30 seconds, wait for geoipupdate to
    -- complete first.
    local ok2, err2 = ngx_timer_at(30, check_and_load_maxminddb)
    if not ok2 then
        core.log.crit("Failed to create timer to check and load maxminddb in 30s: ",
                      err2)
        return
    end
    core.log.notice("Successful to create timer to check and load maxminddb in 30s.")

    -- Only run geoipupdate on the last worker, as it will most likely receive
    -- the least traffic.
    if ngx_worker_id() == ngx_worker_count() - 1 then
        local ok3, err3 = run_geoipupdate()
        if not ok3 then
            core.log.crit("Failed to run geoipupdate: ", err3)
            return
        end
    end
end


function _M.init()
    -- Enable creating recursive timer to call update_maxminddb().
    timer_on = true

    -- Avoid error: "API disabled in the context of init_worker_by_lua*".
    -- NOTE: resty.shell could not be executed in init_worker_by_lua* context.
    local ok, err = ngx_timer_at(0, update_maxminddb)
    if not ok then
        core.log.crit("Failed to start timer to update maxminddb in 0s: ", err)
        return
    end

    core.log.notice("Successful to start timer to update maxminddb in 0s.")
end


function _M.destroy()
    -- Disable creating recursive timer to call update_maxminddb().
    timer_on = false

    core.log.notice("Successful to stop timer for updating maxminddb.")
end


local function get_country(ip)
    if not maxminddb then
        check_and_load_maxminddb()
    end

    local country, err = maxminddb:lookup_value(ip, "country", "iso_code")
    if not country then
        core.log.error("Failed to lookup country by IP (", ip, "): ", err)
        return false -- Return false to allow caching (nil will not be cached).
    end
    return country
end


function _M.get_country(ip)
    return cache(ip, nil, get_country, ip)
end


return _M
