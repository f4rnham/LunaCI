module("lunaci.Worker", package.seeall)

local log = require "lunaci.log"

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
    self.output = {}

    return self
end


function Worker:run(targets, tasks)
    -- TODO run on all versions
    local ver, spec = self:get_latest_version()
    local package = Package(self.package_name, ver, spec)
    log:info("Processing version '%s'", package)

    for _, target in pairs(targets) do
        self.output[target] = {}

        log:info("Running target '%s %s'", target.name, target.version)
        self:run_target(package, target, tasks)
    end
end


function Worker:run_target(package, target, tasks)
    for _, task in pairs(tasks) do
        log:info("Executing task '%s'", task.name)
        local ok, res, out, cont = pcall(task.call, package, target, self.manifest)
        if ok then
            self:add_output(target, task, res, out)

            log:debug("Task result: %s\nOutput: \n%s", res, out)
            if not cont then
                log:warn("Stopping task chain")
                break
            end
        else
            local msg = "Error running task: " .. res
            log:error(msg)
            self:add_output(target, task, "N/A", msg)
        end
    end
end


function Worker:get_latest_version()
    local version, spec
    for v, s in pl.tablex.sort(self.package_versions, const.compareVersions) do
        version, spec = v, s
        break
    end

    return version, spec
end


function Worker:add_output(target, task, res, out)
    self.output[target][task.name] = {res, out}
end


function Worker:get_output()
    return self.output
end


return Worker
