module("lunaci.Worker", package.seeall)

local log = require "lunaci.log"
local PackageReport = require "lunaci.PackageReport"

local const = require "rocksolver.constraints"
local Package = require "rocksolver.Package"

local pl = require "pl.import_into"()


local Worker = {}
Worker.__index = Worker

setmetatable(Worker, {
    __call = function (class, ...)
        return class.new(...)
    end,
})

function Worker.new(name, versions, manifest)
    local self = setmetatable({}, Worker)

    self.package_name = name
    self.package_versions = versions
    self.manifest = manifest
    self.report = PackageReport(name)

    return self
end


function Worker:run(targets, tasks)
    for version, spec in pl.tablex.sort(self.package_versions, const.compareVersions) do
        local package = Package(self.package_name, version, spec)

        for _, target in pairs(targets) do
            self:run_target(package, target, tasks)
        end
    end
end


function Worker:run_target(package, target, tasks)
    local continue = true
    for _, task in pairs(tasks) do
        if not continue then
            self.report:add_output(package, target, task, nil, "Task chain ended.")
        else
            local ok, success, output, cont = pcall(task.call, package, target, self.manifest)

            if ok then
                -- Task run without runtime errors
                self.report:add_output(package, target, task, success, output)

                -- Task finished unsuccessfully - task chain should end
                if not cont then
                    continue = false
                end
            else
                -- Runtime error while running the task
                local msg = "Error running task: " .. success -- success contains lua error message
                log:error(msg)
                self.report:add_output(package, target, task, nil, msg)
            end
        end
    end
end


function Worker:get_report()
    return self.report
end


return Worker
