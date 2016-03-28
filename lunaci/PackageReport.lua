module("lunaci.PackageReport", package.seeall)

local config = require "lunaci.config"
local log = require "lunaci.log"

local pl = require "pl.import_into"()
local const = require "rocksolver.constraints"


local PackageReport = {}
PackageReport.__index = PackageReport

setmetatable(PackageReport, {
    __call = function (class, ...)
        return class.new(...)
    end,
})


function PackageReport.new(name)
    local self = setmetatable({}, PackageReport)

    self.name = name
    self.outputs = {}

    return self
end


function PackageReport:add_output(package, target, task, success, output)
    local version = tostring(package.version)

    local outputs = self:get_output_location(package, version, target)
    table.insert(outputs, {name = task.name, success = success, output = output})
end


function PackageReport:get_output_location(package, version, target)
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
    return pl.tablex.sort(self.outputs, const.compareVersions)
end

function PackageReport:get_version(ver)
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
