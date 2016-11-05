-- Loading the auth module in the global Lua VM in the master process is a
-- requirement, so that code is executed under the user that spawns the
-- master process instead of 'nobody' (which workers operate under).
local use_auth = os.getenv("ADMINROUTER_ACTIVATE_AUTH_MODULE")
if use_auth ~= "true" then
    ngx.log(
        ngx.NOTICE,
        "ADMINROUTER_ACTIVATE_AUTH_MODULE not `true`. " ..
        "Using dummy module."
        )
    auth = {}
    auth.validate_jwt_or_exit = function() return end
else
    ngx.log(ngx.NOTICE, "Use auth module.")
    auth = require "common.auth.open"
end
