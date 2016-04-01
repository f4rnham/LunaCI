module("lunaci.utils", package.seeall)

local log = require "lunaci.log"

local pl = require "pl.import_into"()
local const = require "rocksolver.constraints"


-- Change working directory.
-- Returns success and previous working directory or failure and error message.
function change_dir(dir_name)
    pl.utils.assert_arg(1, dir_name, "string", pl.path.isdir, "is not an existing directory")

    local prev_dir, err = pl.path.currentdir()
    if not prev_dir then
        return nil, err
    end

    local ok, err = pl.path.chdir(dir_name)
    if ok then
        return ok, prev_dir
    else
        return nil, err
    end
end


-- Execute a command in a given working directory.
-- Returns success/failure, actual return code, stdout and stderr outputs.
function dir_exec(dir, cmd)
    local ok, pwd = change_dir(dir)
    if not ok then error("Could not change directory.") end

    log:debug("Running command: " .. cmd)

    local ok, code, out, err = pl.utils.executeex(cmd)

    local okk = change_dir(pwd)
    if not okk then error("Could not change directory.") end

    return ok, code, out, err
end


function git_clone(source, target)
    log:debug("Cloning repository " .. source)
    local ok, code, out, err = pl.utils.executeex("git clone '" .. source .. "' '" .. pl.path.abspath(target) .. "'")

    return ok, not ok and err or nil
end


sortVersions = const.compareVersions


-- Make path or die.
function force_makepath(path)
    if not pl.path.exists(path) then
        local ok, err = pl.dir.makepath(path)
        if not ok then
            log:error("Cannot create path '%s': %s", path, err)
            os.exit(1)
        end
    end
end


function escape_urlsafe(str)
    return str:gsub("[^a-z0-9_.]+", '-')
end


function escape_html(str)
    return str:find("[<>&'\"]") and str:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("'", "&#39;"):gsub("\"", "&quot;") or str
end
