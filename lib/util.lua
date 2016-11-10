local cjson_safe = require "cjson.safe"
local http = require "resty.http"

local util = {}


function util.get_stripped_first_line_from_file(path)
    -- Return nil when file is emtpy.
    -- Return nil open I/O error.
    -- Log I/O error details.
    local f, err = io.open(path, "rb")
    if f then
        -- *l read mode: read line skipping EOL, return nil on end of file.
        local line = f:read("*l")
        f:close()
        if line then
            return line:strip()
        end
        ngx.log(ngx.ERR, "File is empty: " .. path)
        return nil
    end
    ngx.log(ngx.ERR, "Error reading file `" .. path .. "`: " .. err)
    return nil
end


function util.get_file_content(path)
    local f, err = io.open(path, "rb")
    if f then
        -- *a read mode: read entire file.
        local content = f:read("*a")
        f:close()
        return content
    end
    ngx.log(ngx.ERR, "Error reading file `" .. path .. "`: " .. err)
    return nil
end


-- Monkey-patch string table.

function string:split(sep)
    local sep, fields = sep or " ", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end


function string.startswith(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end


function string:strip()
    -- Strip leading and trailing whitespace.
    -- Ref: http://lua-users.org/wiki/StringTrim
    return self:match "^%s*(.-)%s*$"
end


function util.request(url, headers)
    -- Use cosocket-based HTTP library, as ngx subrequests are not available
    -- from within this code path (decoupled from nginx' request processing).
    -- The timeout parameter is given in milliseconds. The `request_uri`
    -- method takes care of parsing scheme, host, and port from the URL.
    local httpc = http.new()
    httpc:set_timeout(10000)
    local res, err = httpc:request_uri(url, {
        method="GET",
        headers=headers,
        ssl_verify=true
    })

    if not res then
        ngx.log(ngx.ERR, "Failed to request " .. url .. ": " .. err)
        return nil, err
    end

    if res.status ~= 200 then
        return nil, "Invalid response status: " .. res.status
    end

    ngx.log(
        ngx.NOTICE,
        "Request url: " .. url ..
        " -- Response Body length: " .. string.len(res.body) .. " bytes."
        )

    return res, nil
end


function util.mesos_dns_get_srv(framework_name)
    local res = ngx.location.capture(
        "/mesos_dns/v1/services/_" .. framework_name .. "._tcp.marathon.mesos")

    if res.truncated then
        -- Remote connection dropped prematurely or timed out.
        ngx.log(ngx.ERR, "Request to Mesos DNS failed.")
        return nil
    end
    if res.status ~= 200 then
        ngx.log(ngx.ERR, "Mesos DNS response status: " .. res.status)
        return nil
    end

    local records, err = cjson_safe.decode(res.body)
    if not records then
        ngx.log(ngx.ERR, "Cannot decode JSON: " .. err)
        return nil
    end
    return records
end


return util
