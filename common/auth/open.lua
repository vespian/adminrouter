local util = require "common.util"
local authcommon = require "common.auth.common"

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


-- Expose interface.
local _M = {}
_M.validate_jwt_or_exit = validate_jwt_or_exit


return _M
