module("lunaci.tasks.require", package.seeall)

local pl = require "pl.import_into"()
local config = require "lunaci.config"

local require_modules = function(package, target, manifest)
    msg = [[
%s
stdout: %s
stderr: %s
status: %s
]]

    local ok, status, stdout, stderr = pl.utils.executeex("../_LuaDist/bin/lua -e 'print(require \"" .. package.name .. "\")'")
    if ok then
        return config.STATUS_OK, msg:format("OK " .. tostring(package), stdout, stderr, status), true
    else
        return config.STATUS_FAIL, msg:format("FAIL " .. tostring(package), stdout, stderr, status), false
    end
end


return require_modules
