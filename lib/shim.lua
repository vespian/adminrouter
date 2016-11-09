local util = require "common.util"
local agent = require 'master.agent.common';

local shim = {}
local auth = {}

local use_auth = os.getenv("ADMINROUTER_ACTIVATE_AUTH_MODULE")
if use_auth ~= "true" then
    ngx.log(
        ngx.NOTICE,
        "ADMINROUTER_ACTIVATE_AUTH_MODULE not `true`. " ..
        "Using dummy module."
        )
    auth.validate_jwt_or_exit = function() return end
else
    ngx.log(ngx.NOTICE, "Use auth module.")
    auth = require "lib.auth.ee"
end

local function shim.request(url)
    return util.request(url, {});
end

local function shim.access_agent_endpoint()
    return auth.validate_jwt_or_exit()
end

local function shim.set_agent_addr()
    return agent.set_agent_addr("http://");
end

local function shim.access_acsapi_endpoint()
    return auth.validate_jwt_or_exit()
end

local function shim.access_lashupkey_endpoint()
    return auth.validate_jwt_or_exit()
end

local function shim.access_service_endpoint()
    return auth.validate_jwt_or_exit()
end

local function shim.access_metadata_endpoint()
    return auth.validate_jwt_or_exit()
end

local function shim.access_historyservice_endpoint()
    return auth.validate_jwt_or_exit()
end

local function shim.access_mesosdns_endpoint()
    return auth.validate_jwt_or_exit()
end

local function shim.access_systemhealth_endpoint()
    return auth.validate_jwt_or_exit()
end

local function shim.access_pkgpanda_endpoint()
    return auth.validate_jwt_or_exit()
end

return shim
