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
    local ok, dist_err, bad_pkg = dist.install(tostring(package), tmp_deploy_dir)

    if ok then
        return config.STATUS_OK, dist_log, true
    else
        for _, msg in pairs(skip_msg) do
            if dist_err:find(msg) ~= nil then
                return config.STATUS_SKIP, dist_err, false
            end
        end

        -- If dist.install failed on other than tested package (most likely dependency)
        if bad_pkg and bad_pkg.name ~= package.name then
            return config.STATUS_DEP_F, dist_err, false
        end

        return config.STATUS_FAIL, dist_err, false
    end
end


return build_package
