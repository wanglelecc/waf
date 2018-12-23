local cc_dict=ngx.shared.cc_dict
local access_ip=ngx.var.remote_addr
local access_uri=ngx.var.uri
local policy_table={
    api_1={
        uri="/test1",
        threshold=20,
        period=2
    },
    api_2={
        uri="/test2",
        threshold=30,
        period=1
    },
    default={
        threshold=10,
        period=1
    }
}

--anti_CC module
local cc_policy_table=nil
for k,v in pairs(policy_table) do
    if v.uri==access_uri then
        cc_policy_table=v
        break
    end
end
if not cc_policy_table then
    cc_policy_table=policy_table["default"]
end
local threshold=cc_policy_table.threshold
local time_period=cc_policy_table.period
local forbidden_ip,status=cc_dict:get("forbidden ip"..access_ip)
if forbidden_ip==1 then
    ngx.exit(ngx.HTTP_FORBIDDEN)
end
local visit_num,status=cc_dict:get(access_ip)
if visit_num then
    if visit_num>=threshold then
        cc_dict:set("forbidden ip"..access_ip,1,10)
        ngx.exit(ngx.HTTP_FORBIDDEN)
    else
        cc_dict:incr(access_ip,1)
    end
else
    cc_dict:set(access_ip,1,time_period)
end
---------------------
作者：csdncqmyg
来源：CSDN
原文：https://blog.csdn.net/csdncqmyg/article/details/75648074
版权声明：本文为博主原创文章，转载请附上博文链接！