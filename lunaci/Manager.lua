module("lunaci.Manager", package.seeall)

local log = require "lunaci.log"
local Worker = require "lunaci.Worker"

local pl = require "pl.import_into"()

local const = require "rocksolver.constraints"


local Manager = {}
Manager.__index = Manager

setmetatable(Manager, {
    __call = function (class, ...)
        return class.new(...)
    end,
})

function Manager.new(manifest, targets, generator)
    local self = setmetatable({}, Manager)

    self.manifest = manifest
    self.targets = targets or {}
    self.tasks = {}
    self.generator = generator
    generator:set_targets(targets)

    return self
end


function Manager:add_task(name, func)
    local task = {name = name, call = func}
    table.insert(self.tasks, task)
    self.generator:add_task(task)
end


function Manager:get_packages()
    return pl.tablex.sort(self.manifest.packages)
end


function Manager:process_packages()
    for name, versions in self:get_packages() do
        log:info("Processing package '%s'", name)
        local worker = Worker(name, versions, self.manifest)
        worker:run(self.targets, self.tasks)

        self.generator:add_report(name, worker:get_report())
    end
end


function Manager:generate_reports()
    self.generator:generate_dashboard()

    for name, versions in self:get_packages() do
        self.generator:generate_package(name)

        for version in pl.tablex.sort(versions, const.compareVersions) do
            self.generator:generate_package_version(name, version)
        end
    end
end


return Manager