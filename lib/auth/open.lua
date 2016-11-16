local util = require "util"
local authcommon = require "auth.common"

local SECRET_KEY = nil

local key_file_path = os.getenv("SECRET_KEY_FILE_PATH")
if key_file_path == nil then
    ngx.log(ngx.WARN, "SECRET_KEY_FILE_PATH not set.")
else
    ngx.log(ngx.NOTICE, "Reading secret key from `" .. key_file_path .. "`.")
    SECRET_KEY = util.get_stripped_first_line_from_file(key_file_path)
    if (SECRET_KEY == nil or SECRET_KEY == '') then
        -- Normalize to nil, for simplified subsequent per-request check.
        SECRET_KEY = nil
        ngx.log(ngx.WARN, "Secret key not set or empty string.")
    end
end


local function validate_jwt_or_exit()
    uid, err = authcommon.validate_jwt(SECRET_KEY)
    if err == 401 then
        return authcommon.exit_401("oauthjwt")
    end

    res = ngx.location.capture("/acs/api/v1/users/" .. uid)
    if res.status ~= ngx.HTTP_OK then
        ngx.log(ngx.ERR, "User not found: `" .. uid .. "`")
        return authcommon.exit_401()
    end
    return uid
end

-- Initialise and return the module:
local _M = {}
function _M.init(use_auth)
    local res = {}

    if use_auth ~= "true" then
        ngx.log(
            ngx.NOTICE,
            "ADMINROUTER_ACTIVATE_AUTH_MODULE not `true`. " ..
            "Using dummy module."
            )
        res.validate_jwt_or_exit = function() return end
    else
        ngx.log(ngx.NOTICE, "Use auth module.");
        res.validate_jwt_or_exit = validate_jwt_or_exit
    end

    res.access_agent_endpoint = function()
        return res.validate_jwt_or_exit()
    end

    res.access_acsapi_endpoint = function()
        return res.validate_jwt_or_exit()
    end

    res.access_lashupkey_endpoint = function()
        return res.validate_jwt_or_exit()
    end

    res.access_service_endpoint = function()
        return res.validate_jwt_or_exit()
    end

    res.access_metadata_endpoint = function()
        return res.validate_jwt_or_exit()
    end

    res.access_historyservice_endpoint = function()
        return res.validate_jwt_or_exit()
    end

    res.access_mesosdns_endpoint = function()
        return res.validate_jwt_or_exit()
    end

    res.access_systemhealth_endpoint = function()
        return res.validate_jwt_or_exit()
    end

    res.access_pkgpanda_endpoint = function()
        return res.validate_jwt_or_exit()
    end

    return res
end

return _M
