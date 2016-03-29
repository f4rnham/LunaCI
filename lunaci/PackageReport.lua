module("lunaci.PackageReport", package.seeall)

local log = require "lunaci.log"
local utils = require "lunaci.utils"

local pl = require "pl.import_into"()


local PackageReport = {}
PackageReport.__index = PackageReport
setmetatable(PackageReport, {
__call = function(self, name)
    pl.utils.assert_string(1, name)
    local self = setmetatable({}, PackageReport)
    self.name = name
    self.outputs = {}
    return self
end
})


function PackageReport:add_output(package, target, task, success, output)
    pl.utils.assert_arg(1, package, "table")
    pl.utils.assert_string(2, target)
    pl.utils.assert_arg(3, task, "table")
    pl.utils.assert_string(5, output)

    local version = tostring(package.version)

    local outputs = self:get_output_location(package, version, target)
    table.insert(outputs, {name = task.name, success = success, output = output})
end


function PackageReport:get_output_location(package, version, target)
    pl.utils.assert_arg(1, package, "table")
    pl.utils.assert_string(2, version)
    pl.utils.assert_string(3, target)

    if not self.outputs[version] then
        self.outputs[version] = {
            name = package.name,
            version = tostring(package.version),
            package = package,
            -- timestamp = os.time(),
            targets = {}
        }
    end
    if not self.outputs[version].targets[target] then
        self.outputs[version].targets[target] = {}
    end
    return self.outputs[version].targets[target]
end

function PackageReport:get_output()
    return pl.tablex.sort(self.outputs, utils.sortVersions)
end

function PackageReport:get_version(ver)
    pl.utils.assert_string(1, ver)

    return self.outputs[ver]
end

function PackageReport:get_latest()
    local version
    for _, ver in self:get_output() do
        version = ver
        break
    end

    return version
end



return PackageReport
