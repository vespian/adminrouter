UPSTREAM_MESOS = os.getenv("UPSTREAM_MESOS")
if UPSTREAM_MESOS == nil then
    UPSTREAM_MESOS = "http://leader.mesos:5050"
end
ngx.log(ngx.NOTICE, "Mesos upstream: " .. UPSTREAM_MESOS)

UPSTREAM_MARATHON = os.getenv("UPSTREAM_MARATHON")
if UPSTREAM_MARATHON == nil then
    UPSTREAM_MARATHON = "http://127.0.0.1:8080"
end
ngx.log(ngx.NOTICE, "Marathon upstream: " .. UPSTREAM_MARATHON)
