module("lunaci.tasks.require", package.seeall)

math.randomseed(os.time())


-- Dummy random placeholder task implementation.
local require_modules = function(package, target, manifest)
    local config = require "lunaci.config"
    err_msg = ([[
Trying to require modules from package %s...
Error: Something wrong happend.
This is just a placeholder text here to make it longer.
]]):format(tostring(package))

    succ_msg = ([[
Trying to require modules from package %s...
All modules required successfully.

Require test successful.
]]):format(tostring(package))

    rand = math.random(10)
    if rand < 4 then
        return config.STATUS_FAIL, err_msg, false
    else
        return config.STATUS_OK, succ_msg, true
    end

end


return require_modules
