module("lunaci.utils", package.seeall)

local log = require "lunaci.log"

local pl = require "pl.import_into"()


-- Change working directory.
-- Returns success and previous working directory or failure and error message.
function change_dir(dir_name)
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
