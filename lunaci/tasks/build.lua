module("lunaci.tasks.build", package.seeall)

local dist = require "dist"
local dist_cfg = require "dist.config"
local reload_log = require "dist.log".reload_config
local pl = require "pl.import_into"()
local config = require "lunaci.config"

local build_package = function(package, target, manifest)
    local msg = [[
%s
stdout: %s
stderr: %s
status: %s
]]

    local tmp_deploy_dir = "../_LuaDist"

    local setup = ([[
rm -rf %s
cp -r ../LuaDist %s
]]):format(tmp_deploy_dir, tmp_deploy_dir)

    local skip_msg = {
        "not found in provided repositories",
        "Unhandled rockspec build type",
        "Unsupported platform %(your platform is not in list of supported platforms%)",
        "Unsupported platform %(your platform was explicitly marked as not supported%)",
    }

    local ce_msg = {
        "error: array type has incomplete element type ‘struct luaL_reg’",
        "error: unknown type name ‘luaL_reg’",
    }

    local ke_msg = {
        "Cound not load rockspec for package .* unexpected symbol near '='",
        "attempt to concatenate field 'type' %(a nil value%)",
    }

    -- External dependency
    -- fatal error: libpq-fe.h: No such file or directory

    local function check_messages(log, messages)
        for _, msg in pairs(messages) do
            if log:find(msg) ~= nil then
                return true
            end
        end

        return false
    end

    local ok, status, stdout, stderr = pl.utils.executeex(setup)

    if not ok then
        return config.STATUS_INT, msg:format("Luadist setup failed", stdout, stderr, status), false
    end

    -- Disable log file and setup custom logging callback
    dist_cfg.write_log_level = nil
    local dist_log = ""
    reload_log(function(level, message)
        dist_log = dist_log .. level .. " " .. message .. "\n"
    end)
    local ok, dist_err, status = dist.install(tostring(package), tmp_deploy_dir)

    if ok then
        return config.STATUS_OK, dist_log, true
    else
        if check_messages(dist_err, skip_msg) then
            return config.STATUS_SKIP, dist_err, false
        end

        if check_messages(dist_err, ce_msg) then
            return config.STATUS_CE, dist_err, false
        end

        if check_messages(dist_err, ke_msg) then
            return config.STATUS_KE, dist_err, false
        end

        -- If dist.install failed on other than tested package (most likely dependency)
        if status == 5 then
            return config.STATUS_DEP_F, dist_err, false
        end

        return config.STATUS_FAIL, dist_err, false
    end
end


return build_package
