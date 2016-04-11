module("lunaci.tasks.build", package.seeall)

math.randomseed(os.time())

local build_package = function(package, target, manifest)
    local config = require "lunaci.config"
    err_msg = ([[
Building package %s...
Error building: Something wrong happend.
This is just a placeholder text here to make it longer.
]]):format(tostring(package))

    succ_msg = ([[
Building package %s...

Resolving dependencies... Done.
Installing dependencies... Done.
All dependencies installed successfully.

Executing CMake... Done.

Package build successful.
]]):format(tostring(package))

    rand = math.random(10)
    if rand <= 3 then
        return config.STATUS_FAIL, err_msg, false
    elseif rand < 5 then
        return config.STATUS_INT, err_msg, false
    else
        return config.STATUS_OK, succ_msg, true
    end

end


return build_package
