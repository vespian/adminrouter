local util = require "common.util"
local agent = require 'master.agent.common';
local auth = require 'common.auth.ee';

local shim = {}

local function shim.request(url)
    return util.request(url, {});
end

local function shim.access_agent_endpoint()
    return auth.check_acl_or_exit("dcos:adminrouter:ops:slave");
end

local function shim.set_agent_addr()
    return agent.set_agent_addr(DEFAULT_SCHEME);
end

local function shim.access_acsapi_endpoint()
    return auth.check_acl_or_exit("dcos:adminrouter:acs");
end

local function shim.access_lashupkey_endpoint()
    -- Note(JP): this ACL is not actually checked.
    -- Currently allowed for all authenticated users.
    local object = "dcos:adminrouter:navstar-lashup-key"
    local action = "full"
    local uid = auth.validate_jwt_or_exit(object, action)
    local auditlogparms = {
        uid = uid,
        object = object,
        action = action,
        result = "allow",
        reason = "authenticated (all users are allowed to access)"
        }
    auth.auditlog(auditlogparms)
end

local function shim.access_service_endpoint()
    local resourceid = "dcos:adminrouter:service:" .. ngx.var.serviceid
    return auth.check_acl_or_exit(resourceid);
end

local function shim.access_metadata_endpoint()
    return auth.check_acl_or_exit("dcos:adminrouter:ops:metadata");
end

local function shim.access_historyservice_endpoint()
    return auth.check_acl_or_exit("dcos:adminrouter:ops:historyservice");
end

local function shim.access_mesosdns_endpoint()
    return auth.check_acl_or_exit("dcos:adminrouter:ops:mesos-dns");
end

local function shim.access_systemhealth_endpoint()
    return auth.check_acl_or_exit("dcos:adminrouter:ops:system-health");
end

local function shim.access_pkgpanda_endpoint()
    return auth.check_acl_or_exit("dcos:adminrouter:ops:pkgpanda");
end

return shim
